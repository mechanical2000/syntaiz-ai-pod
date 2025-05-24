FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# Installer Python 3.10 et les outils de base
RUN apt update && apt install -y \
    software-properties-common \
    build-essential \
    cmake \
    ninja-build \
    wget \
    curl \
    nano \
    git \
    nginx \
    ca-certificates && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt update && apt install -y \
    python3.10 \
    python3.10-venv \
    python3.10-distutils

# Mettre à jour les liens symboliques pour utiliser Python 3.10
RUN ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && rm get-pip.py

# Définir le répertoire de travail (volume RunPod)
WORKDIR /workspace

# Exposer les ports nécessaires
EXPOSE 80
EXPOSE 443

# Laisser l'utilisateur cloner le projet et lancer setup
CMD ["sleep", "infinity"]
