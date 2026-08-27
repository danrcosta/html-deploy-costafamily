export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname === '/' ? '/index.html' : url.pathname;
    
    // Arquivos estáticos mapeados
    const files = {
      '/index.html': '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Costa Family HTML Deploy</title><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="font-family:system-ui;max-width:800px;margin:40px auto;padding:20px"><h1>✅ HTML Deploy Pipeline</h1><p>Status: <strong>Ativo</strong></p><p>Domínio: <a href="https://costafamily.ai">costafamily.ai</a></p><p>Backup: <a href="https://github.com/danrcosta/html-deploy-costafamily">GitHub</a></p><p>GitHub Pages: <a href="https://danrcosta.github.io/html-deploy-costafamily/">Pages</a></p><p><em>Próximo passo: substituir este conteúdo pelo seu HTML real</em></p></body></html>',
    };
    
    const content = files[path] || files['/index.html'];
    
    const headers = {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=3600'
    };
    
    // Adiciona Content-Type baseado extensão
    if (path.endsWith('.css')) headers['Content-Type'] = 'text/css';
    if (path.endsWith('.js')) headers['Content-Type'] = 'application/javascript';
    if (path.endsWith('.png')) headers['Content-Type'] = 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) headers['Content-Type'] = 'image/jpeg';
    
    return new Response(content, { headers });
  }
};