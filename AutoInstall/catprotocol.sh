#!/bin/bash

# Display ASCII art banner in red
echo -e "\033[0;31m"
echo "  ____      _         _   _             _                 "  
echo " / ___|___ (_)_ __   | | | |_   _ _ __ | |_ ___ _ __ ___  "
echo "| |   / _ \| | '_ \  | |_| | | | | '_ \| __/ _ \ '__/ __| " 
echo "| |__| (_) | | | | | |  _  | |_| | | | | ||  __/ |  \__ \ "
echo " \____\___/|_|_| |_| |_| |_|\__,_|_| |_|\__\___|_|  |___/ "
echo -e "\e[0m"

# Update package list and install Docker
echo "Paket listesini güncelliyor ve Docker'ı yüklüyor..."
sudo apt-get update
sudo apt-get install docker.io -y

# Install Docker Compose
echo "Docker Compose'u yüklüyor..."
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION

# Install Node.js and Yarn
echo "Node.js ve Yarn'ı yüklüyor..."
sudo apt-get install npm -y
sudo npm install n -g
sudo n stable
sudo npm i -g yarn

# Clone the CAT Protocol repository
echo "CAT Protocol deposunu klonluyor..."
git clone https://github.com/CATProtocol/cat-token-box
cd cat-token-box

# Install dependencies and build the project
echo "Bağımlılıkları yüklüyor ve projeyi derliyor..."
sudo yarn install
sudo yarn build

# Set permissions and start Docker Compose
echo "İzinleri ayarlıyor ve Docker Compose'u başlatıyor..."
cd ./packages/tracker/
sudo chmod 777 docker/data
sudo chmod 777 docker/pgdata
sudo docker-compose up -d

# Build and run the Docker container
echo "Docker konteynerini oluşturuyor ve çalıştırıyor..."
cd ../../
sudo docker build -t tracker:latest .
sudo docker run -d \
    --name tracker \
    --add-host="host.docker.internal:host-gateway" \
    -e DATABASE_HOST="host.docker.internal" \
    -e RPC_HOST="host.docker.internal" \
    -p 3000:3000 \
    tracker:latest

# Create a wallet
echo "Cüzdanınız oluşturuluyor. Gizli kelimelerinizi saklamayı unutmayın."
cd packages/cli
sudo yarn cli wallet create

# Display wallet address
echo "Cüzdan adresiniz. FB coin göndermeyi unutmayın."
yarn cli wallet address
