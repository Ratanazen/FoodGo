export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Proxy API requests to backend
    if (url.pathname.startsWith('/api/')) {
      const backendUrl = env.BACKEND_URL || 'https://food-go-app.vercel.app';
      const targetUrl = new URL(url.pathname + url.search, backendUrl);
      const proxyRequest = new Request(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: request.body,
        redirect: 'follow',
      });
      return fetch(proxyRequest);
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
