# Sudoku WeChat Mini-Program Backend

A Rust-based backend server for the Sudoku WeChat mini-program, built with Actix-web.

## Features

- WeChat mini-program login (jscode2session)
- User profile management
- Game records storage
- SQLite database
- Docker support

## Prerequisites

- Rust 1.75+
- WeChat Mini-Program AppID and Secret

## Local Development

1. Copy the environment file:

```bash
cp .env.example .env
```

2. Edit `.env` and fill in your WeChat credentials:

```env
WECHAT_APPID=your_appid_here
WECHAT_SECRET=your_secret_here
```

3. Run the server:

```bash
cargo run
```

The server will start at `http://localhost:8080`.

## Experience

## Docker Deployment

### Build and run with Docker Compose:

```bash
docker compose up -d
```

### Build image only:

```bash
docker build -t sudoku-server .
```

### Run container:

```bash
docker run -d \
  -p 8080:8080 \
  -e WECHAT_APPID=your_appid \
  -e WECHAT_SECRET=your_secret \
  -v $(pwd)/data:/app/data \
  --name sudoku-server \
  sudoku-server
```

## API Endpoints

### POST /api/wx/login

WeChat mini-program login.

**Request:**

```json
{
  "code": "wx_login_code_from_wx_login"
}
```

**Response:**

```json
{
  "openid": "user_openid",
  "session_key": "session_key",
  "unionid": "optional_unionid"
}
```

### POST /api/user/profile

Update user profile.

**Request:**

```json
{
  "openid": "user_openid",
  "nickName": "nickname",
  "avatarUrl": "https://example.com/avatar.jpg"
}
```

**Response:**

```json
{
  "success": true
}
```

### GET /api/health

Health check.

**Response:**

```json
{
  "status": "ok"
}
```

## Project Structure

```
server/
├── Cargo.toml
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .dockerignore
└── src/
    ├── main.rs       # Entry point and server setup
    ├── handlers.rs   # API route handlers
    ├── models.rs     # Data models
    └── db.rs         # Database initialization and operations
```

一、本地构建 Docker 镜像  
 在 server 目录下执行：

cd /Users/wangcheng/Documents/workspace/sudu-game/server

# 构建镜像

docker build -t sudu-game-server:latest .

二、推送镜像到服务器  
 方式 1: 导出为 tar 文件后上传（无需 Docker Registry）

# 导出镜像

docker save sudu-game-server:latest | gzip > sudu-game-server.tar.gz

# 上传到服务器（约 100-200MB，首次可能较慢）

scp sudu-game-server.tar.gz root@120.53.246.10:/opt/

# 在服务器上导入

ssh root@120.53.246.10 'docker load < /opt/sudu-game-server.tar.gz'

方式 2: 使用 Docker Registry（推荐，后续更新更方便）  
 如果你有阿里云/腾讯云容器镜像服务，可以：

# 登录你的 Registry

docker login ccr.ccs.tencentyun.com

# 打标签

docker tag sudu-game-server:latest ccr.ccs.tencentyun.com/your-namespace/sudu-game-server:latest

# 推送

docker push ccr.ccs.tencentyun.com/your-namespace/sudu-game-server:latest

# 在服务器上拉取

ssh root@120.53.246.10  
 docker pull ccr.ccs.tencentyun.com/your-namespace/sudu-game-server:latest

三、在服务器上部署

1. 上传 docker-compose.yml 和 .env

# 在本地执行

ssh root@120.53.246.10 "mkdir -p /opt/sudu-game"

scp docker-compose.yml .env root@120.53.246.10:/opt/sudu-game/

2. 在服务器上启动容器  
   ssh root@120.53.246.10  
   cd /opt/sudu-game

# 如果用的是 docker load 导入的镜像，直接运行

docker-compose up -d

# 如果用的是 Registry，docker-compose.yml 中指定 image 即可

3. 验证服务

# 查看容器状态

docker ps

# 查看日志

docker logs -f sudoku-server

# 测试健康检查

curl http://localhost:8080/api/health

# 应返回: {"status":"ok"}

四、常用运维命令

# 查看日志

docker logs sudoku-server

# 实时日志

docker logs -f sudoku-server

# 重启服务

docker restart sudoku-server

# 停止服务

docker stop sudoku-server

# 更新镜像后重新部署

docker load < /opt/sudu-game-server.tar.gz  
 docker-compose up -d

五、一键部署脚本（可选）  
 你也可以在服务器上创建一个部署脚本：

# /opt/sudu-game/deploy.sh

#!/bin/bash  
 set -e

echo "Loading image..."  
 docker load < /opt/sudu-game-server.tar.gz

echo "Starting container..."  
 cd /opt/sudu-game  
 docker-compose up -d

echo "Waiting for service to start..."  
 sleep 2

echo "Checking health..."  
 curl -f http://localhost:8080/api/health || echo "Service may need more time to start"

echo "Deploy complete!"

chmod +x /opt/sudu-game/deploy.sh

{
"0-0": {
"answer": 8,
"candidates": []
},
"0-1": {
"answer": 2,
"candidates": []
},
"0-2": {
"answer": 1,
"candidates": []
},
"0-3": {
"answer": 7,
"candidates": []
},
"0-4": {
"answer": 4,
"candidates": []
},
"0-5": {
"answer": 3,
"candidates": []
},
"0-6": {
"answer": 6,
"candidates": []
},
"0-7": {
"answer": 5,
"candidates": []
},
"0-8": {
"answer": 9,
"candidates": []
},
"1-0": {
"answer": 3,
"candidates": []
},
"1-1": {
"answer": 4,
"candidates": []
},
"1-2": {
"answer": 5,
"candidates": []
},
"1-3": {
"answer": 6,
"candidates": []
},
"1-4": {
"answer": 8,
"candidates": []
},
"1-5": {
"answer": 9,
"candidates": []
},
"1-6": {
"answer": 2,
"candidates": []
},
"1-7": {
"answer": 1,
"candidates": []
},
"1-8": {
"answer": 7,
"candidates": []
},
"2-0": {
"answer": 7,
"candidates": []
},
"2-1": {
"answer": 9,
"candidates": []
},
"2-2": {
"answer": 6,
"candidates": []
},
"2-3": {
"answer": 5,
"candidates": []
},
"2-4": {
"answer": 1,
"candidates": []
},
"2-5": {
"answer": 2,
"candidates": []
},
"2-6": {
"answer": 3,
"candidates": []
},
"2-7": {
"answer": 8,
"candidates": []
},
"2-8": {
"answer": 4,
"candidates": []
},
"3-0": {
"answer": 9,
"candidates": []
},
"3-1": {
"answer": 8,
"candidates": []
},
"3-2": {
"answer": 4,
"candidates": []
},
"3-3": {
"answer": 1,
"candidates": []
},
"3-4": {
"answer": 5,
"candidates": []
},
"3-5": {
"answer": 6,
"candidates": []
},
"3-6": {
"answer": 7,
"candidates": []
},
"3-7": {
"answer": 2,
"candidates": []
},
"3-8": {
"answer": 3,
"candidates": []
},
"4-0": {
"answer": 2,
"candidates": []
},
"4-1": {
"answer": 6,
"candidates": []
},
"4-2": {
"answer": 3,
"candidates": []
},
"4-3": {
"answer": 9,
"candidates": []
},
"4-4": {
"answer": 7,
"candidates": []
},
"4-5": {
"answer": 8,
"candidates": []
},
"4-6": {
"answer": 1,
"candidates": []
},
"4-7": {
"answer": 4,
"candidates": []
},
"4-8": {
"answer": 5,
"candidates": []
},
"5-0": {
"answer": 1,
"candidates": []
},
"5-1": {
"answer": 5,
"candidates": []
},
"5-2": {
"answer": 7,
"candidates": []
},
"5-3": {
"answer": 3,
"candidates": []
},
"5-4": {
"answer": 2,
"candidates": []
},
"5-5": {
"answer": 4,
"candidates": []
},
"5-6": {
"answer": 8,
"candidates": []
},
"5-7": {
"answer": 9,
"candidates": []
},
"5-8": {
"answer": 6,
"candidates": []
},
"6-0": {
"answer": 5,
"candidates": []
},
"6-1": {
"answer": 7,
"candidates": []
},
"6-2": {
"answer": 2,
"candidates": []
},
"6-3": {
"answer": 4,
"candidates": []
},
"6-4": {
"answer": 3,
"candidates": []
},
"6-5": {
"answer": 1,
"candidates": []
},
"6-6": {
"answer": 9,
"candidates": []
},
"6-7": {
"answer": 6,
"candidates": []
},
"6-8": {
"answer": 8,
"candidates": []
},
"7-0": {
"answer": 6,
"candidates": []
},
"7-1": {
"answer": 3,
"candidates": []
},
"7-2": {
"answer": 8,
"candidates": []
},
"7-3": {
"answer": 2,
"candidates": []
},
"7-4": {
"answer": 9,
"candidates": []
},
"7-5": {
"answer": 5,
"candidates": []
},
"7-6": {
"answer": 4,
"candidates": []
},
"7-7": {
"answer": 7,
"candidates": []
},
"7-8": {
"answer": 1,
"candidates": []
},
"8-0": {
"answer": 4,
"candidates": []
},
"8-1": {
"answer": 1,
"candidates": []
},
"8-2": {
"answer": 9,
"candidates": []
},
"8-3": {
"answer": 8,
"candidates": []
},
"8-4": {
"answer": 6,
"candidates": []
},
"8-5": {
"answer": 7,
"candidates": []
},
"8-6": {
"answer": 5,
"candidates": []
},
"8-7": {
"answer": 3,
"candidates": []
},
"8-8": {
"answer": null,
"candidates": []
}
}

### 后续工作

- UI 优化
  - [x] 搜索页面ui调整
  - [x] 列表添加分页
- 录入更多题型
  - [x] 不同难度大题型录入
- 找到一个自动生成题型的网站，并生成一个题目
  - [x] 自己通过代码实现
- [] 提示次数每个游戏默认3次， check答案每局3次
  - [] 早期无法接入广告， 只有默认的三次，看完就无法使用了，重新开始游戏则恢复。
  - [] 接入广告后， 看一次广告加 3 次，提示和check分开看，单独加
- 发布游戏
- 发布游戏攻略3条
- 开通广告
- 接入广告
- 游戏适当更改适应广告
- 发布
