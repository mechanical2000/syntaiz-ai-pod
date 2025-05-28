#!/bin/bash

set -e

export HUGGINGFACE_HUB_TOKEN=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

# 📁 Cache HF local
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📁 Répertoires
MODEL_DIR=/workspace/models/mixtral
TMPDIR=/workspace/tmp
mkdir -p $TMPDIR

echo "🚀 Mise à jour du système"
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

# 🔄 Torch + numpy
pip uninstall -y torch numpy bitsandbytes || true
pip install numpy==1.26.3 --no-cache-dir
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

# 🔧 Compilation de bitsandbytes pour CUDA 11.8
echo "🔧 Compilation de bitsandbytes depuis la source pour CUDA 11.8"
cd /workspace
rm -rf bitsandbytes
git clone https://github.com/bitsandbytes-cuda/bitsandbytes.git
cd bitsandbytes
export BNB_CUDA_VERSION=118
python3 setup.py install
cd -

# 📦 Paquets Python nécessaires
pip install \
    transformers \
    fastapi \
    uvicorn \
    sentencepiece \
    safetensors \
    huggingface_hub \
    accelerate \
    protobuf \
    optimum \
    --no-cache-dir

# 🔄 Configuration NGINX
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

echo "🔁 Redémarrage NGINX"
nginx -t && (nginx -s stop 2>/dev/null || true) && nginx

echo "🚀 Lancement de l'app FastAPI"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# Nettoyage
rm -rf $TMPDIR

# 🧪 Test GPU
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Teste l’API via NGINX avec la commande suivante :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
