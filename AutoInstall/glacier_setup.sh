#!/bin/bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
# Logo
curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh | bash

# Private Key alma
echo -e "${YELLOW}Lütfen Metamask Private Key'inizi girin:${NC}"
read PRIVATE_KEY
echo -e "${GREEN}Girilen Private Key: $PRIVATE_KEY${NC}"

# Sistem güncelleme
echo -e "\n${GREEN}Sistem güncelleniyor...${NC}"
apt update
apt upgrade -y

# Docker kurulumu
echo -e "\n${GREEN}Docker kuruluyor...${NC}"
apt install ca-certificates curl gnupg -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Glacier node başlatma
echo -e "\n${GREEN}Glacier Node başlatılıyor...${NC}"
docker run -d -e PRIVATE_KEY=${PRIVATE_KEY} --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.2

# Tamamlandı
echo -e "\n${GREEN}✅ Kurulum tamamlandı!${NC}"
echo -e "\n${YELLOW}Node loglarını kontrol etmek için:${NC}"
echo -e "${GREEN}docker logs -f glacier-verifier${NC}"
