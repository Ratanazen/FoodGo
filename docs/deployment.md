# 🚀 Production Deployment Guide

## Docker Compose Stack
```bash
cp .env.example .env
docker-compose up -d --build
```

Services orchestrated:
- `db`: PostgreSQL 15 on port 5432
- `redis`: Redis 7 on port 6379
- `backend`: Daphne ASGI server on port 8000
- `web`: Flutter Web server on port 8080
