#!/bin/bash
set -e

export HUGGINGFACE_HUB_TOKEN=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

# 📁 Cache local HF
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📁 Répertoire du modèle
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
    nginx

# ✅ Dossier temporaire
export TMPDIR=/workspace/tmp
mkdir -p $TMPDIR

# 🔄 Installation des libs principales
pip install -U pip setuptools wheel --no-cache-dir
pip install numpy==1.24.4 torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

# 📦 Paquets principaux
pip install \
    transformers \
    accelerate \
    bitsandbytes \
    sentencepiece \
    safetensors \
    huggingface_hub \
    fastapi \
    uvicorn \
    --no-cache-dir

# 📥 Téléchargement conditionnel du modèle quantifié
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle Mixtral GPTQ 4bit..."
    mkdir -p $MODEL_DIR
    python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='$MODEL_REPO',
    revision='$MODEL_REV',
    local_dir='$MODEL_DIR',
    local_dir_use_symlinks=False,
    token='$HUGGINGFACE_HUB_TOKEN'
)"
else
    echo "✅ Modèle déjà présent : $MODEL_DIR"
fi

# 🔄 Configuration Nginx
NGINX_CONF="/etc/nginx/sites-available/default"
cp "$NGINX_CONF" "${NGINX_CONF}.backup"

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

echo "🔄 Redémarrage de Nginx"
nginx -t && (nginx -s stop 2>/dev/null || true) && nginx

# 🚀 Lancement Uvicorn
echo "🚀 Lancement de l'app FastAPI"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# 🧪 Vérification CUDA
echo "🔍 Test GPU"
python3 -c "import torch; print('CUDA dispo:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

# ℹ️ IP publique + test
IP=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Test de l'API via :"
echo "curl -X POST http://$IP/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
