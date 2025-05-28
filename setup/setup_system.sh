#!/bin/bash

set -e

export HUGGINGFACE_HUB_TOKEN=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

# 📁 Chemin vers le modèle et cache
MODEL_REPO="mistralai/Mixtral-8x7B-Instruct-v0.1"
MODEL_DIR="/workspace/models/mixtral"
export HF_HUB_CACHE="/workspace/tmp/hf-cache"
mkdir -p "$HF_HUB_CACHE" "$MODEL_DIR"

# 🔧 Préparation système
apt update && apt install -y \
    build-essential \
    cmake \
    ninja-build \
    python3-pip \
    python3.10-dev \
    git \
    curl \
    nano \
    nginx

# 🔄 Nettoyage et installation de torch & deps
pip uninstall -y torch numpy bitsandbytes || true
pip install numpy==1.24.1 --no-cache-dir
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

pip uninstall -y bitsandbytes

# 📁 Cloner le repo officiel dans un répertoire temporaire
cd /workspace
rm -rf bitsandbytes
git clone https://github.com/bitsandbytes-cuda/bitsandbytes.git
cd bitsandbytes

# 📌 Compilation avec support CUDA 11.x (ex: 11.8)
export CUDA_VERSION=118
make cuda11x

# 🧱 Installation locale
pip install .

# 🔙 Retour au dossier principal
cd /workspace

# 🧩 Installation de transformers & autres
pip install \
    transformers \
    accelerate \
    fastapi \
    uvicorn \
    sentencepiece \
    safetensors \
    huggingface_hub \
    protobuf \
    --no-cache-dir

# 📥 Téléchargement du modèle HuggingFace
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(repo_id='$MODEL_REPO', local_dir='$MODEL_DIR', local_dir_use_symlinks=False, token='$HUGGINGFACE_HUB_TOKEN')
"

# 🔧 Nginx config pour proxy local
NGINX_CONF="/etc/nginx/sites-available/default"
cp "$NGINX_CONF" "$NGINX_CONF.backup"

cat > "$NGINX_CONF" <<EOF
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

# 🚀 Lancement serveur FastAPI
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &
