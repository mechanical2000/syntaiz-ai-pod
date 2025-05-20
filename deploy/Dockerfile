FROM python:3.10-slim

# Installer paquets système
RUN apt update && apt install -y \
    nginx \
    curl \
    nano \
    git

# Créer le répertoire de travail
WORKDIR /workspace

# Exposer les ports (si besoin pour test direct)
EXPOSE 80

# Laisser le lancement au script setup_system.sh
CMD ["/bin/bash"]
