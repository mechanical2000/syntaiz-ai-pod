#!/bin/bash

set -e

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
pip install --no-cache-dir --cache-dir=$PIP_CACHE_DIR \
    -r /workspace/syntaiz-ai-pod/setup/requirements.txt

# 📁 Téléchargement conditionnel du modèle Mixtral
MODEL_DIR=/workspace/models/mixtral
if [ ! -d "$MODEL_DIR" ]; then
    echo "📥 Téléchargement du modèle Mixtral dans $MODEL_DIR..."
    mkdir -p $MODEL_DIR
    python3 -c "import os; from huggingface_hub import snapshot_download; snapshot_download(repo_id='mistralai/Mixtral-8x7B-Instruct-v0.1', local_dir='$MODEL_DIR', local_dir_use_symlinks=False, token=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)"
else
    echo "✅ Modèle Mixtral déjà présent dans $MODEL_DIR"
fi

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
echo "🌐 Tu peux tester ton API via TCP avec clé API avec :"
echo ""
echo "curl -X POST http://$IP_PUBLIQUE:5001/generate \
     -H \"x-api-key: syntaiz-super-secret-key\" \
     -H \"Content-Type: application/json\" \
     -d '{\"prompt\": \"Explique le mot synonyme\"}'"
echo ""
