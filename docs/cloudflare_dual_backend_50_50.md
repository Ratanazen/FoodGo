# FoodGo Dual-Backend Hosting & Cloudflare 50/50 Load Balancing Guide

## Overview

This document provides the complete architecture and deployment instructions for hosting FoodGo across two independent Vercel backend instances (**Project A** and **Project B**) routed via Cloudflare with **50/50 traffic steering** and zero-downtime active failover.

---

## 1. Architecture Summary

```
                      [ Client Requests (Web / Android) ]
                                      |
                           https://api.foodgo.app
                                      |
                     [ Cloudflare Load Balancer / Edge Worker ]
                               50% / 50% Split
                                /          \
                               /            \
             (Weight: 0.5)    /              \   (Weight: 0.5)
                             v                v
                  [ Origin Server A ]    [ Origin Server B ]
                  Vercel Project A       Vercel Project B
                  foodgo-backend-a       foodgo-backend-b
                             \                /
                              \              /
                               v            v
                    [ Shared PostgreSQL Database ]
                         (Neon / RDS / Render)
                                    +
                    [ Shared Redis Cache Instance ]
                             (Upstash Redis)
```

- **Shared Database**: Both instances connect to the same PostgreSQL database (`DATABASE_URL`).
- **Shared Authentication**: SimpleJWT stateless tokens signed with identical `SECRET_KEY`. A token issued by Server A is immediately valid on Server B without session stickiness.
- **Idempotency & Replay Protection**:
  - Checkout orders (`Idempotency-Key` cached via Redis / Django Cache).
  - Webhook callbacks (`Payment.status == 'PAID'` and `WalletTransaction` deduplication).
  - Phone OTP verification (atomic consumption with immediate deletion).
  - Delivery confirmation (single-use `DeliveryConfirmationToken` with database locking).
- **Zero-Leak Health Probes**:
  - `/health/live` (Liveness: returns HTTP 200 without DB query).
  - `/health/ready` (Readiness: validates `SELECT 1` on DB connection; returns generic 200 or 503 with zero credential leakage).

---

## 2. Cloudflare Load Balancing 50/50 Configuration (Dashboard)

### Step 1: Create the Health Monitor
1. Log in to the **Cloudflare Dashboard** -> Select your domain (`foodgo.app`).
2. Navigate to **Traffic** -> **Load Balancing** -> **Manage Monitors** -> **Create Monitor**.
3. Fill in the monitor settings:
   - **Type**: HTTPS
   - **Path**: `/health/ready`
   - **Port**: 443
   - **Interval**: `60` seconds (or `15` seconds on Pro/Enterprise)
   - **Timeout**: `5` seconds
   - **Retries**: `2`
   - **Expected Codes**: `200`
   - **Follow Redirects**: Off
4. Click **Save**.

### Step 2: Create the 50/50 Origin Pool
1. In **Load Balancing**, go to **Manage Pools** -> **Create Pool**.
2. **Pool Name**: `foodgo-dual-pool-50-50`
3. Add the two backend origins:
   - **Origin 1**:
     - Name: `vercel-origin-a`
     - Address: `foodgo-backend-a.vercel.app`
     - Weight: `0.5`
     - Host Header Override: `foodgo-backend-a.vercel.app`
   - **Origin 2**:
     - Name: `vercel-origin-b`
     - Address: `foodgo-backend-b.vercel.app`
     - Weight: `0.5`
     - Host Header Override: `foodgo-backend-b.vercel.app`
4. Attach the monitor created in Step 1.
5. Set **Healthy Threshold**: `2`, **Unhealthy Threshold**: `2`.
6. Click **Save**.

### Step 3: Configure the Load Balancer
1. In **Load Balancing**, click **Create Load Balancer**.
2. **Hostname**: `api.foodgo.app`
3. **Default Pool**: Select `foodgo-dual-pool-50-50`.
4. **Steering Policy**: Select **Dynamic steering** or **Round robin** (Weighted).
5. **Session Affinity**: None (Stateless JWT) or Cookie (if sticky sessions preferred).
6. Click **Save and Deploy**.

---

## 3. Cloudflare API Configuration (Automated Setup)

```bash
# 1. Create Health Monitor
curl -X POST "https://api.cloudflare.com/client/v4/user/load_balancers/monitors" \
     -H "Authorization: Bearer YOUR_CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{
       "description": "FoodGo Database Readiness Monitor",
       "type": "https",
       "method": "GET",
       "path": "/health/ready",
       "port": 443,
       "expected_codes": "200",
       "timeout": 5,
       "interval": 60,
       "retries": 2
     }'

# 2. Create 50/50 Origin Pool
curl -X POST "https://api.cloudflare.com/client/v4/user/load_balancers/pools" \
     -H "Authorization: Bearer YOUR_CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{
       "name": "foodgo-dual-pool-50-50",
       "monitor": "MONITOR_ID_FROM_STEP_1",
       "minimum_origins": 1,
       "origins": [
         {
           "name": "origin-a",
           "address": "foodgo-backend-a.vercel.app",
           "enabled": true,
           "weight": 0.5,
           "header": {
             "Host": ["foodgo-backend-a.vercel.app"]
           }
         },
         {
           "name": "origin-b",
           "address": "foodgo-backend-b.vercel.app",
           "enabled": true,
           "weight": 0.5,
           "header": {
             "Host": ["foodgo-backend-b.vercel.app"]
           }
         }
       ]
     }'

# 3. Create Load Balancer on api.foodgo.app
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/load_balancers" \
     -H "Authorization: Bearer YOUR_CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{
       "name": "api.foodgo.app",
       "default_pools": ["POOL_ID_FROM_STEP_2"],
       "fallback_pool": "POOL_ID_FROM_STEP_2",
       "steering_policy": "dynamic_latency",
       "proxied": true
     }'
```

---

## 4. Cloudflare Worker Edge 50/50 Load Balancing (Built-in Alternative)

If you do not have an active Cloudflare Load Balancing subscription ($5/mo), the included `worker.js` automatically performs edge load balancing across both backend servers:

```javascript
// From worker.js:
const backendA = env.BACKEND_A_URL || 'https://foodgo-backend-a.vercel.app';
const backendB = env.BACKEND_B_URL || 'https://foodgo-backend-b.vercel.app';

// 50/50 Traffic Split
const pickA = Math.random() < 0.5;
const primaryOrigin = pickA ? backendA : backendB;
const secondaryOrigin = pickA ? backendB : backendA;
```

**Failover Behavior**:
- If the selected primary origin returns a `502`, `503`, `504` error or network timeout, `worker.js` automatically sends the request to the secondary origin within milliseconds.
- Clients experience zero errors during origin downtime.
- Injects `X-FoodGo-Origin: A` (or `B`) and `X-FoodGo-Failover: true` for observability.

---

## 5. Backend Security Hardening Checklist

| Security Control | Implementation |
|---|---|
| **Reverse Proxy Normalization** | `SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')` |
| **Host Header Validation** | `USE_X_FORWARDED_HOST = True`, strict `ALLOWED_HOSTS` |
| **Cross-Origin Protection** | `CORS_ALLOWED_ORIGINS` & `CSRF_TRUSTED_ORIGINS` for `*.foodgo.app` |
| **Content Security** | `X_FRAME_OPTIONS = 'DENY'`, `SECURE_CONTENT_TYPE_NOSNIFF = True` |
| **Rate Limiting** | `AnonRateThrottle` (200/min), `UserRateThrottle` (1000/min) |
| **Idempotency** | `Idempotency-Key` header with cached response replay |
| **OTP Replay Protection** | Immediate atomic deletion upon verification |
| **Payment Protection** | Database row locking (`select_for_update()`) and transaction hash checking |

---

## 6. Non-Disruptive Failover Verification Test

To verify 50/50 distribution and automated failover in staging:

1. **Verify 50/50 Distribution**:
   Run 10 consecutive requests to the API health endpoint:
   ```bash
   for i in {1..10}; do
     curl -sI https://api.foodgo.app/health/live/ | grep -i "X-FoodGo-Origin"
   done
   ```
   *Expected Result*: Approximately 5 requests handled by Origin A and 5 requests handled by Origin B.

2. **Simulate Origin A Degradation**:
   In Vercel Project A dashboard, set an environment variable or pause deployments, or disable Origin A in Cloudflare Pool.
   *Expected Result*: Cloudflare Load Balancer / Worker immediately steers 100% of traffic to Origin B within health check interval.

3. **Verify Recovery**:
   Re-enable Origin A.
   *Expected Result*: Cloudflare marks Origin A healthy after 2 consecutive 200 responses and restores the 50/50 traffic split.
