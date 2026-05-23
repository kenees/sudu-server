# syntax=docker/dockerfile:1.4

# ========== 构建阶段 ==========
FROM rust:1.88-slim-bookworm AS builder

WORKDIR /usr/src/app

# 换源加速 apt-get
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        pkg-config \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置 cargo 国内源
RUN mkdir -p $CARGO_HOME && \
    echo '[source.crates-io]' > $CARGO_HOME/config.toml && \
    echo 'replace-with = "ustc"' >> $CARGO_HOME/config.toml && \
    echo '[source.ustc]' >> $CARGO_HOME/config.toml && \
    echo 'registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"' >> $CARGO_HOME/config.toml

# 复制依赖清单
COPY Cargo.toml Cargo.lock ./

# 虚拟 main.rs 编译依赖（不指定目标架构）
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# 复制真实源代码并构建
COPY . .
RUN cargo build --release

# ========== 运行阶段 ==========
FROM debian:bookworm-slim

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libssl3 \
        libmariadb3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制二进制文件（路径不再包含 x86_64 架构目录）
COPY --from=builder /usr/src/app/target/release/sudoku-server /app/
COPY start.sh /app/start.sh
COPY static /app/static
RUN chmod +x /app/start.sh

EXPOSE 8080

ENV RUST_LOG=info
ENV HOST=0.0.0.0
ENV PORT=8080
ENV RUST_BACKTRACE=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

CMD ["./start.sh"]