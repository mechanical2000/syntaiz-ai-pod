#!/bin/bash
set -e

# 🔐 Auth Hugging Face (nécessaire si modèle est gated)
export HUGGINGFACE_HUB_TOKEN=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

# 📁 Variables
MODEL_ID="mistralai/Mixtral-8x7B-Instruct-v0.1"
MODEL_DIR="/workspace/models/mixtral"

# 📦 Màj système
apt update && apt install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    nano \
    python3-pip \
    python3.10-dev \
    nginx \
    libprotobuf-dev protobuf-compiler

# 📦 Pip + numpy (fallback version)
pip install --upgrade pip
pip install numpy --no-cache-dir

# 📦 Librairies IA
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir
pip install \
    transformers \
    accelerate \
    bitsandbytes \
    sentencepiece \
    safetensors \
    huggingface_hub \
    protobuf \
    --no-cache-dir


# 🔄 Configuration de Nginx pour reverse proxy vers Uvicorn
NGINX_DEFAULT_CONF="/etc/nginx/sites-available/default"
cp "$NGINX_DEFAULT_CONF" "${NGINX_DEFAULT_CONF}.backup"

cat > "$NGINX_DEFAULT_CONF" <<EOF
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

echo "🔄 Redémarrage de Nginx"
nginx -t && (nginx -s stop 2>/dev/null || true) && nginx

# 🚀 Démarrage de l'app FastAPI
echo "🚀 Lancement de FastAPI via Uvicorn"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# ✅ Affichage d'infos finales
IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé. Tu peux tester avec :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
