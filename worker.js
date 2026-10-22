// Cloudflare Edge Worker for FoodGo
// Dual-backend 50/50 steering, zero-downtime active failover, and strict CORS handling

function isAuthorizedOrigin(origin) {
  if (!origin) return false;
  try {
    const parsed = new URL(origin);
    const host = parsed.hostname;
    if (host === 'foodgo.rtnaeam611.workers.dev') return true;
    if (host === 'food-go-app.vercel.app') return true;
    if (host.endsWith('.workers.dev')) return true;
    if (host.endsWith('.vercel.app')) return true;
    if (host.endsWith('foodgo.app')) return true;
    if (host.endsWith('.onrender.com')) return true;
    if (host === 'localhost' || host === '127.0.0.1' || host === '0.0.0.0') return true;
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

export default {
  async fetch(request, env) {
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

    // 2. Proxy API and Health endpoints with 50/50 dual-backend load balancing and active failover
    if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/health') || url.pathname.startsWith('/healthz')) {
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

      // Helper function to build proxied request for a given target origin
      const createProxyRequest = (targetOrigin) => {
        const targetUrl = new URL(url.pathname + url.search, targetOrigin);
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
        response = await fetch(createProxyRequest(primaryOrigin));
        // Failover if primary returns 5xx server error or Vercel DEPLOYMENT_NOT_FOUND (404)
        const isFailure = [500, 502, 503, 504].includes(response.status) ||
          (response.status === 404 && response.headers.get('x-vercel-error') === 'DEPLOYMENT_NOT_FOUND');

        if (isFailure && primaryOrigin !== secondaryOrigin) {
          try {
            const failoverResponse = await fetch(createProxyRequest(secondaryOrigin));
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
        // Network or DNS error on primary instance, try secondary origin
        try {
          response = await fetch(createProxyRequest(secondaryOrigin));
          activeTag = secondaryTag;
          didFailover = true;
        } catch (secondaryErr) {
          // Attempt legacy backend fallback if configured
          try {
            response = await fetch(createProxyRequest(legacyBackend));
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
      }

      // Build outgoing response with security and CORS headers
      const resHeaders = new Headers(response.headers);
      resHeaders.set('X-Content-Type-Options', 'nosniff');
      resHeaders.set('X-Frame-Options', 'SAMEORIGIN');
      resHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin');
      resHeaders.set('X-FoodGo-Origin', activeTag);
      resHeaders.set('Vary', 'Origin');

      if (didFailover) {
        resHeaders.set('X-FoodGo-Failover', 'true');
      }

      applyCorsHeaders(resHeaders, requestOrigin);

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: resHeaders,
      });
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
