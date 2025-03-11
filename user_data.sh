#!/bin/bash
# Atualiza pacotes
sudo apt update -y

# Instala Docker
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Instala o cliente MySQL
sudo apt install -y mysql-client-core-8.0

# Instala o utilitário do EFS
sudo apt install -y amazon-efs-utils

# Cria o diretório para montagem do EFS
sudo mkdir -p /mnt/efs

# Monta o EFS utilizando o ID informado (fs-06ccafd3a3bb1cdbc)
sudo mount -t efs fs-06ccafd3a3bb1cdbc:/ /mnt/efs

# Adiciona o EFS ao fstab para montagem automática na reinicialização
echo "fs-06ccafd3a3bb1cdbc:/ /mnt/efs efs defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Exibe as versões instaladas (Docker, Docker Compose e MySQL Client)
docker --version
docker-compose --version
mysql --version

