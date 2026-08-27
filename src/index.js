export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname === '/' ? '/index.html' : url.pathname;
    
    // Mapeia caminhos para arquivos estáticos
    const file = path.startsWith('/static/') ? path : `/ready${path}`;
    
    try {
      // Tenta servir arquivo estático
      const response = await env.ASSETS.fetch(request);
      if (response.status === 404) {
        // Fallback para index.html (SPA)
        return new Response(await env.ASSETS.fetch(new Request(new URL('/index.html', url))).then(r => r.text()), {
          headers: { 'Content-Type': 'text/html' }
        });
      }
      return response;
    } catch (e) {
      // Fallback
      return new Response('<!DOCTYPE html><html><body><h1>Costa Family HTML Serve</h1><p>Deploy via Cloudflare Worker</p></body></html>', {
        headers: { 'Content-Type': 'text/html' }
      });
    }
  }
};