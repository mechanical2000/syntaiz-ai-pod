#!/bin/bash

set -e

echo "🚀 Mise à jour du système"
apt update && apt install -y \
    python3-pip \
    git \
    curl \
    nano \
    nginx

# 👉 Utiliser des répertoires temporaires sûrs dans /workspace
export TMPDIR=/workspace/tmp
export PIP_CACHE_DIR=/workspace/pip-cache
mkdir -p $TMPDIR $PIP_CACHE_DIR

echo "📦 Installation des dépendances Python"
pip install --no-cache-dir --cache-dir=$PIP_CACHE_DIR \
    -r /workspace/syntaiz-ai-pod/setup/requirements.txt

echo "🚀 Lancement de l'app FastAPI (Uvicorn) en arrière-plan"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > /workspace/app.log 2>&1 &

echo "🛠️ Configuration de Nginx pour rediriger / vers FastAPI (localhost:8000)"
NGINX_DEFAULT_CONF="/etc/nginx/sites-available/default"
cp "$NGINX_DEFAULT_CONF" "${NGINX_DEFAULT_CONF}.backup"

cat > "$NGINX_DEFAULT_CONF" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

echo "🔄 Arrêt complet de Nginx existant et redémarrage propre"

# Stopper tous les nginx (s’il y en a), supprimer le pid corrompu
pkill -f nginx 2>/dev/null || true
rm -f /run/nginx.pid

# Tester la config et relancer
nginx -t && nginx

# 🔚 Nettoyage temporaire
echo "🧹 Nettoyage des fichiers temporaires"
rm -rf $TMPDIR $PIP_CACHE_DIR

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Tu peux tester ton API immédiatement avec :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
