#!/bin/bash
set -e

# ========== 配置区 ==========
WORK_DIR="/opt/sudoku-server"          # 服务器上源代码目录（用于拉取最新代码，可选）
IMAGE_NAME="sudoku-game-server"        # 镜像名称
CONTAINER_NAME="sudoku-server-container"

# 服务器连接信息（请修改）
SERVER_USER="root"                     # SSH 用户名
SERVER_HOST="120.53.246.10"           # 服务器 IP 或域名
SERVER_PORT=22                         # SSH 端口
SERVER_WORK_DIR="/opt/sudoku-server"   # 服务器上工作目录（存放镜像压缩包和启动脚本）


# 端口映射
HOST_PORT=8080
CONTAINER_PORT=8080

# 环境变量文件（本地存在则自动上传）
ENV_FILE_LOCAL="./.env"

# 重启策略
RESTART_POLICY="--restart unless-stopped"
# ===================================

# 检查必要命令
for cmd in docker scp ssh; do
    if ! command -v $cmd &> /dev/null; then
        echo "错误：未找到 $cmd 命令" >&2
        exit 1
    fi
done

# 进入脚本所在目录（项目根目录）
cd "$(dirname "$0")"

# 可选：拉取最新代码（如果有 .git）
if [ -d ".git" ]; then
    echo ">>> 拉取最新代码..."
    git pull
else
    echo ">>> 未检测到 .git，跳过代码拉取"
fi

# 创建临时目录存放压缩包
BUILD_DIR="./docker-build"
mkdir -p "$BUILD_DIR"

# 需要构建的架构列表
# ARCHS=("amd64" "arm64")
ARCHS=("amd64")

# 1. 分别构建两个架构的镜像并导出为压缩包
for ARCH in "${ARCHS[@]}"; do
    PLATFORM="linux/$ARCH"
    IMAGE_TAG="$IMAGE_NAME:$ARCH"
    TAR_FILE="$BUILD_DIR/${IMAGE_NAME}.${ARCH}.tar"
    GZ_FILE="$TAR_FILE.gz"

    echo "=========================================="
    echo "构建 $PLATFORM 镜像: $IMAGE_TAG"
    echo "=========================================="

    # 构建镜像（不指定 target，让 Dockerfile 自适应）
    DOCKER_BUILDKIT=1 docker build \
        --platform "$PLATFORM" \
        -t "$IMAGE_TAG" \
        --load \
        .

    echo "导出镜像到 $TAR_FILE"
    docker save "$IMAGE_TAG" -o "$TAR_FILE"

    echo "压缩为 $GZ_FILE"
    gzip -f "$TAR_FILE"
done

# 2. 检测服务器架构
echo ">>> 检测服务器架构..."
SERVER_ARCH=$(ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "uname -m")
case "$SERVER_ARCH" in
    x86_64)
        SERVER_ARCH="amd64"
        ;;
    aarch64)
        SERVER_ARCH="arm64"
        ;;
    *)
        echo "错误：未知服务器架构 $SERVER_ARCH" >&2
        exit 1
        ;;
esac
echo "服务器架构: $SERVER_ARCH"

# 3. 选择对应的压缩包
LOCAL_GZ="$BUILD_DIR/${IMAGE_NAME}.${SERVER_ARCH}.tar.gz"
if [ ! -f "$LOCAL_GZ" ]; then
    echo "错误：未找到 $LOCAL_GZ" >&2
    exit 1
fi

# 4. 上传压缩包到服务器
echo ">>> 传输镜像压缩包到 $SERVER_HOST:$SERVER_WORK_DIR/"
ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "mkdir -p $SERVER_WORK_DIR"
scp -P "$SERVER_PORT" "$LOCAL_GZ" "$SERVER_USER@$SERVER_HOST:$SERVER_WORK_DIR/"

# 5. 上传 .env 文件（如果存在）
if [ -f "$ENV_FILE_LOCAL" ]; then
    echo ">>> 上传 .env 文件"
    scp -P "$SERVER_PORT" "$ENV_FILE_LOCAL" "$SERVER_USER@$SERVER_HOST:$SERVER_WORK_DIR/.env"
fi

# 6. 远程部署
echo ">>> 在服务器上执行部署..."
ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" bash << EOF
set -e

cd "$SERVER_WORK_DIR"

# 加载镜像
echo "加载镜像..."
gunzip -c ${IMAGE_NAME}.${SERVER_ARCH}.tar.gz | docker load

# 重新打标签为 :latest
LOADED_IMAGE_ID=\$(docker images --format "{{.ID}}" | head -1)
docker tag "\$LOADED_IMAGE_ID" "$IMAGE_NAME:latest"

# 停止并删除旧容器
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "停止并删除旧容器 $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

# 环境变量参数
ENV_ARGS="-e RUST_LOG=info -e RUST_BACKTRACE=1"
if [ -f ".env" ]; then
    ENV_ARGS="\$ENV_ARGS --env-file .env"
fi

# 启动新容器
echo "启动新容器 $CONTAINER_NAME ..."
docker run -d \\
    --name "$CONTAINER_NAME" \\
    -p $HOST_PORT:$CONTAINER_PORT \\
    \$ENV_ARGS \\
    $RESTART_POLICY \\
    "$IMAGE_NAME:latest"

# 清理无用镜像
docker image prune -f

echo "容器运行状态："
docker ps --filter "name=$CONTAINER_NAME"
EOF

echo "=== 部署完成 ==="