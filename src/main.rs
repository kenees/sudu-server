use actix_files::Files;
use actix_web::{middleware::Logger, web, App, HttpServer};
use serde::{Deserialize, Serialize};
use std::env;
use std::panic;
use std::process;

mod db;
mod handlers;
mod models;

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
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    eprintln!("DEBUG: main started");
    // Initialize env_logger with stderr to ensure logs are visible in Docker
    env_logger::Builder::from_env(env_logger::Env::new().default_filter_or("info"))
        .target(env_logger::Target::Stderr)
        .init();
    eprintln!("DEBUG: main started2");
    dotenv::dotenv().ok();
    eprintln!("DEBUG: main started3");
    let host = env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    eprintln!("DEBUG: main started4");
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    eprintln!("DEBUG: main started5");
    let db_url = env::var("DATABASE_URL").unwrap_or_else(|_| {
        "mysql://sudoku:ksJZy7sJ48nwHkzr@120.53.246.10:3306/sudoku".to_string()
    });
    eprintln!("DEBUG: main started6");

    eprintln!(
        "Starting server, db_url={}, host={}, port={}",
        db_url, host, port
    );

    // Print PID and basic process info to help container debugging
    eprintln!("PID={}, PPID={}", process::id(), std::process::id());

    // Install panic hook to ensure panics are logged to stderr (docker logs)
    panic::set_hook(Box::new(|panic_info| {
        eprintln!("PANIC captured: {}", panic_info);
        if let Some(location) = panic_info.location() {
            eprintln!("Panic at {}:{}", location.file(), location.line());
        }
        if let Ok(bt) = std::env::var("RUST_BACKTRACE") {
            if bt != "0" {
                // Try to print a backtrace if available
                eprintln!("Backtrace: {:#?}", backtrace::Backtrace::new());
            }
        }
    }));

    // Initialize database
    let pool = db::init_db(&db_url).await.unwrap_or_else(|e| {
        eprintln!("Failed to initialize database: {}", e);
        std::process::exit(1);
    });

    eprintln!(
        "Database initialized, starting HTTP server at http://{}:{}",
        host, port
    );

    log::info!("Creating HttpServer instance");
    let server = HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .app_data(web::Data::new(pool.clone()))
            // Auth
            .route("/api/wx/login", web::post().to(handlers::wx_login))
            .route(
                "/api/user/profile",
                web::post().to(handlers::update_profile),
            )
            .route("/api/user/info", web::get().to(handlers::get_user_info))
            // Puzzles
            .route(
                "/api/puzzles/daily/{date}",
                web::get().to(handlers::get_daily_puzzles),
            )
            .route(
                "/api/puzzles/history/{date}",
                web::get().to(handlers::get_history_puzzles),
            )
            .route(
                "/api/puzzles/search",
                web::post().to(handlers::search_puzzles),
            )
            .route(
                "/api/puzzles/{id}",
                web::get().to(handlers::get_puzzle_detail),
            )
            // Game records
            .route(
                "/api/records/save",
                web::post().to(handlers::save_game_record),
            )
            .route("/api/records", web::get().to(handlers::get_user_records))
            .route(
                "/api/records/{openid}/{puzzle_id}",
                web::get().to(handlers::get_game_record),
            )
            // Health
            .route("/api/health", web::get().to(handlers::health_check))
            // Static files
            .service(Files::new("/static", "./static").show_files_listing())
        // System web
    })
    .bind(format!("{}:{}", host, port));

    match server {
        Ok(srv) => {
            log::info!("Server bound to {}:{}", host, port);
            if let Err(e) = srv.run().await {
                log::error!("HttpServer run error: {}", e);
                eprintln!("HttpServer run error: {}", e);
                return Err(e);
            }
            Ok(())
        }
        Err(e) => {
            log::error!("Failed to bind server: {}", e);
            eprintln!("Failed to bind server: {}", e);
            Err(e)
        }
    }
}
