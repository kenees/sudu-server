use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Deserialize)]
pub struct WeChatLoginRequest {
    pub code: String,
}

#[derive(Debug, Serialize)]
pub struct WeChatLoginResponse {
    pub openid: String,
    pub session_key: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unionid: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nick_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub avatar_url: Option<String>,
}

#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct User {
    pub id: i64,
    pub openid: String,
    pub nick_name: Option<String>,
    pub avatar_url: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateProfileRequest {
    pub openid: String,
    pub nick_name: String,
    pub avatar_url: String,
}

#[derive(Debug, Serialize)]
pub struct UpdateProfileResponse {
    pub success: bool,
}

// ==================== Puzzle models ====================

#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct Puzzle {
    pub id: i64,
    pub difficulty: i32,
    pub cages_json: String,
    pub answer_json: Option<String>,
    pub created_at: chrono::NaiveDateTime,
}

#[derive(Debug, Serialize)]
pub struct PuzzleListItem {
    pub id: i64,
    pub difficulty: i32,
    pub average_solving_time: i64,
    pub created_at: chrono::NaiveDateTime,
}

#[derive(Debug, Serialize)]
pub struct PuzzleDetail {
    pub id: i64,
    pub difficulty: i32,
    pub cages: Vec<crate::db::CageRow>,
    pub answer: Option<Vec<i32>>,
    pub average_solving_time: i64,
}

// ==================== Search request ====================

#[derive(Debug, Deserialize)]
pub struct SearchPuzzlesRequest {
    pub id: Option<i64>,
    pub level: i32,
    pub openid: Option<String>,
}

// ==================== Game record models ====================

#[derive(Debug, Deserialize)]
pub struct SaveGameRecordRequest {
    pub openid: String,
    pub puzzle_id: i64,
    pub cell_values: String, // JSON string of 9x9 array
    pub elapsed_seconds: i64,
    pub completed: bool,
    #[serde(default)]
    pub disabled_hints: Option<String>, // JSON string of array of cage ids
}

#[derive(Debug, Serialize)]
pub struct SaveGameRecordResponse {
    pub success: bool,
    pub record_id: i64,
}

#[derive(Debug, FromRow, Serialize)]
pub struct GameRecordListItem {
    pub id: i64,
    pub puzzle_id: i64,
    pub difficulty: i32,
    pub elapsed_seconds: i64,
    pub completed: bool,
    pub created_at: chrono::NaiveDateTime,
}

#[derive(Debug, Serialize)]
pub struct GameRecordDetail {
    pub id: i64,
    pub puzzle_id: i64,
    pub difficulty: i32,
    pub cell_values: String,
    pub elapsed_seconds: i64,
    pub completed: bool,
    pub created_at: chrono::NaiveDateTime,
}
