#!/bin/bash

# Display ASCII art banner in red
echo -e "\033[0;31m"
echo "  ____      _         _   _             _                 "  
echo " / ___|___ (_)_ __   | | | |_   _ _ __ | |_ ___ _ __ ___  "
echo "| |   / _ \| | '_ \  | |_| | | | | '_ \| __/ _ \ '__/ __| " 
echo "| |__| (_) | | | | | |  _  | |_| | | | | ||  __/ |  \__ \ "
echo " \____\___/|_|_| |_| |_| |_|\__,_|_| |_|\__\___|_|  |___/ "
echo -e "\e[0m"

# Update package list and install Docker and jq
echo -e "\033[0;32mPaket listesini güncelliyor ve Docker ile jq'yu yüklüyor...\033[0m"
sudo apt-get update
sudo apt-get install docker.io jq -y

# Install Docker Compose
echo -e "\033[0;32mDocker Compose'u yüklüyor...\033[0m"
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION

# Install Node.js and Yarn using NodeSource
echo -e "\033[0;32mNode.js ve Yarn'ı yüklüyor...\033[0m"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g yarn

# Clone the CAT Protocol repository
echo -e "\033[0;32mCAT Protocol deposunu klonluyor...\033[0m"
git clone https://github.com/CATProtocol/cat-token-box
cd cat-token-box

# Install dependencies and build the project
echo -e "\033[0;32mBağımlılıkları yüklüyor ve projeyi derliyor...\033[0m"
yarn install
yarn build

# Update the tracker URL in config.json
CONFIG_FILE="./packages/cli/config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "\033[0;32mconfig.json dosyasını güncelliyor...\033[0m"
    sed -i 's|"tracker": "http://127.0.0.1:3000"|"tracker": "http://162.55.47.20:3000"|' $CONFIG_FILE
else
    echo -e "\033[0;31mconfig.json dosyası bulunamadı. Lütfen dosyanın varlığını kontrol edin.\033[0m"
    exit 1
fi

# Set permissions and start Docker Compose
echo -e "\033[0;32mİzinleri ayarlıyor ve Docker Compose'u başlatıyor...\033[0m"
cd ./packages/tracker/
sudo chmod 777 docker/data
sudo chmod 777 docker/pgdata
docker-compose up -d

# Build and run the Docker container
echo -e "\033[0;32mDocker konteynerini oluşturuyor ve çalıştırıyor...\033[0m"
cd ../../
docker build -t tracker:latest .
docker run -d \
    --name tracker \
    --add-host="host.docker.internal:host-gateway" \
    -e DATABASE_HOST="host.docker.internal" \
    -e RPC_HOST="host.docker.internal" \
    -p 3000:3000 \
    tracker:latest

# Create a wallet
echo -e "\033[0;32mCüzdanınız oluşturuluyor. Gizli kelimelerinizi saklamayı unutmayın.\033[0m"
cd packages/cli
yarn build
yarn cli wallet create

# Display wallet address
echo -e "\033[0;32mCüzdan adresiniz. FB coin göndermeyi unutmayın.\033[0m"
yarn cli wallet address
