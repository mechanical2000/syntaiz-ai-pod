#!/bin/bash

set -e
export HUGGINGFACE_HUB_TOKEN=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
export HF_HUB_CACHE=/workspace/tmp/hf-cache
export TMPDIR=/workspace/tmp
mkdir -p $HF_HUB_CACHE $TMPDIR

echo "🚀 Mise à jour du système..."
apt update && apt install -y \
    build-essential cmake ninja-build \
    python3-pip python3.10-dev \
    git curl nano nginx

echo "🚧 Nettoyage des installations précédentes..."
pip uninstall -y torch numpy bitsandbytes || true

echo "📦 Installation de Torch avec CUDA 11.8..."
pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir
pip install numpy --no-cache-dir

echo "📦 Installation des dépendances Python..."
pip install \
    transformers \
    accelerate \
    sentencepiece \
    safetensors \
    huggingface_hub \
    fastapi uvicorn \
    --no-cache-dir

echo "🛠️ Compilation de bitsandbytes avec support CUDA 11.8..."

cd /workspace
rm -rf bitsandbytes
git clone https://github.com/TimDettmers/bitsandbytes.git
cd bitsandbytes

# Force la variable d’environnement CUDA
export CUDA_VERSION=118

# Supprimer les builds précédents au cas où
rm -rf build/ dist/ bitsandbytes.egg-info/

# Compilation manuelle
CUDA_VERSION=118 python3 setup.py install

cd -

echo "🔧 Configuration de Nginx pour reverse proxy..."
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

echo "🔁 Redémarrage de Nginx"
nginx -t && (nginx -s stop 2>/dev/null || true) && nginx

echo "🚀 Lancement de l'API FastAPI"
cd /workspace/syntaiz-ai-pod/app
nohup uvicorn main:app --host 0.0.0.0 --port 5001 > /workspace/app.log 2>&1 &

echo "🧪 Validation GPU"
python3 -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0))"

IP_PUBLIQUE=$(curl -s ifconfig.me)
echo ""
echo "✅ Déploiement terminé !"
echo "🌐 Exemple de requête :"
echo "curl -X POST http://$IP_PUBLIQUE/generate -H 'x-api-key: syntaiz-super-secret-key' -H 'Content-Type: application/json' -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""