#!/bin/bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logo çekme ve gösterme
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)
printLogo

# Fonksiyon: Komut çalıştırma ve hata kontrolü
run_command() {
  echo -e "${YELLOW}► \$1${NC}"
  eval "\$2"
  if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Hata: \$1 başarısız oldu${NC}"
      exit 1
  fi
}

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}❌ Bu script root yetkisi gerektiriyor.${NC}"
  echo "Lütfen 'sudo bash glacier_setup.sh' şeklinde çalıştırın."
  exit 1
fi

# Private Key'i al
echo -e "${YELLOW}Lütfen Metamask Private Key'inizi girin (girdiğiniz karakterler gizli kalacaktır):${NC}"
read -s PRIVATE_KEY
echo

if [ -z "$PRIVATE_KEY" ]; then
  echo -e "${RED}❌ Private Key boş olamaz!${NC}"
  exit 1
fi

# 1. Sistem Güncellemesi
echo -e "\n${GREEN}1. Sistem güncelleniyor...${NC}"
run_command "Sistem güncelleniyor" "apt update && apt upgrade -y"

# 2. Gerekli Paketlerin Kurulumu
echo -e "\n${GREEN}2. Gerekli paketler kuruluyor...${NC}"
run_command "Gerekli paketler kuruluyor" "apt install -y htop ca-certificates curl gnupg lsb-release git wget make jq build-essential pkg-config ncdu tar unzip"

# 3. Docker Kurulumu
echo -e "\n${GREEN}3. Docker kuruluyor...${NC}"
run_command "Docker GPG anahtarı ekleniyor" "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
run_command "Docker repository ekleniyor" 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null'
run_command "Paket listesi güncelleniyor" "apt update"
run_command "Docker kuruluyor" "apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"

# 4. Docker Compose Kurulumu
echo -e "\n${GREEN}4. Docker Compose kuruluyor...${NC}"
run_command "Docker Compose indiriliyor" "curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose"
run_command "Docker Compose'a çalıştırma izni veriliyor" "chmod +x /usr/local/bin/docker-compose"

# 5. Docker Kullanıcı İzinleri
echo -e "\n${GREEN}5. Docker kullanıcı izinleri ayarlanıyor...${NC}"
run_command "Docker grubu oluşturuluyor" "groupadd -f docker"
run_command "Kullanıcı Docker grubuna ekleniyor" "usermod -aG docker $SUDO_USER"

# 6. Glacier Node Başlatma
echo -e "\n${GREEN}6. Glacier node başlatılıyor...${NC}"
run_command "Eski container kaldırılıyor (varsa)" "docker rm -f glacier-verifier 2>/dev/null || true"
run_command "Glacier node başlatılıyor" "docker run -d -e PRIVATE_KEY=${PRIVATE_KEY} --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.2"

# Kurulum Tamamlandı
echo -e "\n${GREEN}✅ Kurulum başarıyla tamamlandı!${NC}"
echo -e "\n${YELLOW}Önemli Komutlar:${NC}"
echo -e "► Node loglarını görüntülemek için:"
echo -e "${GREEN}docker logs -f glacier-verifier -n 150${NC}"
echo -e "\n► Node durumunu kontrol etmek için:"
echo -e "${GREEN}docker ps | grep glacier-verifier${NC}"
echo -e "\n► Node'u yeniden başlatmak için:"
echo -e "${GREEN}docker restart glacier-verifier${NC}"
echo -e "\n► Web üzerinden node durumu:"
echo -e "${GREEN}https://testnet.nodes.glacier.io/status${NC}"

# Sistem yeniden başlatma önerisi
echo -e "\n${YELLOW}Not: Değişikliklerin tam olarak uygulanması için sistemi yeniden başlatmanız önerilir.${NC}"
echo -e "Yeniden başlatmak için: ${GREEN}sudo reboot${NC}"
