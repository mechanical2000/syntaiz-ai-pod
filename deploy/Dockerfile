FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV BNB_CUDA_VERSION=118 

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
    python3.10-dev \
    python3.10-venv \
    python3.10-distutils

# Mettre à jour les liens symboliques pour utiliser Python 3.10
RUN ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && rm get-pip.py

# Installer torch et ses dépendances avant bitsandbytes
RUN pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cu118 \
    numpy==1.26.3

# Cloner et compiler bitsandbytes manuellement
RUN git clone --depth=1 https://github.com/TimDettmers/bitsandbytes.git /workspace/bitsandbytes && \
    cd /workspace/bitsandbytes && \
    python setup.py install

# Répertoire de travail
WORKDIR /workspace

# Laisser l'utilisateur lancer setup_config.sh
CMD ["sleep", "infinity"]
