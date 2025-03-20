# 🚀 Deploy do WordPress com Docker na AWS

Este projeto implementa um ambiente completo para rodar o **WordPress** na **AWS**, utilizando **Docker, RDS MySQL e EFS**. O ambiente é **seguro e escalável**, garantindo que a instância EC2 **não tenha IP público**, utilizando **NAT Gateway** para acesso externo e um **Load Balancer** para gerenciar o tráfego.

📌 Arquitetura da Solução

✅ VPC com sub-redes públicas e privadas 

✅ EC2 privada rodando WordPress em Docker 

✅ Banco de Dados RDS MySQL

✅ EFS (Elastic File System) para armazenamento persistente

✅ Load Balancer (ALB) para distribuir tráfego

✅ NAT Gateway para acesso à internet sem IP público na EC2

✅ Auto Scaling para alta disponibilidade

✅ CloudWatch para monitoramento

✅ AMI personalizada para acelerar provisionamento 

---
## Diagrama do projeto
![Captura de tela 2025-03-09 211550](https://github.com/user-attachments/assets/ef6dfd05-2180-48d6-bb7d-3ef49e0c4418)

---

🛠 Pré-requisitos
- Conta AWS com permissões necessárias
- Chave SSH configurada
- Repositório Git para versionamento
- CLI da AWS instalada para execução manual

🚨 TABELA COM TODOS OS SECURITY GROUPS NECESSÁRIOS NO FINAL DO README 🚨

---

## 🚀 Passo a Passo da Instalação

1️⃣ Criar a VPC e Configurar a Rede
1. Criar VPC:
- Nome: WordPress-VPC
- CIDR: 10.0.0.0/16
2. Criar Sub-redes:
- Públicas: 10.0.100.0/24 (us-east-1a) e 10.0.101.0/24 (us-east-1b)
- Privadas: 10.0.200.0/24 (us-east-1a) e 10.0.201.0/24 (us-east-1b)
3. Criar e Associar:
- Internet Gateway à VPC
- NAT Gateway na Public-Subnet-1
4. Configurar Rotas:
- Tabela Pública: 0.0.0.0/0 → Internet Gateway
- Tabela Privada: 0.0.0.0/0 → NAT Gateway

🔹 2️⃣ Provisionar Banco de Dados RDS MySQL
1. Criar Instância RDS:
- Engine: MySQL 8.0
- Identificador: wordpress-db
- Usuário: admin
- Senha: SenhaSegura
2. Configurar Rede:
- VPC: WordPress-VPC
- Subnets Privadas: Private-Subnet-1 e Private-Subnet-2
- Acesso Público: Desativado
3. Configurar Security Group (SG-RDS)
- Permitir tráfego: Apenas da EC2 privada (porta 3306)    

### 🔹 3️⃣ Passos para Configuração do EFS

1. **Criar o Sistema de Arquivos EFS**  
   - Acesse o **AWS Console** → **EFS (Elastic File System)**.  
   - Clique em **Create File System**.  
   - **Nome:** `wordpress-efs`  
   - **VPC:** Selecione **MyVPC** (a mesma usada pela EC2).  

2. **Configurar o Acesso à Rede**  
   - Na etapa **Configure network access**:  
     - Selecione as **Private Subnets** (usadas pela EC2 privada).  
     - Escolha o **Security Group** ou crie um novo chamado **SG-EFS**.  
     - **Adicione uma regra Inbound** no SG-EFS permitindo tráfego **NFS (porta 2049)** **apenas** do **SG-EC2-Wordpress**.  

3. **Criar e Montar o EFS na EC2 Privada**  
   Após a criação, conecte-se à **EC2 privada** via **Bastion Host** e execute:  

   ```bash
   # Instalar o utilitário do EFS
   sudo yum install -y amazon-efs-utils

   # Criar um diretório para o EFS
   sudo mkdir -p /mnt/efs

   # Montar o EFS (substitua fs-XXXXXX pelo ID do EFS)
   sudo mount -t efs fs-XXXXXX:/ /mnt/efs

### 🔹 4️⃣ Criar o Bastion Host

O **Bastion Host** é uma instância EC2 pública usada para acessar **instâncias privadas** na VPC de forma segura, evitando a necessidade de atribuir IPs públicos às instâncias de produção.

####  **Passos para Configuração do Bastion Host:**

1. **Criar a Instância EC2 Pública**  
   - Acesse o **AWS Console** → **EC2 Dashboard** → **Launch Instance**.  
   - Escolha a **AMI**: `Amazon Linux 2` (ou outra de sua preferência).  
   - Selecione o **Instance Type**: `t2.micro` (elegível para Free Tier).  
   - Em **Network Settings**:  
     - **VPC:** Selecione `MyVPC`.  
     - **Subnet:** Escolha uma **Public Subnet** (ex.: `Public Subnet 1`).  
     - **Auto-assign Public IP:** **Enabled** (necessário para acesso externo).  

2. **Configurar o Security Group do Bastion**  
   - Crie um novo Security Group chamado **SG-Bastion** e adicione a seguinte regra:  
     - **Inbound:** Permitir **SSH (porta 22)** apenas do **seu IP** (`203.0.113.0/32`, substitua pelo seu IP real).  
   - **OBS:** Nunca permita SSH público (`0.0.0.0/0`) para evitar acessos indesejados.  

3. **Criar e Associar um Key Pair**  
   - Se ainda não tem um par de chaves SSH, crie um novo.  
   - Faça o download da chave **(.pem)** e mantenha-a segura.  

4. **Iniciar a Instância e Conectar-se ao Bastion Host**  
   - Após a instância iniciar, copie o **Public IP** e conecte-se via terminal:  
     ```bash
     ssh -i seu-keypair.pem ec2-user@<BASTION_PUBLIC_IP>
     ```

5. **Acessar a EC2 Privada via Bastion Host**  
   - No Bastion Host, conecte-se à **EC2 privada** utilizando seu **Private IP** (encontrado no EC2 Dashboard):  
     ```bash
     ssh -i seu-keypair.pem ec2-user@<EC2_PRIVATE_IP>
     ```
Para copiar a chave privada (.pem) para o Bastion Host e facilitar a conexão com a EC2 privada, use o seguinte comando no seu terminal local:
```
scp -i minha-key.pem minha-key.pem ubuntu@BASTION_IP:/home/ubuntu/
```
Depois, conecte-se ao Bastion Host e ajuste as permissões da chave:
```
ssh -i minha-key.pem ubuntu@BASTION_IP
chmod 400 minha-key.pem
```
Agora, use o Bastion para acessar a EC2 privada:
```
ssh -i minha-key.pem ubuntu@PRIVATE_IP
```
### 🔹 5️⃣ Criar a Instância EC2 Privada
1️⃣ Criar uma instância EC2

* Escolher uma AMI personalizada com tudo pré-configurado (ou uma base como Ubuntu 24.04).
* Tipo de instância: Escolher de acordo com a necessidade (exemplo: t3.micro).
* Subnet: Selecionar uma privada dentro da VPC configurada.
* IP Público: Desativado (acesso apenas via Bastion).
* Security Group: Criar um grupo permitindo:
   - Porta 80 (HTTP): Apenas do Load Balancer.
   - Porta 443 (HTTPS): Apenas do Load Balancer.
   - Porta 22 (SSH): Apenas do Bastion Host.
   - Porta 2049 (NFS): Apenas para o EFS.
   - Porta 3306 (MySQL): Apenas para a instância RDS.

2️. Adicionar o User Data (caso não use AMI personalizada)

No campo User Data, adicionar o script abaixo para configurar a instância automaticamente:
```
#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io git amazon-efs-utils
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
sudo mkdir -p /mnt/efs
sudo mount -t efs fs-XXXXXXXX:/ /mnt/efs
echo "fs-XXXXXXXX:/ /mnt/efs efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
cd /home/ubuntu
git clone https://github.com/SEU-USUARIO/aws-wordpress-docker.git
cd aws-wordpress-docker
sudo chmod +x setup.sh
sudo ./setup.sh
```
3️. Revisar e iniciar a instância

- Garantir que está na subnet privada correta.
- Associar ao Security Group adequado.
- Criar e associar um Key Pair para acesso via Bastion.
4️. Testar conexão
Acessar via Bastion Host:
```
ssh -i minha-key.pem ubuntu@PRIVATE_IP
```
### 🔹 7️⃣ Conectar-se à EC2 Privada e Verificar Instalação  

Após a inicialização da EC2 privada, conecte-se a ela via **Bastion Host** para garantir que tudo foi instalado corretamente.  

####  **Passos para Conexão e Verificação:**  

1. **Acesse o Bastion Host:**  
   - No terminal do seu computador local, conecte-se ao Bastion Host:  
     ```bash
     ssh -i meu-keypair.pem ec2-user@<BASTION_PUBLIC_IP>
     ```
   - **Substitua `<BASTION_PUBLIC_IP>` pelo IP público da sua instância Bastion Host.**  

2. **Conecte-se à EC2 Privada a partir do Bastion Host:**  
   - No terminal do Bastion Host, use o comando:  
     ```bash
     ssh -i meu-keypair.pem ec2-user@<EC2_PRIVATE_IP>
     ```
   - **Substitua `<EC2_PRIVATE_IP>` pelo IP privado da sua EC2 privada.**  

3. **Verificar instalação de pacotes essenciais
Executar os seguintes comandos na EC2 para garantir que tudo foi instalado corretamente:
   ```
   docker --version   # Verificar instalação do Docker
   docker-compose --version  # Verificar instalação do Docker Compose
   mysql --version  # Verificar cliente MySQL
   aws --version  # Verificar AWS CLI
   mount.efs --version  # Verificar utilitário do EFS
   ```
🔹 8️⃣ Configurar o Load Balancer (Classic Load Balancer - CLB)
O Classic Load Balancer (CLB) será responsável por distribuir o tráfego entre as instâncias EC2 privadas.

1️. Criar o Classic Load Balancer
   1. No AWS Console, vá até EC2 → Load Balancers → Create Load Balancer.
   2. Escolha Classic Load Balancer e clique em Create.
   3. Configuração Geral:
      - Nome: wordpress-clb
      -VPC: Selecione a mesma onde estão as EC2 privadas.
      - Subnets: Escolha as sub-redes públicas para que o CLB seja acessível pela internet.
2️. Configurar Listeners
   1. Adicionar regras de escuta:
      - Listener 1: HTTP (porta 80) → Encaminhar para HTTP (porta 80).
      - Listener 2 (Opcional): HTTPS (porta 443) → Encaminhar para HTTP (porta 80) (caso tenha certificado SSL).
3️. Criar e Associar um Security Group
   1. Criar um Security Group chamado SG-CLB.
   2. Adicionar as seguintes regras:
      * Entrada (Inbound):
         * HTTP (80): Acesso de 0.0.0.0/0 (qualquer lugar).
         * HTTPS (443) (Opcional): Acesso de 0.0.0.0/0 (caso utilize SSL).
      * Saída (Outbound): Permitir todo tráfego.
4️. Configurar Health Check
   1. Path: /healthcheck.php
   2. Protocolo: HTTP
   3. Porta: 80
   4. Tempo de Intervalo: 30s
   5. Timeout: 5s
   6. Falhas para considerar indisponível: 2
   7. Sucessos para considerar disponível: 2
5️. Registrar Instâncias no CLB
   1. Vá para Instances dentro da configuração do CLB.
   2. Selecione as instâncias do Auto Scaling e clique em Register Instances.
📌 Após a configuração, copie o DNS do Classic Load Balancer (wordpress-clb-xxxxxxx.elb.amazonaws.com) e utilize para acessar o WordPress! 🚀

### 🔹 9️⃣ Configurar o WordPress com Docker Compose
Agora, vamos configurar o WordPress dentro da EC2 privada usando Docker Compose.

 Passos para Configuração do WordPress:
1. Conectar-se à EC2 Privada via Bastion Host
```
ssh -i meu-keypair.pem ec2-user@<EC2_PRIVATE_IP>
```
2. Criar um diretório para o WordPress
```
mkdir -p /home/ec2-user/wordpress
cd /home/ec2-user/wordpress
```
3. Criar e configurar o arquivo docker-compose.yml
* No diretório ``/home/ec2-user/wordpress``, crie o arquivo:
```
nano docker-compose.yml
```
* Adicione o seguinte conteúdo (substitua <ENDPOINT_RDS> pelo endpoint do banco de dados RDS copiado na etapa 2):
```
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: <ENDPOINT_RDS>
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: <SUA SENHA>
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /mnt/efs:/var/www/html/wp-content/uploads
      - wp_data:/var/www/html
volumes:
  wp_data:
```
4. Subir os containers
```
docker-compose up -d
```
5. Verificar se os containers estão rodando corretamente
```
docker ps
```
### 🔹 🔟 Testar o WordPress

Agora que todos os componentes estão configurados, vamos testar o acesso ao WordPress para garantir que a implantação foi bem-sucedida.

#### 🏗 **Passos para Testar a Instalação do WordPress:**

1. **Copiar o DNS do Load Balancer**  
   - No **AWS Console**, vá para **EC2** → **Load Balancers**.  
   - Selecione `wordpress-alb` e copie o **DNS Name** (exemplo):  
     ```
     wordpress-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com
     ```

2. **Acessar o WordPress no navegador**  
   - No seu navegador, abra o seguinte link:  
     ```
     http://wordpress-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com
     ```
   - Se tudo estiver correto, você verá a **tela de configuração do WordPress**.

3. **Completar a Instalação do WordPress**  
   - Escolha o idioma e clique em **Continuar**.  
   - Preencha as informações do site:  
     - **Título do Site:** Defina um nome para o seu site.  
     - **Nome de Usuário:** Escolha um usuário administrador.  
     - **Senha:** Defina uma senha forte.  
     - **E-mail:** Insira um e-mail válido para recuperação de senha.  
   - Clique em **Instalar WordPress** e aguarde a conclusão.  

4. **Acessar o Painel Administrativo**  
   - Após a instalação, faça login acessando:  
     ```
     http://wordpress-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com/wp-admin
     ```
   - Utilize o **usuário e senha** cadastrados no passo anterior.  

5. **Verificar o Funcionamento**  
   - Se a página inicial do WordPress carregar corretamente, significa que a implantação foi **bem-sucedida**.  
   - Para testar upload de arquivos, vá até **Mídia** → **Adicionar Nova** e tente enviar uma imagem.  
   - Se o upload funcionar, significa que o **EFS está configurado corretamente** para armazenar os arquivos.  

## 🔒 **Configuração dos Security Groups**
---
🛠 Passos para Configurar o Auto Scaling
1️. Criar um Launch Template:

No EC2 Dashboard, vá para Launch Templates e crie um novo.
Selecione a AMI personalizada (com o ambiente pré-configurado).
Escolha o Instance Type adequado.
Configure o Security Group (SG-EC2) para permitir comunicação com ALB, EFS e RDS.
User Data vazio, pois a configuração já está na AMI.
2️. Criar o Auto Scaling Group:

No Auto Scaling Groups, crie um novo grupo e selecione o Launch Template criado.
Escolha as sub-redes privadas da VPC para as instâncias.
Defina os limites:
Mínimo: 1 instância
Desejado: 2 instâncias
Máximo: 4 instâncias
Associe o grupo ao Classic Load Balancer (CLB).
Configure regras de escalabilidade:
Aumentar se a CPU ultrapassar 60% por 5 minutos.
Diminuir se a CPU ficar abaixo de 30% por 5 minutos.
---
Passos para Configurar o CloudWatch
1️. Instalar e Configurar o CloudWatch Agent na EC2:
- Conectar-se à EC2 privada via Bastion Host.
- Instalar o CloudWatch Agent:
```
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
```
- Executar o assistente de configuração:
```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```
   - Escolher EC2 como ambiente.
   - Definir métricas básicas do sistema (CPU, memória, disco).
   - Adicionar logs do Apache (/var/log/apache2/access.log e /var/log/apache2/error.log).
   - Salvar a configuração.
- Iniciar o serviço:
```
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl enable amazon-cloudwatch-agent
```
2️. Criar Alarmes no CloudWatch:

- No AWS CloudWatch, vá para Alarms e crie novos alarmes:
   - Alerta de CPU Alta:
      - Métrica: Utilização de CPU da instância EC2
      - Condição: Acima de 70% por 5 minutos
      - Ação: Notificação via SNS (e-mail ou SMS)
   - Alerta de Baixa Memória:
      - Métrica: Uso de memória
      - Condição: Abaixo de 20% por 5 minutos
      - Ação: Notificação via SNS
---
| Nome          | Recurso         | Regras                                                       |
|--------------|----------------|-------------------------------------------------------------|
| **SG-EC2**   | EC2 WordPress   | - Porta **80** do Load Balancer                             |
|              |                 | - Porta **443** (HTTPS) do Load Balancer (opcional)        |
|              |                 | - Porta **3306** para acessar o RDS                        |
|              |                 | - Porta **2049** para acesso ao EFS                        |
|              |                 | - Porta **22** para acesso via Bastion Host                |
| **SG-RDS**   | RDS MySQL       | - Porta **3306** apenas para a EC2                         |
| **SG-EFS**   | EFS             | - Porta **2049** apenas para a EC2                         |
| **SG-CLB**   | Classic Load Balancer | - Porta **80/443** do mundo (0.0.0.0/0)             |
| **SG-Bastion** | Bastion Host  | - Porta **22** apenas do seu IP

## ✅ Conclusão

Com essa configuração, você tem um **WordPress rodando na AWS** de forma segura, escalável e bem organizada.  
A EC2 privada roda o Docker, o RDS armazena os dados e o EFS mantém os arquivos persistentes, enquanto o Load Balancer distribui o tráfego de forma eficiente.
