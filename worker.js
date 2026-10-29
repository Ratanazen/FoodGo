// Cloudflare Edge Worker for FoodGo
// Dual-backend 50/50 steering, zero-downtime active failover, edge caching, and strict CORS handling

// ============================================================================
// Public GET endpoints eligible for edge caching (short TTLs)
// NEVER cache: auth, tokens, OTP, orders, payments, wallets, notifications, admin, drivers, user profile
// ============================================================================
const CACHEABLE_PATTERNS = [
  { pattern: /^\/api\/restaurants\/$/, ttl: 120 },
  { pattern: /^\/api\/restaurants\/\d+\/$/, ttl: 120 },
  { pattern: /^\/api\/restaurant-categories\//, ttl: 300 },
  { pattern: /^\/api\/food-categories\//, ttl: 120 },
  { pattern: /^\/api\/food-items\//, ttl: 120 },
  { pattern: /^\/api\/currency\/rates\//, ttl: 600 },
  { pattern: /^\/api\/recommendations\//, ttl: 120 },
  { pattern: /^\/api\/coupons\/$/, ttl: 120 },
  { pattern: /^\/api\/live-items\//, ttl: 60 },
  { pattern: /^\/media\/mongo\//, ttl: 3600 },
  { pattern: /^\/api\/media\/mongo\//, ttl: 3600 },
  { pattern: /^\/static\//, ttl: 86400 },
];

// Endpoints that must NEVER be cached regardless of method
const NEVER_CACHE_PATTERNS = [
  /^\/health/,
  /^\/api\/health/,
  /^\/api\/token/,
  /^\/api\/auth\//,
  /^\/api\/register/,
  /^\/api\/me\//,
  /^\/api\/orders\//,
  /^\/api\/payments\//,
  /^\/api\/wallets\//,
  /^\/api\/notifications\//,
  /^\/api\/admin\//,
  /^\/admin/,
  /^\/api\/drivers\//,
  /^\/api\/addresses\//,
  /^\/api\/carts\//,
  /^\/api\/cart-items\//,
  /^\/api\/favorites\//,
  /^\/api\/reviews\//,
  /^\/api\/forgot-password/,
  /^\/api\/mongodb\/sync/,
  /^\/api\/media\/mongo\/upload/,
];

// Request timeout for backend fetch (milliseconds)
const BACKEND_TIMEOUT_MS = 25000;

const ALLOWED_ORIGIN_HOSTS = new Set([
  'foodgo.rtnaeam611.workers.dev',
  'food-go-app.vercel.app',
  'foodgo-backend-a.vercel.app',
  'foodgo-backend-b.vercel.app',
  'foodgo-53pl.onrender.com',
  'localhost',
  '127.0.0.1',
  '0.0.0.0',
]);

function isAuthorizedOrigin(origin) {
  if (!origin) return false;
  try {
    const parsed = new URL(origin);
    const host = parsed.hostname;
    if (ALLOWED_ORIGIN_HOSTS.has(host)) return true;
    if (host === 'foodgo.app' || host.endsWith('.foodgo.app')) return true;
  } catch (_) {
    return false;
  }
  return false;
}

function applyCorsHeaders(targetHeaders, requestOrigin) {
  if (isAuthorizedOrigin(requestOrigin)) {
    targetHeaders.set('Access-Control-Allow-Origin', requestOrigin);
    targetHeaders.set('Access-Control-Allow-Credentials', 'true');
    targetHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD');
    targetHeaders.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, Accept, Origin, User-Agent, X-Requested-With, X-FoodGo-LB, Idempotency-Key');
    targetHeaders.set('Access-Control-Max-Age', '86400');
  }
}

/**
 * Check if a request path + method is eligible for edge caching.
 * Returns the TTL in seconds, or 0 if not cacheable.
 */
function getCacheTtl(method, pathname, hasAuthHeader) {
  // Only cache GET/HEAD requests
  if (method !== 'GET' && method !== 'HEAD') return 0;

  // Never cache if the request carries an Authorization header (user-specific data)
  if (hasAuthHeader) return 0;

  // Check explicit never-cache patterns
  for (const pattern of NEVER_CACHE_PATTERNS) {
    if (pattern.test(pathname)) return 0;
  }

  // Check cacheable patterns
  for (const { pattern, ttl } of CACHEABLE_PATTERNS) {
    if (pattern.test(pathname)) return ttl;
  }

  return 0;
}

/**
 * Fetch with timeout using AbortController.
 * Returns the response or throws on timeout/network error.
 */
async function fetchWithTimeout(request, timeoutMs) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(request, { signal: controller.signal });
    return response;
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Determine if a mutating request is safe to retry on failover.
 * Non-idempotent writes (POST/PUT/PATCH/DELETE) are only retried if an Idempotency-Key is present.
 */
function isSafeToRetry(method, headers) {
  if (method === 'GET' || method === 'HEAD' || method === 'OPTIONS') return true;
  // Allow retry if idempotency key is present
  const hasIdempotencyKey = headers.has('Idempotency-Key') || headers.has('X-Idempotency-Key');
  return hasIdempotencyKey;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const requestOrigin = request.headers.get('Origin');

    // 1. Direct handling of CORS preflight requests
    if (request.method === 'OPTIONS') {
      const preflightHeaders = new Headers();
      preflightHeaders.set('Vary', 'Origin');
      applyCorsHeaders(preflightHeaders, requestOrigin);
      return new Response(null, {
        status: 204,
        headers: preflightHeaders,
      });
    }

    // 2. Proxy API, Health, Admin, Static, and Media endpoints with 50/50 dual-backend load balancing
    if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/health') || url.pathname.startsWith('/healthz') || url.pathname.startsWith('/admin') || url.pathname.startsWith('/static/') || url.pathname.startsWith('/media/')) {

      // --- Edge Cache Check ---
      const hasAuthHeader = request.headers.has('Authorization');
      const hasCookieHeader = request.headers.has('Cookie') && (request.headers.get('Cookie') || '').includes('sessionid');
      const cacheTtl = getCacheTtl(request.method, url.pathname, hasAuthHeader, hasCookieHeader);
      const cache = caches.default;

      if (cacheTtl > 0) {
        // Build a cache key from the full URL (query params included)
        const cacheKey = new Request(url.toString(), { method: 'GET' });
        const cachedResponse = await cache.match(cacheKey);
        if (cachedResponse) {
          // Return cached response with cache hit indicator
          const hitHeaders = new Headers(cachedResponse.headers);
          hitHeaders.set('X-FoodGo-Cache', 'HIT');
          hitHeaders.set('Vary', 'Origin');
          applyCorsHeaders(hitHeaders, requestOrigin);
          return new Response(cachedResponse.body, {
            status: cachedResponse.status,
            statusText: cachedResponse.statusText,
            headers: hitHeaders,
          });
        }
      }

      // --- Backend Proxy ---
      const sanitizeOrigin = (urlStr) => {
        if (!urlStr || typeof urlStr !== 'string') {
          return 'https://food-go-app.vercel.app';
        }
        const clean = urlStr.trim();
        if (clean.includes('foodgo-backend-b.vercel.app') || clean.includes('foodgo-backend-a.vercel.app')) {
          return 'https://food-go-app.vercel.app';
        }
        return clean.endsWith('/') ? clean.slice(0, -1) : clean;
      };

      const backendA = sanitizeOrigin(env.BACKEND_A_URL);
      const backendB = sanitizeOrigin(env.BACKEND_B_URL);
      const legacyBackend = sanitizeOrigin(env.BACKEND_URL);

      // 50/50 Traffic Split
      const pickA = Math.random() < 0.5;
      const primaryOrigin = pickA ? backendA : backendB;
      const secondaryOrigin = pickA ? backendB : backendA;
      const primaryTag = pickA ? 'A' : 'B';
      const secondaryTag = pickA ? 'B' : 'A';

      // Buffer request body once to allow retry on secondary backend for mutating methods
      const hasBody = !['GET', 'HEAD'].includes(request.method);
      const requestBody = hasBody ? await request.arrayBuffer() : null;

      // Check if this request is safe to retry on failover
      const canRetry = isSafeToRetry(request.method, request.headers);

      // Helper function to build proxied request for a given target origin
      const createProxyRequest = (targetOrigin) => {
        let proxyPath = url.pathname;
        if (proxyPath === '/health' || proxyPath === '/healthz') {
          proxyPath = '/health/';
        }
        const targetUrl = new URL(proxyPath + url.search, targetOrigin);
        const headers = new Headers(request.headers);
        headers.set('Host', new URL(targetOrigin).host);
        headers.set('X-Forwarded-Host', url.host);
        headers.set('X-Forwarded-Proto', 'https');
        headers.set('X-FoodGo-LB', 'Cloudflare-Worker-50-50');

        return new Request(targetUrl, {
          method: request.method,
          headers: headers,
          body: requestBody,
          redirect: 'follow',
        });
      };

      let response;
      let activeTag = primaryTag;
      let didFailover = false;

      try {
        response = await fetchWithTimeout(createProxyRequest(primaryOrigin), BACKEND_TIMEOUT_MS);
        // Failover if primary returns 5xx server error or Vercel DEPLOYMENT_NOT_FOUND (404)
        const isFailure = [500, 502, 503, 504].includes(response.status) ||
          (response.status === 404 && response.headers.get('x-vercel-error') === 'DEPLOYMENT_NOT_FOUND');

        if (isFailure && primaryOrigin !== secondaryOrigin && canRetry) {
          try {
            const failoverResponse = await fetchWithTimeout(createProxyRequest(secondaryOrigin), BACKEND_TIMEOUT_MS);
            if (failoverResponse.ok || failoverResponse.status < 500) {
              response = failoverResponse;
              activeTag = secondaryTag;
              didFailover = true;
            }
          } catch (_) {
            // Keep original response if secondary instance also fails
          }
        }
      } catch (err) {
        // Network, DNS, or timeout error on primary instance
        if (canRetry) {
          try {
            response = await fetchWithTimeout(createProxyRequest(secondaryOrigin), BACKEND_TIMEOUT_MS);
            activeTag = secondaryTag;
            didFailover = true;
          } catch (secondaryErr) {
            // Attempt legacy backend fallback if configured
            try {
              response = await fetchWithTimeout(createProxyRequest(legacyBackend), BACKEND_TIMEOUT_MS);
              activeTag = 'legacy';
            } catch (legacyErr) {
              const errHeaders = new Headers({ 'Content-Type': 'application/json' });
              applyCorsHeaders(errHeaders, requestOrigin);
              return new Response(JSON.stringify({
                error: 'Backend instances unavailable',
                status: 503,
                details: 'Both Origin A and Origin B failed to respond.'
              }), {
                status: 503,
                headers: errHeaders,
              });
            }
          }
        } else {
          // Non-idempotent request without idempotency key — don't retry, return error
          const errHeaders = new Headers({ 'Content-Type': 'application/json' });
          applyCorsHeaders(errHeaders, requestOrigin);
          return new Response(JSON.stringify({
            error: 'Backend temporarily unavailable',
            status: 503,
            details: 'Primary backend failed. Retry was not attempted for this mutating request to prevent duplicates. Include an Idempotency-Key header to enable safe retry.'
          }), {
            status: 503,
            headers: errHeaders,
          });
        }
      }

      // Build outgoing response with security and CORS headers
      const resHeaders = new Headers(response.headers);
      resHeaders.set('X-Content-Type-Options', 'nosniff');
      resHeaders.set('X-Frame-Options', 'SAMEORIGIN');
      resHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin');
      resHeaders.set('X-FoodGo-Origin', activeTag);
      resHeaders.set('Vary', 'Origin');

      resHeaders.set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');

      if (didFailover) {
        resHeaders.set('X-FoodGo-Failover', 'true');
      }

      // Add appropriate Cache-Control headers based on endpoint type
      if (hasAuthHeader || hasCookieHeader || NEVER_CACHE_PATTERNS.some(p => p.test(url.pathname))) {
        resHeaders.set('Cache-Control', 'no-store, private');
      }

      applyCorsHeaders(resHeaders, requestOrigin);

      const finalResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: resHeaders,
      });

      // --- Store cacheable responses in edge cache ---
      if (cacheTtl > 0 && response.ok) {
        const cacheKey = new Request(url.toString(), { method: 'GET' });
        const cacheHeaders = new Headers(resHeaders);
        cacheHeaders.set('Cache-Control', `public, max-age=${cacheTtl}`);
        cacheHeaders.set('X-FoodGo-Cache', 'MISS');
        const cacheResponse = new Response(finalResponse.clone().body, {
          status: response.status,
          statusText: response.statusText,
          headers: cacheHeaders,
        });
        ctx.waitUntil(cache.put(cacheKey, cacheResponse));
      }

      return finalResponse;
    }

    // 3. Serve static web assets with single-page-application fallback
    if (env.ASSETS && typeof env.ASSETS.fetch === 'function') {
      const response = await env.ASSETS.fetch(request);
      const newHeaders = new Headers(response.headers);
      newHeaders.set('X-Frame-Options', 'SAMEORIGIN');
      newHeaders.set('X-Content-Type-Options', 'nosniff');
      newHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin');
      applyCorsHeaders(newHeaders, requestOrigin);

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders,
      });
    }

    return new Response('FoodGo Edge Worker Active', {
      status: 200,
      headers: { 'Content-Type': 'text/plain' },
    });
  },
};
