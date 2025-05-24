#!/bin/bash

set -e

export HUGGINGFACE_HUB_TOKEN=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

# 📁 Répertoire cache HF local pour éviter les erreurs de quota
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📦 Modèle Mixtral GPTQ depuis TheBloke
MODEL_REPO="TheBloke/Mixtral-8x7B-Instruct-v0.1-GPTQ"
MODEL_DIR=/workspace/models/mixtral

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

# 👉 Utiliser des répertoires temporaires sûrs dans /workspace
export TMPDIR=/workspace/tmp
mkdir -p $TMPDIR

# 🔄 Installation des dépendances principales
pip uninstall -y torch numpy auto-gptq triton || true
pip install numpy==1.24.4 --no-cache-dir
pip install torch==2.0.1 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir

# ⚙️ Compilation CUDA : auto-gptq complet
git clone --branch v0.4.2 https://github.com/PanQiWei/AutoGPTQ.git /workspace/auto-gptq
cd /workspace/auto-gptq
pip install . --no-cache-dir
cd -

# 📦 Paquets PyPI classiques
pip install \
    transformers \
    fastapi \
    uvicorn \
    sentencepiece \
    safetensors \
    huggingface_hub \
    --no-cache-dir

# 📦 Paquets CUDA/PyTorch (depuis index cu118)
pip install \
    accelerate \
    bitsandbytes \
    --index-url https://download.pytorch.org/whl/cu118 \
    --no-cache-dir

# 📁 Téléchargement conditionnel du modèle Mixtral GPTQ
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle Mixtral quantifié depuis $MODEL_REPO dans $MODEL_DIR..."
    mkdir -p $MODEL_DIR
    python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$MODEL_REPO', local_dir='$MODEL_DIR', local_dir_use_symlinks=False, token=os.getenv('HUGGINGFACE_HUB_TOKEN'))"
else
    echo "✅ Modèle Mixtral déjà présent dans $MODEL_DIR"
fi

# 🔄 Configuration de Nginx pour reverse proxy vers Uvicorn
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

echo "🚀 Lancement de l'app FastAPI (Uvicorn) en arrière-plan"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

# 🔚 Nettoyage temporaire
echo "🧹 Nettoyage des fichiers temporaires"
rm -rf $TMPDIR

# 🧪 Validation GPU
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
