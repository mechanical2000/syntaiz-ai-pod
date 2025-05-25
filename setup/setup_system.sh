#!/bin/bash

set -e

# 🔐 Token Hugging Face (nécessaire si le modèle est gated)
export HUGGINGFACE_HUB_TOKEN=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

# 📁 Répertoire de cache Hugging Face
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📦 Modèle Mixtral officiel (non quantifié)
MODEL_REPO="mistralai/Mixtral-8x7B-Instruct-v0.1"
MODEL_DIR="/workspace/models/mixtral"

# 🧱 Mise à jour système et dépendances
apt update && apt install -y \
    build-essential \
    cmake \
    python3-pip \
    python3.10-dev \
    git \
    curl \
    nano \
    nginx \
    libprotobuf-dev \
    protobuf-compiler \
    libgoogle-perftools-dev

# 🔁 Dossier temporaire
export TMPDIR=/workspace/tmp
mkdir -p $TMPDIR

# 🔄 Nettoyage d’éventuelles anciennes installations
pip uninstall -y torch numpy triton bitsandbytes || true

# 🧠 Torch + CUDA 11.8
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

# 📦 Paquets principaux
pip install \
    numpy==1.24.4 \
    transformers \
    bitsandbytes \
    accelerate \
    sentencepiece \
    safetensors \
    huggingface_hub \
    fastapi \
    uvicorn \
    protobuf \
    --no-cache-dir

# 📥 Téléchargement conditionnel du modèle
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle Mixtral depuis $MODEL_REPO"
    python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$MODEL_REPO', local_dir='$MODEL_DIR', local_dir_use_symlinks=False, token='$HUGGINGFACE_HUB_TOKEN')"
else
    echo "✅ Modèle déjà présent dans $MODEL_DIR"
fi

# 🌐 Nginx (reverse proxy)
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

# 🚀 Lancement de l’API
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# 🧪 GPU
echo "🔍 Test CUDA"
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| GPU:', torch.cuda.get_device_name(0))"

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo "🌐 API dispo via Nginx :"
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
