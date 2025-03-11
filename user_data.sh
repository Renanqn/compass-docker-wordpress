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

# Exibe versão do Docker, Docker Compose e MySQL
docker --version
docker-compose --version
mysql --version

