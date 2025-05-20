#!/bin/bash

set -e

echo "🚀 Mise à jour du système"
apt update && apt install -y \
    python3-pip \
    nginx \
    certbot \
    python3-certbot-nginx \
    git \
    curl \
    nano

echo "📦 Installation des dépendances Python"
pip install --upgrade pip
pip install -r /workspace/syntaiz-ai-pod/setup/requirements.txt

echo "⚙️ Configuration Nginx"
NGINX_CONF="/etc/nginx/sites-available/syntaiz"
NGINX_LINK="/etc/nginx/sites-enabled/syntaiz"

# Créer ou écraser la config Nginx
cat > $NGINX_CONF <<EOF
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

# Activer le site si non lié
[ -e "$NGINX_LINK" ] || ln -s $NGINX_CONF $NGINX_LINK

echo "🔍 Vérification de la configuration Nginx"
nginx -t

echo "🔄 Redémarrage de Nginx (compatible RunPod)"
nginx -s reload || nginx

echo "🚀 Lancement de l'app FastAPI en arrière-plan"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > /workspace/app.log 2>&1 &

IP_PUBLIQUE=$(curl -s ifconfig.me)

echo "✅ Déploiement terminé !"
echo "🌐 Teste ton API avec :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Qu’est-ce qu’un synonyme ?\"}'"
echo ""
