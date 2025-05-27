#!/bin/bash

set -e

export HUGGINGFACE_HUB_TOKEN=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

# 📁 Répertoire cache HF local
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📦 Modèle Mixtral 4bit depuis TheBloke
MODEL_REPO="TheBloke/Mixtral-8x7B-v0.1-GPTQ"
MODEL_REV="gptq-4bit-128g-actorder_True"
MODEL_DIR=/workspace/models/mixtral-4bit

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
    nginx \
    libprotobuf-dev \
    protobuf-compiler

# Répertoire temporaire sûr
export TMPDIR=/workspace/tmp
mkdir -p $TMPDIR

# 🔄 Installation des dépendances Python
pip uninstall -y torch numpy triton || true
pip install numpy==1.26.3 --no-cache-dir
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

# 📦 Dépendances PyPI classiques
pip install \
    transformers \
    fastapi \
    uvicorn \
    sentencepiece \
    safetensors \
    huggingface_hub \
    protobuf \
    optimum \
    --no-cache-dir

# 📦 Paquets CUDA/PyTorch spécifiques
pip install accelerate bitsandbytes --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

# 📁 Téléchargement conditionnel du modèle
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle Mixtral 4bit..."
    mkdir -p $MODEL_DIR
    python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$MODEL_REPO', revision='$MODEL_REV', local_dir='$MODEL_DIR', token='$HUGGINGFACE_HUB_TOKEN')"
else
    echo "✅ Modèle déjà présent dans $MODEL_DIR"
fi

# 🔄 Configuration de Nginx pour le reverse proxy
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

# 🚀 Lancement FastAPI
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# Nettoyage
rm -rf $TMPDIR

# 🔍 Vérification CUDA
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

# 🔗 Instructions CURL
IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Tu peux tester ton API avec :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
