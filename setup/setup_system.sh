#!/bin/bash
set -e

export HUGGINGFACE_HUB_TOKEN=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

# 📁 Répertoire cache HF
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📦 Repo du modèle quantifié (compatible bitsandbytes)
MODEL_REPO="mistralai/Mixtral-8x7B-Instruct-v0.1"
MODEL_DIR="/workspace/models/mixtral"

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

# 🔄 Dépendances Python
pip uninstall -y torch numpy triton || true
pip install numpy==1.24.4 --no-cache-dir
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir
pip install \
    transformers \
    accelerate \
    bitsandbytes \
    sentencepiece \
    fastapi \
    uvicorn \
    safetensors \
    protobuf \
    huggingface_hub \
    --no-cache-dir

# 📥 Téléchargement conditionnel du modèle
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle depuis $MODEL_REPO..."
    mkdir -p $MODEL_DIR
    python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$MODEL_REPO', local_dir='$MODEL_DIR', token='$HUGGINGFACE_HUB_TOKEN')"
else
    echo "✅ Modèle déjà présent dans $MODEL_DIR"
fi

# 🔧 Configuration Nginx
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

echo "🚀 Lancement de FastAPI (Uvicorn) en fond"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# 🧪 Vérification GPU
echo "🔍 Test GPU"
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Test API :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
