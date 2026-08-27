#!/bin/bash
# 🚀 HTML Deploy Pipeline for costafamily.ai
# Flow: Local HTML → GitHub Backup → Cloudflare Deploy
#
# Usage: ./deploy.sh deploy nome-do-arquivo.html

set -e

# === Configurações ===
PROJECT_ROOT="$HOME/projects/html-deploy"
GITHUB_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN"
REPO="danrcosta/html-deploy-costafamily"
GITHUB_REMOTE="https://x-access-token:$GITHUB_TOKEN@github.com/$REPO.git"

# === Função: Deploy completo ===
deploy() {
    local file="$1"
    if [ -z "$file" ]; then
        echo "❌ Uso: deploy.sh deploy nome-do-arquivo.html"
        return 1
    fi

    echo "=== 🚀 Iniciando deploy de $file ==="

    # 1. Verifica arquivo existe
    if [ ! -f "$PROJECT_ROOT/ready/$file" ]; then
        echo "❌ Arquivo não encontrado em ready/: $file"
        return 1
    fi

    # 2. Atualiza index.html se for o arquivo principal
    if [ "$file" == "index.html" ]; then
        echo "🔄 Atualizando index.html principal..."
        cp "$PROJECT_ROOT/ready/$file" "$PROJECT_ROOT/index.html"
    fi

    # 3. Commit e push para GitHub
    cd "$PROJECT_ROOT"
    git add -A
    git commit -m "Deploy: $file ($(date '+%Y-%m-%d %H:%M'))"
    git push "$GITHUB_REMOTE" main

    echo "✅ Deploy concluído!"
    echo "   → GitHub: https://github.com/$REPO"
    echo "   → GitHub Pages: https://danrcosta.github.io/html-deploy-costafamily/"
    echo "   → Domínio: https://costafamily.ai"
}

# === Subcomandos ===
case "$1" in
    deploy)
        deploy "$2"
        ;;
    init)
        echo "=== Inicializando repositório ==="
        cd "$PROJECT_ROOT"
        git init
        git remote add origin "$GITHUB_REMOTE" || true
        git fetch origin
        git checkout -b main
        git pull origin main --allow-unrelated-histories
        echo "✅ Repositório inicializado"
        ;;
    status)
        cd "$PROJECT_ROOT"
        echo "=== Status do Repositório ==="
        git status
        echo "=== Arquivos ==="
        find . -type f -not -path "./.git/*" | sort
        ;;
    *)
        echo "Uso: deploy.sh [deploy|init|status] [arquivo]"
        echo ""
        echo "Comandos:"
        echo "  deploy <arquivo>  - Deploy HTML para GitHub e Cloudflare"
        echo "  init              - Inicializa repositório local"
        echo "  status            - Mostra status atual"
        ;;
esac