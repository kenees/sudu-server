use serde::{Deserialize, Serialize};
use sqlx::MySqlPool;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CageCell {
    pub row: i32,
    pub col: i32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CageRow {
    pub id: i32,
    pub sum: i32,
    pub cells: Vec<CageCell>,
    pub inner: Vec<Vec<i32>>,
}

pub async fn init_db(db_url: &str) -> Result<MySqlPool, sqlx::Error> {
    let pool = MySqlPool::connect(db_url).await?;

    // Create users table if not exists
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id BIGINT PRIMARY KEY AUTO_INCREMENT,
            openid VARCHAR(255) NOT NULL UNIQUE,
            nick_name VARCHAR(255),
            avatar_url TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
        "#,
    )
    .execute(&pool)
    .await?;

    // Create puzzles table
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS puzzles (
            id BIGINT PRIMARY KEY AUTO_INCREMENT,
            difficulty INT NOT NULL DEFAULT 1,
            average_solving_time BIGINT NOT NULL DEFAULT 0,
            cages_json TEXT NOT NULL,
            answer_json TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
        "#,
    )
    .execute(&pool)
    .await?;

    // Create game_records table
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS game_records (
            id BIGINT PRIMARY KEY AUTO_INCREMENT,
            openid VARCHAR(255) NOT NULL,
            puzzle_id BIGINT NOT NULL,
            difficulty INT,
            cell_values_json TEXT NOT NULL,
            elapsed_seconds BIGINT NOT NULL DEFAULT 0,
            completed BOOLEAN NOT NULL DEFAULT FALSE,
            disabled_hints_json TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_openid (openid),
            INDEX idx_puzzle_id (puzzle_id)
        )
        "#,
    )
    .execute(&pool)
    .await?;

    Ok(pool)
}

pub async fn get_or_create_user(pool: &MySqlPool, openid: &str) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        INSERT IGNORE INTO users (openid) VALUES (?)
        "#,
    )
    .bind(openid)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn get_user_profile(
    pool: &MySqlPool,
    openid: &str,
) -> Result<Option<(String, String)>, sqlx::Error> {
    let row: Option<(Option<String>, Option<String>)> = sqlx::query_as(
        r#"
        SELECT nick_name, avatar_url FROM users WHERE openid = ?
        "#,
    )
    .bind(openid)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|(nick, avatar)| (nick.unwrap_or_default(), avatar.unwrap_or_default())))
}

pub async fn update_user_profile(
    pool: &MySqlPool,
    openid: &str,
    nick_name: &str,
    avatar_url: &str,
) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        INSERT INTO users (openid, nick_name, avatar_url)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            nick_name = VALUES(nick_name),
            avatar_url = VALUES(avatar_url),
            updated_at = CURRENT_TIMESTAMP
        "#,
    )
    .bind(openid)
    .bind(nick_name)
    .bind(avatar_url)
    .execute(pool)
    .await?;

    Ok(())
}

// ==================== Puzzle functions ====================

/// Get the best (minimum) completed time for a user on a specific puzzle
pub async fn get_personal_best_time(
    pool: &MySqlPool,
    openid: &str,
    puzzle_id: i64,
) -> Result<Vec<(i64, bool)>, sqlx::Error> {
    let best: Vec<(i64, bool)> = sqlx::query_as::<_, (i64, bool)>(
        r#"
        SELECT elapsed_seconds, completed
        FROM game_records
        WHERE openid = ? AND puzzle_id = ?
        "#,
    )
    .bind(openid)
    .bind(puzzle_id)
    .fetch_all(pool)
    .await?;

    Ok(best)
}

/// Get puzzles for a specific date (daily puzzles)
pub async fn get_daily_puzzles(
    pool: &MySqlPool,
    date: &str,
    openid: Option<&str>,
) -> Result<Vec<(i64, i32, i64, String, Option<i64>, bool)>, sqlx::Error> {
    let rows: Vec<(i64, i32, i64, String, String)> = sqlx::query_as(
        r#"
        SELECT id, difficulty, average_solving_time, cages_json, COALESCE(answer_json, '') as answer_json
        FROM puzzles
        WHERE DATE(created_at) = ?
        ORDER BY difficulty ASC
        "#,
    )
    .bind(date)
    .fetch_all(pool)
    .await?;

    // Compute average solving time from game_records
    let mut results = Vec::new();
    for (id, difficulty, average_solving_time, _, _) in rows {
        let (personal_time, completed) = if let Some(oid) = openid {
            match get_personal_best_time(pool, oid, id).await {
                Ok(records) => records
                    .first()
                    .map(|&(t, c)| (Some(t), c))
                    .unwrap_or((None, false)),
                Err(e) => {
                    eprintln!("Failed to get personal best time: {}", e);
                    (None, false)
                }
            }
        } else {
            (None, false)
        };

        results.push((
            id,
            difficulty,
            average_solving_time,
            date.to_string(),
            personal_time,
            completed,
        ));
    }

    Ok(results)
}

/// Get puzzle detail with cages
pub async fn get_puzzle_detail(
    pool: &MySqlPool,
    puzzle_id: i64,
) -> Result<Option<(i64, i32, String, Option<String>, i64)>, sqlx::Error> {
    let row: Option<(i64, i32, String, Option<String>)> = sqlx::query_as(
        r#"
        SELECT id, difficulty, cages_json, answer_json
        FROM puzzles
        WHERE id = ?
        "#,
    )
    .bind(puzzle_id)
    .fetch_optional(pool)
    .await?;

    match row {
        Some((id, difficulty, cages_json, answer_json)) => {
            let avg_time: Option<i64> = sqlx::query_scalar(
                r#"
                SELECT AVG(elapsed_seconds) FROM game_records
                WHERE puzzle_id = ? AND completed = 1
                "#,
            )
            .bind(id)
            .fetch_one(pool)
            .await
            .unwrap_or(None);

            Ok(Some((
                id,
                difficulty,
                cages_json,
                answer_json,
                avg_time.unwrap_or(0),
            )))
        }
        None => Ok(None),
    }
}

/// Search puzzles by id (optional), level (required), created_at <= today
pub async fn search_puzzles(
    pool: &MySqlPool,
    puzzle_id: Option<i64>,
    level: i32,
    openid: Option<&str>,
) -> Result<Vec<(i64, i32, i64, String, Option<i64>, bool)>, sqlx::Error> {
    let today = chrono::Local::now().format("%Y-%m-%d").to_string();

    let query = if let Some(id) = puzzle_id {
        sqlx::query_as::<_, (i64, i32, i64, String, String)>(
            r#"
            SELECT id, difficulty, average_solving_time, cages_json, COALESCE(answer_json, '') as answer_json
            FROM puzzles
            WHERE id = ? AND DATE(created_at) <= ?
            ORDER BY created_at DESC
            "#,
        )
        .bind(id)
        .bind(&today)
    } else {
        sqlx::query_as::<_, (i64, i32, i64, String, String)>(
            r#"
            SELECT id, difficulty, average_solving_time, cages_json, COALESCE(answer_json, '') as answer_json
            FROM puzzles
            WHERE difficulty = ? AND DATE(created_at) <= ?
            ORDER BY created_at DESC
            "#,
        )
        .bind(level)
        .bind(&today)
    };

    let rows: Vec<(i64, i32, i64, String, String)> = query.fetch_all(pool).await?;

    let mut results = Vec::new();
    for (id, difficulty, average_solving_time, _, _) in rows {
        let (personal_time, completed) = if let Some(oid) = openid {
            match get_personal_best_time(pool, oid, id).await {
                Ok(records) => records
                    .first()
                    .map(|&(t, c)| (Some(t), c))
                    .unwrap_or((None, false)),
                Err(e) => {
                    eprintln!("Failed to get personal best time: {}", e);
                    (None, false)
                }
            }
        } else {
            (None, false)
        };

        results.push((
            id,
            difficulty,
            average_solving_time,
            String::new(),
            personal_time,
            completed,
        ));
    }

    Ok(results)
}

// ==================== Game record functions ====================

/// Save or update a game record for a user (one record per user+puzzle)
pub async fn save_game_record(
    pool: &MySqlPool,
    openid: &str,
    puzzle_id: i64,
    cell_values_json: &str,
    elapsed_seconds: i64,
    completed: bool,
    disabled_hints_json: &str,
) -> Result<i64, sqlx::Error> {
    // Get puzzle difficulty
    let difficulty: Option<i32> = sqlx::query_scalar("SELECT difficulty FROM puzzles WHERE id = ?")
        .bind(puzzle_id)
        .fetch_optional(pool)
        .await?;

    // Check if record already exists for this user+puzzle
    let existing: Option<(i64,)> = sqlx::query_as(
        r#"
        SELECT id FROM game_records
        WHERE openid = ? AND puzzle_id = ?
        LIMIT 1
        "#,
    )
    .bind(openid)
    .bind(puzzle_id)
    .fetch_optional(pool)
    .await?;

    match existing {
        Some((record_id,)) => {
            sqlx::query(
                r#"
                UPDATE game_records
                SET cell_values_json = ?, elapsed_seconds = ?, completed = ?, difficulty = ?, disabled_hints_json = ?, created_at = CURRENT_TIMESTAMP
                WHERE id = ?
                "#,
            )
            .bind(cell_values_json)
            .bind(elapsed_seconds)
            .bind(completed)
            .bind(difficulty)
            .bind(disabled_hints_json)
            .bind(record_id)
            .execute(pool)
            .await?;

            Ok(record_id)
        }
        None => {
            let result = sqlx::query(
                r#"
                INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                "#,
            )
            .bind(openid)
            .bind(puzzle_id)
            .bind(difficulty)
            .bind(cell_values_json)
            .bind(elapsed_seconds)
            .bind(completed)
            .bind(disabled_hints_json)
            .execute(pool)
            .await?;

            Ok(result.last_insert_id() as i64)
        }
    }
}

/// Get all game records for a user
pub async fn get_user_records(
    pool: &MySqlPool,
    openid: &str,
) -> Result<Vec<(i64, i64, i32, i64, bool, String, i64, String)>, sqlx::Error> {
    let rows: Vec<(i64, i64, i32, i64, bool, String, String)> = sqlx::query_as(
        r#"
        SELECT
            gr.id,
            gr.puzzle_id,
            COALESCE(gr.difficulty, p.difficulty) as difficulty,
            gr.elapsed_seconds,
            gr.completed,
            COALESCE(DATE_FORMAT(gr.created_at, '%Y-%m-%d %H:%i:%s'), CURRENT_TIMESTAMP) as created_at,
            gr.cell_values_json
        FROM game_records gr
        LEFT JOIN puzzles p ON gr.puzzle_id = p.id
        WHERE gr.openid = ?
        ORDER BY gr.created_at DESC
        "#,
    )
    .bind(openid)
    .fetch_all(pool)
    .await?;

    let mut results = Vec::new();

    for (id, puzzle_id, difficulty, elapsed_seconds, completed, created_at, cell_values_json) in
        rows
    {
        let avg_time: Option<i64> = sqlx::query_scalar(
            r#"
            SELECT average_solving_time FROM puzzles
            WHERE id = ?
            "#,
        )
        .bind(puzzle_id)
        .fetch_one(pool)
        .await
        .unwrap_or(None);

        results.push((
            id,
            puzzle_id,
            difficulty,
            elapsed_seconds,
            completed,
            created_at,
            avg_time.unwrap_or(0),
            cell_values_json,
        ));
    }

    log::info!("rows: {:?}", results);

    Ok(results)
}

/// Get a specific game record with cell values
pub async fn get_game_record(
    pool: &MySqlPool,
    openid: &str,
    puzzle_id: i64,
) -> Result<Option<(i64, i64, i32, String, i64, bool, String, String)>, sqlx::Error> {
    let row: Option<(i64, i64, i32, String, i64, bool, String, String)> = sqlx::query_as(
        r#"
        SELECT id, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed,
               COALESCE(DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s'), CURRENT_TIMESTAMP) as created_at,
               COALESCE(disabled_hints_json, '[]') as disabled_hints_json
        FROM game_records
        WHERE openid = ? AND puzzle_id = ?
        ORDER BY created_at DESC
        LIMIT 1
        "#,
    )
    .bind(openid)
    .bind(puzzle_id)
    .fetch_optional(pool)
    .await?;

    Ok(row)
}
