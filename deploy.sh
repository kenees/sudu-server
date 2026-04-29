#!/bin/bash
set -e

# 配置信息
SERVER_IP="120.53.246.10"
SERVER_USER="root"
IMAGE_NAME="sudu-game-server"
IMAGE_TAG="latest"
REMOTE_DIR="/opt/sudu-game"
REMOTE_SRC_DIR="${REMOTE_DIR}/src"
CONTAINER_NAME="sudoku-server"
