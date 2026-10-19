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

### 4.2 Automated Database Backups
Before executing any major schema migration:
```bash
pg_dump "$DATABASE_URL" --format=c --file="backup_$(date +%Y%m%d_%H%M%S).dump"
```

### 4.3 Rollback Procedure
If a deployment fails:
1. **Vercel Rollback**: Navigate to `Deployments` in Vercel dashboard and click `Instant Rollback` on the previous known healthy deployment.
2. **Database Rollback**:
   ```bash
   pg_restore --clean --if-exists -d "$DATABASE_URL" backup_YYYYMMDD_HHMMSS.dump
   ```
3. **Git Revert**: Revert the commit and push to `main` and `master`:
   ```bash
   git revert HEAD
   git push origin main && git checkout master && git merge main && git push origin master && git checkout main
   ```
