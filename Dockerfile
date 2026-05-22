# ========== 构建阶段 ==========
# 在 Dockerfile 开头启用 BuildKit
# syntax=docker/dockerfile:1.4

# 使用官方 Rust 镜像，它支持多架构（arm64/amd64）
# 指定版本号以保持可重现性，建议使用最新的稳定版
FROM rust:1.88-slim-bookworm AS builder

# 设置工作目录
WORKDIR /usr/src/app

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources
# 安装构建依赖（如果需要 MySQL/OpenSSL）
# pkg-config 和 libssl-dev 是编译许多 Rust 库所必需的
RUN apt-get update && \
         apt-get install -y --no-install-recommends \
         pkg-config \
         libssl-dev \
     && rm -rf /var/lib/apt/lists/*

# 配置 cargo 源（不需要挂载缓存）
RUN mkdir -p $CARGO_HOME && \
    echo '[source.crates-io]' > $CARGO_HOME/config.toml && \
    echo 'replace-with = "ustc"' >> $CARGO_HOME/config.toml && \
    echo '[source.ustc]' >> $CARGO_HOME/config.toml && \
    echo 'registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"' >> $CARGO_HOME/config.toml

COPY Cargo.toml Cargo.lock ./

# 复制依赖清单文件（利用 Docker 缓存，避免每次重新下载依赖）
COPY Cargo.toml Cargo.lock ./

# 创建一个虚拟的 main.rs，仅用于编译依赖项（缓存依赖层）
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    rustup target add x86_64-unknown-linux-gnu && \
    cargo build --release --target x86_64-unknown-linux-gnu && \
    rm -rf src

# 复制真正的源代码并构建
COPY . .
RUN cargo build --release --target x86_64-unknown-linux-gnu

# ========== 运行阶段 ==========
# 使用精简的 Debian 镜像（支持多架构）
FROM debian:bookworm-slim

# 安装运行时动态库（OpenSSL 运行时库、MariaDB 客户端库，ca-certificates 用于 HTTPS）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libssl3 \
        libmariadb3 \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 从构建阶段复制编译好的二进制文件
COPY --from=builder /usr/src/app/target/x86_64-unknown-linux-gnu/release/sudoku-server /app/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 如果服务需要配置文件，取消下面的注释并确保文件存在
# COPY config.toml /app/

# 声明运行时端口（仅作文档，不实际映射）
EXPOSE 8080

# 可选：设置默认环境变量（可在 docker run 或 compose 中覆盖）
ENV RUST_LOG=info
ENV HOST=0.0.0.0
ENV PORT=8080
ENV RUST_BACKTRACE=1

# Docker 自检，确保服务在 8080 端口健康运行
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

# 运行服务
CMD ["./start.sh"]