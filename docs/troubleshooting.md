# 🛠️ FoodGo Troubleshooting & Diagnostics Guide

**Document Version**: 1.0.0  
**Scope**: Diagnosing common errors across Flutter client, Django backend, Vercel serverless, and Docker environments.

---

## 1. Quick Diagnostic Checklist

| Symptom | Probable Cause | Immediate Remediation |
| :--- | :--- | :--- |
| **HTTP 401 Unauthorized** | Missing or expired JWT access token | Verify login or check `flutter_secure_storage` token expiration |
| **HTTP 429 Too Many Requests** | Rate-limiting throttle exceeded | Throttling raised to 120/min (anon) and 600/min (user) in `REST_FRAMEWORK` |
| **HTTP 500 on Vercel** | Missing `requirements.txt` or module resolution | Verify root `requirements.txt` and `sys.path.insert` in `wsgi.py` |
| **Docker Build fails on Flutter** | Overly aggressive `.dockerignore` | Ensure `foodgo_flutter` is not excluded in `.dockerignore` |
| **WebSocket connection fails** | Daphne not running or wrong port | Verify ASGI server is listening on port `8000` / `$PORT` |
| **MissingPluginException in tests** | Mocking missing for native plugins | Wrap native channels or use unit test mocks for secure storage |

---

## 2. Common Scenarios & Step-by-Step Fixes

### Scenario A: Vercel Serverless Function Times Out or Returns 500
- **Symptoms**: `FUNCTION_INVOCATION_TIMEOUT` or `ModuleNotFoundError: No module named 'config'`.
- **Diagnostic Step**: Check Vercel Function logs:
  ```bash
  vercel logs food-go-app.vercel.app
  ```
- **Remediation**:
  1. Confirm `backend/config/wsgi.py` contains:
     ```python
     CURRENT_DIR = Path(__file__).resolve().parent
     BACKEND_DIR = CURRENT_DIR.parent
     if str(BACKEND_DIR) not in sys.path:
         sys.path.insert(0, str(BACKEND_DIR))
     ```
  2. Confirm `requirements.txt` is present at the repository root.

### Scenario B: Flutter Web Blank Screen on Page Refresh
- **Symptoms**: Direct URL navigation (e.g., `/cart`, `/orders`) gives 404 in Nginx container.
- **Root Cause**: Single-page routing without fallback.
- **Remediation**: Verify `foodgo_flutter/nginx.conf` contains `try_files $uri $uri/ /index.html;`.

### Scenario C: Database Migrations Conflict in CI/CD
- **Symptoms**: `python manage.py makemigrations --check --dry-run` fails with pending migrations.
- **Diagnostic Step**: Run locally:
  ```bash
  backend/venv/bin/python backend/manage.py makemigrations
  ```
- **Remediation**: Commit the newly created migration file to `backend/core/migrations/` and push.

### Scenario D: Missing Environment Variables
- **Symptoms**: `SECRET_KEY` error or database connection failure on local run.
- **Remediation**: Copy `.env.example` to `backend/.env` and supply local credentials:
  ```bash
  cp .env.example backend/.env
  ```
