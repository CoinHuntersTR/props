#!/bin/bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logo çekme ve gösterme
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)
printLogo

echo -e "${YELLOW}Lütfen Metamask Private Key'inizi girin:${NC}"
read PRIVATE_KEY
echo -e "${GREEN}Girilen Private Key: $PRIVATE_KEY${NC}"

echo -e "\n${GREEN}1. Sistem güncelleniyor...${NC}"
sudo apt update
sudo apt upgrade -y

echo -e "\n${GREEN}2. Docker kurulumu yapılıyor...${NC}"
sudo apt install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo -e "\n${GREEN}3. Glacier Node başlatılıyor...${NC}"
sudo docker run -d -e PRIVATE_KEY=${PRIVATE_KEY} --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.2

echo -e "\n${GREEN}✅ Kurulum tamamlandı!${NC}"
echo -e "\n${YELLOW}Node loglarını kontrol etmek için:${NC}"
echo -e "${GREEN}docker logs -f glacier-verifier${NC}"
