#!/bin/bash
set -ex  # Habilita modo debug para mostrar os comandos e parar caso algum falhe

# Atualização do sistema e instalação de pacotes essenciais
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y docker.io git unzip curl awscli binutils make gcc cmake pkg-config libssl-dev amazon-efs-utils

# Iniciar e habilitar o Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Instalar Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configuração do EFS
EFS_ID="fs-XXXXXXXX"  # Substitua pelo ID correto do seu EFS!
MOUNT_POINT="/mnt/efs"

sudo mkdir -p ${MOUNT_POINT}
echo "${EFS_ID}:/ ${MOUNT_POINT} efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Clonar repositório do projeto e iniciar o WordPress
cd /home/ubuntu
git clone https://github.com/SEU-USUARIO/aws-wordpress-docker.git
cd aws-wordpress-docker
sudo docker-compose up -d

# Instalar e configurar CloudWatch Agent
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Criar configuração do CloudWatch Agent
cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/apache2/access.log",
                        "log_group_name": "apache-access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/apache2/error.log",
                        "log_group_name": "apache-error",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Iniciar e habilitar o CloudWatch Agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl enable amazon-cloudwatch-agent
