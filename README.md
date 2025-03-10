# 🚀 Deploy do WordPress com Docker na AWS

Este projeto implementa um ambiente completo para rodar o **WordPress** na **AWS**, utilizando **Docker, RDS MySQL e EFS**. O ambiente é **seguro e escalável**, garantindo que a instância EC2 **não tenha IP público**, utilizando **NAT Gateway** para acesso externo e um **Load Balancer** para gerenciar o tráfego.

## 📌 Arquitetura da Solução

✅ **VPC** com sub-redes públicas e privadas  
✅ **EC2 privada** rodando WordPress em Docker (sem IP público)  
✅ **Banco de Dados RDS MySQL** para armazenamento de dados  
✅ **EFS (Elastic File System)** para armazenamento persistente dos arquivos  
✅ **Load Balancer (ALB)** como ponto de entrada público  
✅ **NAT Gateway** para acesso da EC2 privada à internet  
✅ **Bastion Host** (opcional) para acesso seguro via SSH  
✅ **Security Groups** configurados para segurança de cada recurso  

---
## Diagrama do projeto
![Captura de tela 2025-03-09 211550](https://github.com/user-attachments/assets/ef6dfd05-2180-48d6-bb7d-3ef49e0c4418)

---

## 📂 Estrutura do Projeto
📦 aws-wordpress-docker 

┣ 📜 README.md # Documentação do projeto

┣ 📜 docker-compose.yml # Configuração do Docker para WordPress

┣ 📜 setup.sh # Script para configurar Docker na EC2

┗ 📜 .gitignore # Arquivos ignorados no repositório


---

## 🛠 Pré-requisitos

Antes de iniciar, certifique-se de ter:

- **Conta AWS** com permissões para criar instâncias EC2, RDS, EFS, Load Balancer, VPC, etc.
- **Chave SSH** configurada para acessar as instâncias.
- **GitHub** para armazenar e versionar os scripts de instalação.

🚨 TABELA COM TODOS OS SECURITY GROUPS NECESSÁRIOS NO FINAL DO README 🚨

---

## 🚀 Passo a Passo da Instalação

### 🔹 1️⃣ Criar a VPC e Configurar a Rede
## 🔹 Configuração da VPC e Sub-redes

1. Criar uma **VPC** com o seguinte bloco CIDR: `10.0.0.0/16`

2. Criar as **Sub-redes** conforme a tabela abaixo:

| Tipo        | Nome             | CIDR            | Zona de Disponibilidade |
|------------|----------------|----------------|------------------------|
| **Pública** | Public Subnet 1 | `10.0.100.0/24` | us-east-1a |
| **Pública** | Public Subnet 2 | `10.0.101.0/24` | us-east-1b |
| **Privada** | Private Subnet 1 | `10.0.200.0/24` | us-east-1a |
| **Privada** | Private Subnet 2 | `10.0.201.0/24` | us-east-1b |

3. Criar um **Internet Gateway** e associá-lo à VPC.  

4. Criar um **NAT Gateway** na **Public Subnet 1** para permitir que a EC2 privada acesse a internet.  

5. Configurar as **Tabelas de Rotas**:  
   - **Public Route Table** (associada às sub-redes públicas) deve rotear `0.0.0.0/0` para o **Internet Gateway**.  
   - **Private Route Table** (associada às sub-redes privadas) deve rotear `0.0.0.0/0` para o **NAT Gateway**.  

### 🔹 2️⃣ **Criar um Banco de Dados RDS MySQL**  
   - Acesse o **AWS Console** → **RDS** → **Databases** → **Create Database**.  
   - Escolha **Standard Create**.  
   - Em **Engine Options**, selecione **MySQL** e a versão **8.0**.  
   - Em **Templates**, escolha **Free Tier** (se aplicável) ou **Production**.  
   - **DB Instance Identifier:** `wordpress-db`  
   - **Master Username:** `admin`  
   - **Master Password:** Escolha uma senha segura e **anote para uso posterior**.  

2. **Configurar Rede e Acesso Seguro**  
   - Em **Connectivity**, selecione a **VPC criada anteriormente (MyVPC)**.  
   - Em **DB Subnet Group**, clique em **Create new DB Subnet Group** e inclua **as sub-redes privadas**:  
     - `Private Subnet 1 (us-east-1a)`  
     - `Private Subnet 2 (us-east-1b)`  
   - **Public Access:** **Disabled** (para garantir que o banco não seja acessível via internet).  
   - Em **VPC Security Group**, crie ou selecione um **Security Group exclusivo para o RDS** (**SG-RDS**).  
     - **Regras do Security Group:** Permitir tráfego **apenas da EC2 privada**, na **porta 3306 (MySQL)**.  

3. **Configurar Armazenamento e Performance**  
   - **Allocated Storage:** 20 GB (ou mais, conforme necessário).  
   - **Storage Auto Scaling:** Habilitar para ajuste automático do tamanho do armazenamento.  
   - **Multi-AZ Deployment:** Opcional (recomendado para alta disponibilidade).  

4. **Finalizar a Criação do Banco**  
   - Clique em **Create Database** e aguarde a conclusão do provisionamento (pode levar alguns minutos).  
   - Após a criação, vá para **RDS Dashboard** → **Databases**, selecione `wordpress-db` e **copie o Endpoint** (exemplo: `wordpress-db.xxxxxx.us-east-1.rds.amazonaws.com`).  
   - **Este Endpoint será usado na configuração do WordPress** no `docker-compose.yml`.  

### 🔹 3️⃣ Passos para Configuração do EFS:**

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

### 🔹 4️⃣ Criar o Bastion Host (Opcional)

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

### 🔹 5️⃣ Criar a EC2 Privada com Docker via GitHub

Nesta etapa, criaremos uma **instância EC2 privada**, configuraremos **Docker e Docker Compose** automaticamente por meio de um **script hospedado no GitHub**, e garantiremos que ela **não tenha IP público** para segurança.

####  **Passos para Configuração da EC2 Privada:**

1. **Criar a Instância EC2 Privada**  
   - Acesse o **AWS Console** → **EC2 Dashboard** → **Launch Instance**.  
   - Escolha a **AMI**: `Amazon Linux 2` (ou outra distribuição compatível).  
   - Selecione o **Instance Type**: `t2.micro` (Free Tier elegível).  

2. **Configurar Rede e Segurança**  
   - Em **Network Settings**:  
     - **VPC:** Selecione `MyVPC`.  
     - **Subnet:** Escolha uma **Private Subnet** (ex.: `Private Subnet 1`).  
     - **Auto-assign Public IP:** **Disabled** (para manter a EC2 privada).  
   - Em **Security Groups**, crie ou selecione **SG-EC2-Wordpress** com as seguintes regras:  
     - **Inbound:**  
       - **Porta 80 (HTTP):** Permitir **apenas do Load Balancer** (SG-LoadBalancer).  
       - **Porta 443 (HTTPS):** Opcional, permitir do Load Balancer caso use SSL.  
       - **Porta 22 (SSH):** Permitir **apenas do Bastion Host** para acesso seguro.  
     - **Outbound:** Permitir todo o tráfego **(padrão AWS)** para atualizações e instalação de pacotes.  

3. **Criar um Repositório GitHub para Automação**  
   - No GitHub, crie um novo repositório chamado **aws-ec2-docker-setup**.  
   - No repositório, crie um arquivo chamado `setup.sh` e adicione o seguinte conteúdo:  

   ```bash
   #!/bin/bash
   sudo yum update -y
   sudo yum install -y docker
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker ec2-user
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
### 🔹 6️⃣ Configurar Inicialização Automática via User Data

Para garantir que a EC2 **instale e configure automaticamente o Docker** ao iniciar, utilizaremos **User Data**. Esse recurso permite que comandos sejam executados automaticamente na primeira inicialização da instância.

####  **Passos para Configuração do User Data:**

1. **Durante a criação da EC2**, vá para a seção **Advanced Details**.  
2. **Localize o campo "User Data"** e insira o seguinte script:  

   ```bash
   #!/bin/bash
   # Atualiza os pacotes e instala o Git
   sudo yum update -y
   sudo yum install -y git

   # Navega para o diretório home do usuário
   cd /home/ec2-user

   # Clona o repositório do GitHub que contém o script de configuração
   git clone https://github.com/SEU-USUARIO/aws-ec2-docker-setup.git

   # Acessa o diretório do repositório clonado
   cd aws-ec2-docker-setup

   # Concede permissão de execução ao script
   sudo chmod +x setup.sh

   # Executa o script para instalar Docker e Docker Compose
   sudo ./setup.sh

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

3. **Verifique se Docker e Docker Compose foram instalados corretamente:**  
   ```bash
   docker --version
   docker-compose --version
### 🔹 8️⃣ Criar o Load Balancer
Agora, criaremos um Application Load Balancer (ALB) para distribuir o tráfego entre as instâncias EC2 de forma eficiente e segura.

 Passos para Configuração do Load Balancer:
1. **Criar um Application Load Balancer (ALB)**  
   - No **AWS Console**, acesse **EC2 Dashboard** → **Load Balancers** → **Create Load Balancer**.  
   - Escolha **Application Load Balancer**.  
   - Configure os detalhes:  
     - **Name:** `wordpress-alb`  
     - **Scheme:** **Internet-facing**  
     - **IP address type:** **IPv4**  
     - **VPC:** Selecione `MyVPC`  
     - **Availability Zones:** Selecione **Public Subnet 1** e **Public Subnet 2** 
2. **Configurar Listeners**  
   - **Listener HTTP (porta 80):** Redireciona para o Target Group.  
   - **Listener HTTPS (porta 443):** Opcional, caso utilize SSL/TLS.
3. **Criar um Target Group e associá-lo à EC2 privada**  
   - Na etapa **Configure Routing**, clique em **Create Target Group**.  
   - Configure:  
     - **Target type:** `Instances`  
     - **Protocol:** HTTP  
     - **Port:** 80  
     - **Health Check Path:** `/`  
   - Selecione a **EC2 privada** e registre-a no Target Group.
4. **Finalizar a Configuração e Criar o Load Balancer**  
   - Clique em **Review and Create**.  
   - Após a criação, copie o **DNS Name** do Load Balancer (exemplo):  

     ```
     wordpress-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com
     ```

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
      WORDPRESS_DB_PASSWORD: SenhaForte123!
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

| Nome         | Recurso        | Regras                                   |
|-------------|---------------|-----------------------------------------|
| **SG-EC2**  | EC2 WordPress  | Porta **80** do Load Balancer          |
| **SG-RDS**  | RDS MySQL      | Porta **3306** da EC2                  |
| **SG-EFS**  | EFS            | Porta **2049** da EC2                  |
| **SG-ALB**  | Load Balancer  | Porta **80/443** do mundo (0.0.0.0/0)  |
| **SG-Bastion** | Bastion Host | Porta **22** apenas do seu IP          |

## ✅ Conclusão

Com essa configuração, você tem um **WordPress rodando na AWS** de forma segura, escalável e bem organizada.  
A EC2 privada roda o Docker, o RDS armazena os dados e o EFS mantém os arquivos persistentes, enquanto o Load Balancer distribui o tráfego de forma eficiente.
