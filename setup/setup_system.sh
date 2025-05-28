#!/bin/bash
set -e

export HUGGINGFACE_HUB_TOKEN=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

# 📁 Cache HuggingFace local
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📁 Modèle local
MODEL_REPO="mistralai/Mixtral-8x7B-Instruct-v0.1"
MODEL_DIR="/workspace/models/mixtral"

# 📦 Installation minimale
pip install \
    numpy==1.26.3 \
    transformers \
    accelerate \
    sentencepiece \
    safetensors \
    fastapi \
    uvicorn \
    huggingface_hub \
    protobuf \
    --no-cache-dir

# 📥 Téléchargement du modèle Mixtral si manquant
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle quantifié Mixtral (4bit)..."
    mkdir -p $MODEL_DIR
    python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='$MODEL_REPO',
    local_dir='$MODEL_DIR',
    token='$HUGGINGFACE_HUB_TOKEN',
    local_dir_use_symlinks=False
)"
else
    echo "✅ Modèle déjà présent dans $MODEL_DIR"
fi

# 🔧 NGINX proxy
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

echo "🔄 Redémarrage de NGINX"
nginx -t && (nginx -s stop 2>/dev/null || true) && nginx

# 🚀 Lancement FastAPI
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# ✅ Vérif CUDA
echo "🔍 Test GPU"
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

rm -rf /workspace/tmp
