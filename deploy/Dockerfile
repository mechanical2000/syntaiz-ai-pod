FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
# Installer Python et les outils de base
RUN apt update && apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    curl \
    nano \
    git

# Lier 'python' à 'python3' pour compatibilité
RUN ln -s /usr/bin/python3 /usr/bin/python

# Définir le répertoire de travail (volume RunPod)
WORKDIR /workspace

# Exposer uniquement les ports HTTP (FastAPI reste interne)
EXPOSE 80
EXPOSE 443

# Laisser l'utilisateur cloner le projet et lancer setup
CMD ["sleep", "infinity"]
