export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Proxy API and Health endpoints with 50/50 dual-backend load balancing and active failover
    if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/health') || url.pathname.startsWith('/healthz')) {
      const backendA = env.BACKEND_A_URL || 'https://foodgo-backend-a.vercel.app';
      const backendB = env.BACKEND_B_URL || 'https://foodgo-backend-b.vercel.app';
      const legacyBackend = env.BACKEND_URL || 'https://food-go-app.vercel.app';

      // 50/50 Traffic Split
      const pickA = Math.random() < 0.5;
      const primaryOrigin = pickA ? backendA : backendB;
      const secondaryOrigin = pickA ? backendB : backendA;
      const primaryTag = pickA ? 'A' : 'B';
      const secondaryTag = pickA ? 'B' : 'A';

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
          body: ['GET', 'HEAD'].includes(request.method) ? null : request.body,
          redirect: 'follow',
        });
      };

      let response;
      let activeTag = primaryTag;
      let didFailover = false;

      try {
        response = await fetch(createProxyRequest(primaryOrigin));
        // If primary instance returns server error (502, 503, 504), failover to secondary instance
        if ([502, 503, 504].includes(response.status) && primaryOrigin !== secondaryOrigin) {
          try {
            const failoverResponse = await fetch(createProxyRequest(secondaryOrigin));
            if (failoverResponse.ok || failoverResponse.status < 500) {
              response = failoverResponse;
              activeTag = secondaryTag;
              didFailover = true;
            }
          } catch (_) {
            // Keep original response if secondary also fails
          }
        }
      } catch (err) {
        // Network/DNS error on primary, try secondary origin
        try {
          response = await fetch(createProxyRequest(secondaryOrigin));
          activeTag = secondaryTag;
          didFailover = true;
        } catch (secondaryErr) {
          // If both fail, attempt legacy backend fallback
          try {
            response = await fetch(createProxyRequest(legacyBackend));
            activeTag = 'legacy';
          } catch (legacyErr) {
            return new Response(JSON.stringify({
              error: 'Backend instances unavailable',
              status: 503,
              details: 'Both Origin A and Origin B failed to respond.'
            }), {
              status: 503,
              headers: { 'Content-Type': 'application/json' }
            });
          }
        }
      }

      // Add security & observability headers
      const resHeaders = new Headers(response.headers);
      resHeaders.set('X-Content-Type-Options', 'nosniff');
      resHeaders.set('X-Frame-Options', 'SAMEORIGIN');
      resHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin');
      resHeaders.set('X-FoodGo-Origin', activeTag);
      if (didFailover) {
        resHeaders.set('X-FoodGo-Failover', 'true');
      }

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: resHeaders,
      });
    }

    // Serve static assets with single-page-application fallback
    const response = await env.ASSETS.fetch(request);
    const newHeaders = new Headers(response.headers);
    newHeaders.set('X-Frame-Options', 'SAMEORIGIN');
    newHeaders.set('X-Content-Type-Options', 'nosniff');
    newHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin');

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: newHeaders,
    });
  },
};
