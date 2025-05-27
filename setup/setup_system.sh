#!/bin/bash

set -e

export HUGGINGFACE_HUB_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # Remplace par ton token perso

# 📁 Répertoires
export HF_HUB_CACHE=/workspace/tmp/hf-cache
MODEL_REPO="mistralai/Mixtral-8x7B-Instruct-v0.1"
MODEL_DIR=/workspace/models/mixtral
TMPDIR=/workspace/tmp

# 📦 Mise à jour système
apt update && apt install -y \
    build-essential \
    cmake \
    python3-pip \
    python3.10-dev \
    git \
    curl \
    nano \
    nginx

# 🔧 Python et pip
pip install --upgrade pip
pip install wheel setuptools

# 📦 Dépendances Python
pip install --no-cache-dir \
    torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 \
    bitsandbytes \
    transformers \
    accelerate \
    sentencepiece \
    safetensors \
    fastapi \
    uvicorn \
    huggingface_hub \
    protobuf \
    optimum

# 📥 Téléchargement conditionnel du modèle
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle ${MODEL_REPO}..."
    python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(repo_id='$MODEL_REPO', local_dir='$MODEL_DIR', local_dir_use_symlinks=False, token='$HUGGINGFACE_HUB_TOKEN')
"
else
    echo "✅ Modèle déjà présent dans $MODEL_DIR"
fi

# 🔄 Configuration Nginx
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

nginx -t && (nginx -s stop 2>/dev/null || true) && nginx

# 🚀 Lancement API
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

echo "✅ Lancement terminé"
