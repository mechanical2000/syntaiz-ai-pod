#!/bin/bash

set -e

# 🔐 Authentification Hugging Face pour modèles gated
export HUGGINGFACE_HUB_TOKEN=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

# 📁 Répertoire cache HF local pour éviter les erreurs de quota
export HF_HUB_CACHE=/workspace/tmp/hf-cache
mkdir -p $HF_HUB_CACHE

# 📦 Modèle Mixtral GPTQ depuis TheBloke
MODEL_REPO="TheBloke/Mixtral-8x7B-Instruct-v0.1-GPTQ"
MODEL_DIR=/workspace/models/mixtral

echo "🚀 Mise à jour du système"
apt update && apt install -y \
    python3-pip \
    git \
    curl \
    nano \
    nginx

# 👉 Utiliser des répertoires temporaires sûrs dans /workspace
export TMPDIR=/workspace/tmp
export PIP_CACHE_DIR=/workspace/pip-cache
mkdir -p $TMPDIR $PIP_CACHE_DIR

echo "📦 Installation de torch avec support CUDA 12.1"
pip install torch==2.1.0 --index-url https://download.pytorch.org/whl/cu121

echo "📦 Installation des dépendances Python"
pip uninstall -y torch numpy auto-gptq || true
pip install torch==2.0.1 --index-url https://download.pytorch.org/whl/cu118
pip install numpy==1.24.4
pip install auto-gptq==0.4.2
pip install transformers==4.33.2
pip uninstall -y triton || true

pip install --no-cache-dir --cache-dir=$PIP_CACHE_DIR \
    -r /workspace/syntaiz-ai-pod/setup/requirements.txt

# 📁 Téléchargement conditionnel du modèle Mixtral GPTQ
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle Mixtral quantifié depuis $MODEL_REPO dans $MODEL_DIR..."
    mkdir -p $MODEL_DIR
    python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$MODEL_REPO', local_dir='$MODEL_DIR', local_dir_use_symlinks=False, token='$HUGGINGFACE_HUB_TOKEN')"
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
rm -rf $TMPDIR $PIP_CACHE_DIR

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Tu peux tester ton API via le proxy Nginx :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE/generate \
     -H \"x-api-key: syntaiz-super-secret-key\" \
     -H \"Content-Type: application/json\" \
     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
