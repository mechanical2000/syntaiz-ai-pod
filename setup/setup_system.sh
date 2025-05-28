#!/bin/bash
set -e

# 🔐 Jeton Hugging Face
export HUGGINGFACE_HUB_TOKEN=hf_hf_oWokkszjNWtbGFZEJEgdupPWzZAudbhNml  # ← Remplace ici

# 📁 Dossiers & modèle
MODEL_REPO="TheBloke/Mixtral-8x7B-Instruct-v0.1-GPTQ"
MODEL_REV="gptq-4bit-128g-actorder_True"
MODEL_DIR=/workspace/models/mixtral

# 📁 Cache Hugging Face
export HF_HUB_CACHE=/workspace/tmp/hf-cache
export TMPDIR=/workspace/tmp
mkdir -p $HF_HUB_CACHE $TMPDIR $MODEL_DIR

echo "🚀 Mise à jour du système"
apt update && apt install -y \
    build-essential cmake ninja-build \
    python3-pip python3.10-dev \
    git curl nano nginx

echo "📦 Installation de torch (CUDA 11.8)"
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

echo "📦 Installation des dépendances Python"
pip install \
    numpy \
    transformers \
    accelerate \
    bitsandbytes \
    sentencepiece \
    safetensors \
    huggingface_hub \
    fastapi \
    uvicorn \
    --no-cache-dir

# 📥 Téléchargement du modèle quantifié (4bit)
if [ ! -f "$MODEL_DIR/config.json" ]; then
    echo "📥 Téléchargement du modèle depuis $MODEL_REPO@$MODEL_REV"
    python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='$MODEL_REPO',
    local_dir='$MODEL_DIR',
    revision='$MODEL_REV',
    local_dir_use_symlinks=False,
    token='$HUGGINGFACE_HUB_TOKEN'
)"
else
    echo "✅ Modèle déjà présent dans $MODEL_DIR"
fi

# 🔄 Configuration de Nginx pour proxy Uvicorn
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

# 🚀 Lancement de l'API FastAPI
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# 🧹 Nettoyage
echo "🧹 Nettoyage des fichiers temporaires"
rm -rf $TMPDIR

# 🧪 Test GPU
echo "🔍 Test GPU"
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Pour tester l’API :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \\"
echo "     -H \"x-api-key: syntaiz-super-secret-key\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""