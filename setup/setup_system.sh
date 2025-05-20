#!/bin/bash

set -e

echo "🚀 Mise à jour du système"
apt update && apt install -y \
    python3-pip \
    git \
    curl \
    nano \
    nginx

echo "📦 Installation des dépendances Python"
pip install --upgrade pip
pip install -r /workspace/syntaiz-ai-pod/setup/requirements.txt

echo "🚀 Lancement de l'app FastAPI (Uvicorn) en arrière-plan"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > /workspace/app.log 2>&1 &

echo "🛠️ Configuration de Nginx pour rediriger / vers FastAPI (localhost:8000)"
NGINX_DEFAULT_CONF="/etc/nginx/sites-available/default"

# Sauvegarde de la conf actuelle
cp "$NGINX_DEFAULT_CONF" "${NGINX_DEFAULT_CONF}.backup"

# Écriture de la nouvelle config
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

echo "🔄 Redémarrage de Nginx propre"
nginx -t && nginx -s stop || true
nginx

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
