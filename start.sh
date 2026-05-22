#!/bin/sh
set -e

echo "[startup] $(date) - starting sudoku-server container"
echo "[startup] HOST=${HOST:-0.0.0.0} PORT=${PORT:-8080} RUST_LOG=${RUST_LOG:-info} RUST_BACKTRACE=${RUST_BACKTRACE:-0}"
echo "[startup] working dir: $(pwd)"
echo "[startup] listing /app contents:"
ls -la /app

if [ ! -x ./sudoku-server ]; then
  echo "[startup] ERROR: sudoku-server binary missing or not executable"
  ls -la ./sudoku-server || true
  exit 1
fi

echo "[startup] executing ./sudoku-server"
exec ./sudoku-server
