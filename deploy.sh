#!/bin/bash
set -e  # 遇到任何错误立即退出

# ========== 配置区（请根据实际情况修改）==========
WORK_DIR="/opt/sudu-server"                # 源代码所在目录
IMAGE_NAME="sudu-game-server"            # 镜像名称
CONTAINER_NAME="sudoku-server-container" # 容器名称

# 端口映射（宿主:容器），Rust服务默认监听端口请按需修改，例如 8080:8080
HOST_PORT=8080
CONTAINER_PORT=8080
PORT_MAP="$HOST_PORT:$CONTAINER_PORT"

# 可选：需要挂载的数据卷（例如配置文件、日志等），按需添加，多个用空格分隔
# 示例：VOLUMES="-v /opt/sudu-game/data:/app/data"
VOLUMES=""

# 可选：环境变量，例如 RUST_LOG=info
ENV_VARS="-e RUST_LOG=info -e WECHAT_APPID=wx1234567890abcdef -e WECHAT_SECRET=3395af4534cd03876fad6ebe0b5aa5a5"

# 可选：重启策略（always / unless-stopped / on-failure）
RESTART_POLICY="--restart unless-stopped"
# ===============================================

echo "=== 开始部署 $CONTAINER_NAME ==="

# 1. 进入工作目录
cd "$WORK_DIR" || { echo "错误：无法进入目录 $WORK_DIR"; exit 1; }

# 2. 拉取最新代码（假设使用 git，如果不是 git 仓库请注释或替换为 svn update 等）
if [ -d ".git" ]; then
    echo ">>> 拉取最新代码..."
    git pull
else
    echo ">>> 未检测到 .git 目录，跳过代码拉取"
fi

# 3. 构建 Docker 镜像
echo ">>> 构建 Docker 镜像 $IMAGE_NAME:latest ..."
docker build -t "$IMAGE_NAME:latest" .

# 可选：同时打一个时间戳标签，便于回滚
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
docker tag "$IMAGE_NAME:latest" "$IMAGE_NAME:$TIMESTAMP"
echo ">>> 已额外打标签 $IMAGE_NAME:$TIMESTAMP"

# 4. 停止并删除旧容器（如果存在）
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
    echo ">>> 停止并删除旧容器 $CONTAINER_NAME ..."
    docker stop "$CONTAINER_NAME" >/dev/null || true
    docker rm "$CONTAINER_NAME" >/dev/null || true
else
    echo ">>> 未找到旧容器 $CONTAINER_NAME，跳过停止/删除步骤"
fi

# 5. 运行新容器
echo ">>> 启动新容器 $CONTAINER_NAME ..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT_MAP" \
    $VOLUMES \
    $ENV_VARS \
    $RESTART_POLICY \
    "$IMAGE_NAME:latest"

# 6. 清理多余的 dangling 镜像（可选）
echo ">>> 清理无标签的 dangling 镜像..."
docker image prune -f

# 7. 显示容器运行状态
echo "=== 部署完成 ==="
docker ps --filter "name=$CONTAINER_NAME"
