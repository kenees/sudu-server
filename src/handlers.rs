use actix_web::{web, HttpRequest, HttpResponse};
use chrono::{NaiveDateTime, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::MySqlPool;
use std::env;

use crate::models::{
    CreatePuzzleRequest, CreatePuzzleResponse, SaveGameRecordRequest, SaveGameRecordResponse,
    SearchPuzzlesRequest, UpdateProfileRequest, UpdateProfileResponse, UserInfo,
    WeChatLoginRequest, WeChatLoginResponse,
};

const WECHAT_API_URL: &str = "https://api.weixin.qq.com/sns/jscode2session";

#[derive(Debug, Serialize, Deserialize)]
pub struct AuthClaims {
    pub openid: String,
    pub session_key: String,
    pub exp: usize,
}

fn jwt_secret() -> String {
    env::var("JWT_SECRET").unwrap_or_else(|_| "sudoku_jwt_secret_change_me".to_string())
}

fn token_ttl_seconds() -> usize {
    env::var("SESSION_TOKEN_TTL_SECONDS")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(7200)
}

pub fn create_auth_token(
    openid: &str,
    session_key: &str,
) -> Result<String, jsonwebtoken::errors::Error> {
    let now = Utc::now().timestamp() as usize;
    let claims = AuthClaims {
        openid: openid.to_owned(),
        session_key: session_key.to_owned(),
        exp: now + token_ttl_seconds(),
    };
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(jwt_secret().as_bytes()),
    )
}

pub fn validate_auth_token(token: &str) -> Result<AuthClaims, jsonwebtoken::errors::Error> {
    let mut validation = Validation::new(Algorithm::HS256);
    validation.validate_exp = true;
    decode::<AuthClaims>(
        token,
        &DecodingKey::from_secret(jwt_secret().as_bytes()),
        &validation,
    )
    .map(|data| data.claims)
}

fn auth_openid_from_header(req: &HttpRequest) -> Result<String, HttpResponse> {
    let token = match req
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|h| h.strip_prefix("Bearer "))
    {
        Some(t) => t.to_string(),
        None => {
            return Err(HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "Authorization header required",
            })));
        }
    };

    match validate_auth_token(&token) {
        Ok(claims) => Ok(claims.openid),
        Err(_) => Err(HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "Invalid or expired token",
        }))),
    }
}

fn require_auth_openid(req: &HttpRequest) -> Result<String, HttpResponse> {
    auth_openid_from_header(req)
}

/// WeChat mini-program login endpoint
/// Exchanges wx.login() code for openid and session_key
pub async fn wx_login(
    pool: web::Data<MySqlPool>,
    body: web::Json<WeChatLoginRequest>,
) -> HttpResponse {
    let appid = match env::var("WECHAT_APPID") {
        Ok(v) => v,
        Err(_) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "WECHAT_APPID not configured"
            }))
        }
    };

    let secret = match env::var("WECHAT_SECRET") {
        Ok(v) => v,
        Err(_) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "WECHAT_SECRET not configured"
            }))
        }
    };

    let client = Client::new();

    let resp = match client
        .get(WECHAT_API_URL)
        .query(&[
            ("appid", &appid),
            ("secret", &secret),
            ("js_code", &body.code),
            ("grant_type", &"authorization_code".to_string()),
        ])
        .send()
        .await
    {
        Ok(r) => r,
        Err(e) => {
            eprintln!("Failed to call WeChat API: {}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to call WeChat API"
            }));
        }
    };

    let json: Value = match resp.json().await {
        Ok(j) => j,
        Err(e) => {
            eprintln!("Failed to parse WeChat API response: {}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to parse WeChat API response"
            }));
        }
    };

    // Check for WeChat API errors
    if let Some(errcode) = json.get("errcode") {
        let errmsg = json
            .get("errmsg")
            .and_then(|v| v.as_str())
            .unwrap_or("Unknown error");
        log::error!("WeChat API error: {} - {}", errcode, errmsg);
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": errmsg
        }));
    }

    let openid = json.get("openid").and_then(|v| v.as_str()).unwrap_or("");
    let session_key = json
        .get("session_key")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let unionid = json.get("unionid").and_then(|v| v.as_str());

    if openid.is_empty() || session_key.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Invalid response from WeChat API"
        }));
    }

    // Create or get user in database
    if let Err(e) = crate::db::get_or_create_user(&pool, openid).await {
        log::error!("Failed to create user: {}", e);
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "Failed to create user"
        }));
    }

    let token = match create_auth_token(openid, session_key) {
        Ok(t) => t,
        Err(e) => {
            log::error!("Failed to create auth token: {}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create auth token"
            }));
        }
    };

    // Fetch user profile
    let profile = crate::db::get_user_profile(&pool, openid)
        .await
        .ok()
        .flatten();
    let (
        id,
        openid,
        nick_name,
        avatar_url,
        level,
        finish_count,
        average_time,
        finish_max_difficulty,
        experience,
    ) = profile.unwrap_or((
        -1,
        String::new(),
        String::new(),
        String::new(),
        1,
        0,
        0,
        0,
        0,
    ));

    HttpResponse::Ok().json(WeChatLoginResponse {
        openid: openid.to_string(),
        token,
        unionid: unionid.map(|s| s.to_string()),
        nick_name: if nick_name.is_empty() {
            None
        } else {
            Some(nick_name)
        },
        avatar_url: if avatar_url.is_empty() {
            None
        } else {
            Some(avatar_url)
        },
        id,
        level,
        finish_count,
        average_time,
        finish_max_difficulty,
        experience,
    })
}

/// Create a new puzzle entry from the web editor
pub async fn create_puzzle(
    pool: web::Data<MySqlPool>,
    body: web::Json<CreatePuzzleRequest>,
) -> HttpResponse {
    let average_solving_time = body.average_solving_time.unwrap_or(0);
    let answer_json = body.answer_json.as_deref();
    let created_at = match body.created_at.as_deref() {
        Some(value) if !value.trim().is_empty() => {
            match NaiveDateTime::parse_from_str(value, "%Y-%m-%dT%H:%M")
                .or_else(|_| NaiveDateTime::parse_from_str(value, "%Y-%m-%d %H:%M:%S"))
                .or_else(|_| NaiveDateTime::parse_from_str(value, "%Y-%m-%d %H:%M"))
            {
                Ok(dt) => Some(dt),
                Err(_) => {
                    return HttpResponse::BadRequest().json(serde_json::json!({
                        "error": "created_at 格式错误，请使用 YYYY-MM-DDTHH:MM 或 YYYY-MM-DD HH:MM:SS"
                    }));
                }
            }
        }
        _ => None,
    };

    match crate::db::insert_puzzle(
        &pool,
        body.difficulty,
        &body.cages_json,
        answer_json,
        average_solving_time,
        created_at,
    )
    .await
    {
        Ok(puzzle_id) => HttpResponse::Ok().json(CreatePuzzleResponse {
            success: true,
            puzzle_id,
        }),
        Err(e) => {
            log::error!("Failed to insert puzzle: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to insert puzzle"
            }))
        }
    }
}

/// Update user profile (nickname, avatar)
pub async fn update_profile(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    body: web::Json<UpdateProfileRequest>,
) -> HttpResponse {
    let token_openid = match require_auth_openid(&req) {
        Ok(openid) => openid,
        Err(resp) => return resp,
    };

    if token_openid != body.openid {
        return HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "openid mismatch"
        }));
    }

    match crate::db::update_user_profile(&pool, &body.openid, &body.nick_name, &body.avatar_url)
        .await
    {
        Ok(_) => HttpResponse::Ok().json(UpdateProfileResponse { success: true }),
        Err(e) => {
            eprintln!("Failed to update profile: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to update profile"
            }))
        }
    }
}

// Return  total number , avg time, height level, myself records
pub async fn get_user_info(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    query: web::Query<serde_json::Value>,
) -> HttpResponse {
    let token_openid = match require_auth_openid(&req) {
        Ok(openid) => openid,
        Err(resp) => return resp,
    };

    let openid = match query.get("openid").and_then(|v| v.as_str()) {
        Some(o) => o.to_string(),
        None => token_openid.clone(),
    };

    if token_openid != openid {
        return HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "openid mismatch"
        }));
    }

    let profile = crate::db::get_user_profile(&pool, &openid)
        .await
        .ok()
        .flatten();
    let (
        id,
        openid,
        nick_name,
        avatar_url,
        level,
        finish_count,
        average_time,
        finish_max_difficulty,
        experience,
    ) = profile.unwrap_or((
        -1,
        String::new(),
        String::new(),
        String::new(),
        1,
        0,
        0,
        0,
        0,
    ));

    HttpResponse::Ok().json(UserInfo {
        openid: openid.to_string(),
        nick_name: if nick_name.is_empty() {
            None
        } else {
            Some(nick_name)
        },
        avatar_url: if avatar_url.is_empty() {
            None
        } else {
            Some(avatar_url)
        },
        id,
        level,
        finish_count,
        average_time,
        finish_max_difficulty,
        experience,
    })
}

/// Health check endpoint
pub async fn health_check() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({ "status": "ok" }))
}

// ==================== Puzzle endpoints ====================

/// Get daily puzzles for a specific date
pub async fn get_daily_puzzles(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    path: web::Path<String>,
    query: web::Query<serde_json::Value>,
) -> HttpResponse {
    let date = path.into_inner();
    let token_openid = match auth_openid_from_header(&req) {
        Ok(v) => Some(v),
        Err(resp) => return resp,
    };
    let openid = query
        .get("openid")
        .and_then(|v| v.as_str())
        .or_else(|| token_openid.as_deref());

    if let Some(query_openid) = query.get("openid").and_then(|v| v.as_str()) {
        if let Some(token_openid) = token_openid.as_deref() {
            if query_openid != token_openid {
                return HttpResponse::Unauthorized().json(serde_json::json!({
                    "error": "openid mismatch"
                }));
            }
        }
    }

    match crate::db::get_daily_puzzles(&pool, &date, openid).await {
        Ok(puzzles) => {
            let items: Vec<serde_json::Value> = puzzles
                .iter()
                .map(|(id, difficulty, avg_time, _, personal_time, completed)| {
                    serde_json::json!({
                        "id": id,
                        "difficulty": difficulty,
                        "time": avg_time,
                        "completed": completed,
                        "personal_time": personal_time,
                    })
                })
                .collect();

            HttpResponse::Ok().json(items)
        }
        Err(e) => {
            log::error!("Failed to get daily puzzles: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to get daily puzzles"
            }))
        }
    }
}

/// Get history puzzles for a specific date
pub async fn get_history_puzzles(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    path: web::Path<String>,
    query: web::Query<serde_json::Value>,
) -> HttpResponse {
    // Same as daily - puzzles for a specific date
    get_daily_puzzles(req, pool, path, query).await
}

/// Search puzzles by id (optional) and level (required)
pub async fn search_puzzles(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    body: web::Json<SearchPuzzlesRequest>,
) -> HttpResponse {
    let token_openid = match require_auth_openid(&req) {
        Ok(openid) => openid,
        Err(resp) => return resp,
    };
    let openid = match body.openid.as_deref() {
        Some(o) if o != token_openid => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "openid mismatch"
            }));
        }
        Some(_) => Some(token_openid.as_str()),
        None => Some(token_openid.as_str()),
    };

    match crate::db::search_puzzles(&pool, body.id, Some((body.level[0], body.level[1])), openid)
        .await
    {
        Ok(puzzles) => {
            let items: Vec<serde_json::Value> = puzzles
                .iter()
                .map(
                    |(id, difficulty, average_solving_time, _, personal_time, completed)| {
                        let diff_label = match difficulty {
                            1..=3 => "简单",
                            4..=6 => "中等",
                            _ => "困难",
                        };

                        serde_json::json!({
                            "id": id,
                            "title": format!("{} #{}", diff_label, id),
                            "difficulty_label": diff_label,
                            "difficulty": difficulty,
                            "time": average_solving_time,
                            "personal_time": personal_time,
                            "completed": completed,
                        })
                    },
                )
                .collect();

            HttpResponse::Ok().json(items)
        }
        Err(e) => {
            log::error!("Failed to search puzzles: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to search puzzles"
            }))
        }
    }
}

/// Get puzzle detail (with cages data)
pub async fn get_puzzle_detail(pool: web::Data<MySqlPool>, path: web::Path<i64>) -> HttpResponse {
    let puzzle_id = path.into_inner();

    match crate::db::get_puzzle_detail(&pool, puzzle_id).await {
        Ok(Some((id, difficulty, cages_json, answer_json, avg_time))) => {
            let cages: Vec<crate::db::CageRow> = match serde_json::from_str(&cages_json) {
                Ok(c) => c,
                Err(e) => {
                    log::error!("Failed to parse cages_json: {}", e);
                    return HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Invalid puzzle data"
                    }));
                }
            };

            // Parse answer_json as Vec<i32> if present
            let answer: Option<Vec<i32>> =
                answer_json.and_then(|json_str| serde_json::from_str::<Vec<i32>>(&json_str).ok());

            HttpResponse::Ok().json(serde_json::json!({
                "id": id,
                "difficulty": difficulty,
                "cages": cages,
                "answer": answer,
                "average_solving_time": avg_time,
            }))
        }
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Puzzle not found"
        })),
        Err(e) => {
            log::error!("Failed to get puzzle detail: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to get puzzle detail"
            }))
        }
    }
}

// ==================== Game record endpoints ====================

/// Save game state (cell values, elapsed time, completed status)
pub async fn save_game_record(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    body: web::Json<SaveGameRecordRequest>,
) -> HttpResponse {
    let token_openid = match require_auth_openid(&req) {
        Ok(openid) => openid,
        Err(resp) => return resp,
    };

    if token_openid != body.openid {
        return HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "openid mismatch"
        }));
    }

    log::info!(
        "Saving game record: openid={}, puzzle_id={}, cell_values_len={}, elapsed={}, difficulty={}",
        body.openid,
        body.puzzle_id,
        body.cell_values.len(),
        body.elapsed_seconds,
        body.difficulty,
    );
    log::info!("Cell values raw: {}", body.cell_values);

    let disabled_hints_json = body.disabled_hints.as_deref().unwrap_or("[]");

    match crate::db::save_game_record(
        &pool,
        &body.openid,
        body.puzzle_id,
        &body.cell_values,
        body.elapsed_seconds,
        body.completed,
        disabled_hints_json,
        body.difficulty,
        body.exp,
    )
    .await
    {
        Ok(record_id) => HttpResponse::Ok().json(SaveGameRecordResponse {
            success: true,
            record_id,
        }),
        Err(e) => {
            log::error!("Failed to save game record: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to save game record"
            }))
        }
    }
}

/// Get user's game records
pub async fn get_user_records(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    query: web::Query<serde_json::Value>,
) -> HttpResponse {
    let token_openid = match require_auth_openid(&req) {
        Ok(openid) => openid,
        Err(resp) => return resp,
    };

    let openid = match query.get("openid").and_then(|v| v.as_str()) {
        Some(o) if o != token_openid => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "openid mismatch"
            }));
        }
        Some(_) => token_openid.clone(),
        None => token_openid.clone(),
    };

    match crate::db::get_user_records(&pool, &openid).await {
        Ok(records) => {
            // Group by date
            let mut groups: std::collections::BTreeMap<String, Vec<serde_json::Value>> =
                std::collections::BTreeMap::new();

            for (record_id, puzzle_id, difficulty, elapsed, completed, created_at, avg_time, _) in
                records
            {
                let date = if created_at.contains(' ') {
                    created_at
                        .split_whitespace()
                        .next()
                        .unwrap_or(&created_at)
                        .to_string()
                } else {
                    created_at[..10].to_string()
                };
                let diff_label = match difficulty {
                    1..=3 => "简单",
                    4..=6 => "中等",
                    _ => "困难",
                };
                // let time_min = elapsed / 60;
                // let time_sec = elapsed % 60;

                // let avg_time_min = avg_time / 60;
                // let avg_time_sec = avg_time % 60;

                let entry = serde_json::json!({
                    "id": puzzle_id,
                    "record_id": record_id,
                    "title": format!("{} #{}", diff_label, puzzle_id),
                    "difficulty_label": diff_label,
                    "difficulty": difficulty,
                    "time": avg_time,
                    "personalTime": elapsed,
                    "completed": completed,
                });

                groups.entry(date).or_default().push(entry);
            }

            let result: Vec<serde_json::Value> = groups
                .into_iter()
                .map(|(date, items)| {
                    serde_json::json!({
                        "date": date,
                        "items": items,
                    })
                })
                .collect();

            HttpResponse::Ok().json(result)
        }
        Err(e) => {
            log::error!("Failed to get user records: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to get user records"
            }))
        }
    }
}

/// Get game record for resuming a game
pub async fn get_game_record(
    req: HttpRequest,
    pool: web::Data<MySqlPool>,
    path: web::Path<(String, i64)>,
) -> HttpResponse {
    let token_openid = match require_auth_openid(&req) {
        Ok(openid) => openid,
        Err(resp) => return resp,
    };

    let (openid, puzzle_id) = path.into_inner();
    if token_openid != openid {
        return HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "openid mismatch"
        }));
    }

    match crate::db::get_game_record(&pool, &openid, puzzle_id).await {
        Ok(Some((_, _, difficulty, cell_values, elapsed, completed, _, disabled_hints))) => {
            // Convert to Vec<Vec<Vec<i32>>> where null becomes []
            // let cell_values_grid = parse_cell_values(&cell_values);

            // Parse disabled_hints
            let disabled_hints: Vec<i32> =
                serde_json::from_str(&disabled_hints).unwrap_or_default();

            HttpResponse::Ok().json(serde_json::json!({
                "puzzle_id": puzzle_id,
                "difficulty": difficulty,
                "cell_values": cell_values,
                "elapsed_seconds": elapsed,
                "completed": completed,
                "disabled_hints": disabled_hints,
            }))
        }
        Ok(None) => HttpResponse::Ok().json(serde_json::json!({
            "puzzle_id": puzzle_id,
            "difficulty": 0,
            "cell_values": [],
            "elapsed_seconds": 0,
            "completed": false,
            "disabled_hints": [],
        })),
        Err(e) => {
            log::error!("Failed to get game record: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to get game record"
            }))
        }
    }
}

/// Parse cell_values JSON which may contain null values.
/// Format: "[null,[1],[2,3],null,...]" where null -> []
fn parse_cell_values(json: &str) -> Vec<Vec<Vec<i32>>> {
    if json.is_empty() || json == "[]" {
        return Vec::new();
    }

    // Try parsing as Vec<Vec<Vec<Option<i32>>>> first (handles null)
    if let Ok(grid) = serde_json::from_str::<Vec<Vec<Vec<Option<i32>>>>>(json) {
        return grid
            .into_iter()
            .map(|row| {
                row.into_iter()
                    .map(|cell| cell.into_iter().filter_map(|v| v).collect())
                    .collect()
            })
            .collect();
    }

    // Fallback: try parsing as Vec<Vec<Vec<i32>>> directly
    if let Ok(grid) = serde_json::from_str::<Vec<Vec<Vec<i32>>>>(json) {
        return grid;
    }

    // Last resort: return empty
    Vec::new()
}
