#!/bin/bash

set -e

export HUGGINGFACE_HUB_TOKEN=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
export HF_HUB_CACHE=/workspace/tmp/hf-cache
export MODEL_DIR=/workspace/models/mixtral-4bit
MODEL_REPO="mistralai/Mixtral-8x7B-Instruct-v0.1"

mkdir -p $HF_HUB_CACHE $MODEL_DIR

echo "🚀 Mise à jour du système"
apt update && apt install -y \
  build-essential \
  cmake \
  python3-pip \
  python3.10-dev \
  git \
  curl \
  nano \
  nginx

export TMPDIR=/workspace/tmp
mkdir -p $TMPDIR

echo "📦 Installation PyTorch + deps"
pip uninstall -y torch numpy || true
pip install numpy==1.26.3 --no-cache-dir
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

echo "📦 Installation bitsandbytes via GitHub"
pip install git+https://github.com/TimDettmers/bitsandbytes.git --no-cache-dir

echo "📦 Installation des libs nécessaires"
pip install \
  transformers \
  accelerate \
  safetensors \
  sentencepiece \
  fastapi \
  uvicorn \
  huggingface_hub \
  optimum \
  --no-cache-dir

echo "📥 Téléchargement du modèle $MODEL_REPO dans $MODEL_DIR..."
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='$MODEL_REPO',
    local_dir='$MODEL_DIR',
    local_dir_use_symlinks=False,
    token='$HUGGINGFACE_HUB_TOKEN'
)
"

echo "🔄 Configuration de Nginx pour reverse proxy"
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

echo "🚀 Lancement de l'app FastAPI (Uvicorn) en arrière-plan"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

echo "🧹 Nettoyage des fichiers temporaires"
rm -rf $TMPDIR

echo "🔍 Test GPU"
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Tu peux tester ton API via le proxy Nginx :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
