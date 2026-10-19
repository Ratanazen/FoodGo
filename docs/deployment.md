# FoodGo Production Hosting & Deployment Guide

**Document Version**: 1.0.0  
**Production API**: [https://food-go-app.vercel.app/](https://food-go-app.vercel.app/)  
**Render Web Service**: [https://foodgo-53pl.onrender.com/](https://foodgo-53pl.onrender.com/)

---

## 1. Architecture & Deployment Targets

FoodGo supports hybrid serverless and containerized production topologies:

```mermaid
graph LR
    Client[Flutter Web & Mobile] --> |HTTPS REST & Auth| Vercel[Vercel Serverless WSGI]
    Client --> |WSS Real-Time Tracking| Render[Render Daphne ASGI Container]
    Vercel --> Postgres[(Managed PostgreSQL 15)]
    Render --> Postgres
    Render --> Redis[(Redis Cloud / Cache)]
```

---

## 2. Platform 1: Vercel Serverless Backend

### 2.1 Configuration
- **Entry Point**: `backend/config/wsgi.py`
- **Runtime**: Python 3.12 (`@vercel/python`)
- **Configuration File**: Root [`vercel.json`](file:///home/reny/FoodGo/vercel.json) and [`backend/vercel.json`](file:///home/reny/FoodGo/backend/vercel.json)
- **Automatic Initialization**: When running on Vercel (`'VERCEL' in os.environ`), `wsgi.py` automatically checks for `core_user` tables and runs migrations and superuser provisioning during cold-start.

### 2.2 Vercel Environment Variables
Configure these in the Vercel Project Dashboard (`Settings -> Environment Variables`):

| Variable | Recommended Value | Note |
| :--- | :--- | :--- |
| `DJANGO_SETTINGS_MODULE` | `config.settings` | Required for Django initialization |
| `SECRET_KEY` | *(50+ char random secret)* | Production cryptographic key |
| `DJANGO_DEBUG` | `False` | Disables debug mode in production |
| `DATABASE_URL` | `postgres://user:pass@ep-host.region.aws.neon.tech/foodgo` | Managed Neon or Supabase PostgreSQL |
| `ALLOWED_HOSTS` | `.vercel.app,food-go-app.vercel.app,localhost` | Host whitelist |
| `CORS_ALLOWED_ORIGINS` | `https://food-go-app.vercel.app,https://foodgo-53pl.onrender.com` | Allowed CORS origins |
| `SESSION_COOKIE_SECURE` | `True` | Forces HTTPS cookies |
| `CSRF_COOKIE_SECURE` | `True` | Forces HTTPS CSRF tokens |

### 2.3 Deployment Commands
Using Vercel CLI:
```bash
# Preview Deployment
vercel

# Production Deployment
vercel --prod
```

---

## 3. Platform 2: Render Container Hosting (WebSockets & Daphne)

### 3.1 Backend Service (ASGI WebSockets)
- **Environment**: Docker
- **Dockerfile**: `Dockerfile`
- **Start Command**: `./start.sh` (executes Daphne on `0.0.0.0:$PORT`)
- **Health Check Path**: `/api/restaurants/`

### 3.2 Frontend Service (Flutter Web SPA)
- **Environment**: Docker
- **Dockerfile**: `Dockerfile.frontend`
- **Server**: Nginx Alpine serving single-page application bundle on port `8080`
- **Routing**: Configured in `foodgo_flutter/nginx.conf` with SPA fallback:
  ```nginx
  location / {
      try_files $uri $uri/ /index.html;
  }
  ```

---

## 4. Production Database Migrations & Rollback Procedures

### 4.1 Applying Migrations
Always run non-destructive database migrations against production:
```bash
python manage.py migrate --noinput
```

### 4.2 Automated Database Backup Script (`scripts/backup_db.sh`)
FoodGo includes an enterprise backup utility supporting PostgreSQL (production) and SQLite (development) with automated gzip compression, retention pruning, and restore verification:

```bash
# 1. Run automated backup (respects DATABASE_URL or falls back to SQLite)
bash scripts/backup_db.sh --backup

# 2. List all existing backup archives with size and modification timestamp
bash scripts/backup_db.sh --list

# 3. Configure automated cron job for daily midnight backups with 7-day retention
0 0 * * * /bin/bash /home/reny/FoodGo/scripts/backup_db.sh --backup --retention 7 >> /var/log/foodgo_backup.log 2>&1
```

### 4.3 Disaster Recovery & Rollback Procedure
If a production deployment or schema migration fails:
1. **Database Restore**:
   ```bash
   # Restore PostgreSQL from gzip-compressed dump
   bash scripts/backup_db.sh --restore backups/foodgo_pg_YYYYMMDD_HHMMSS.dump.gz

   # Or restore SQLite fallback
   bash scripts/backup_db.sh --restore backups/foodgo_sqlite_YYYYMMDD_HHMMSS.sqlite3.gz
   ```
2. **Vercel Instant Rollback**:
   - Navigate to `Deployments` in the Vercel Dashboard.
   - Locate the last known green production deployment.
   - Click `...` -> `Instant Rollback`.
3. **Render ASGI Container Rollback**:
   - Navigate to the Render Dashboard -> `foodgo-backend` -> `Deploys`.
   - Select the target commit and trigger a rollback deploy.
4. **Git Branch Alignment**:
   ```bash
   git revert HEAD
   git push origin main && git checkout master && git merge main && git push origin master && git checkout main
   ```

---

## 5. Production Health Checks & Monitoring

The following endpoints are monitored for uptime and telemetry:

| Endpoint | Method | Expected Status | Purpose |
| :--- | :--- | :--- | :--- |
| `/api/restaurants/` | `GET` | `HTTP 200` | Core API & database connectivity |
| `/api/currency/rates/` | `GET` | `HTTP 200` | NBC multi-currency exchange rate engine |
| `/api/admin/analytics/` | `GET` | `HTTP 200 / 401` | Operations & KPI aggregation |
| `/ws/tracking/<order_id>/` | `WSS` | `101 Switching Protocols` | Daphne ASGI live telemetry WebSocket |
