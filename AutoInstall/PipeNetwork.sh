#!/bin/bash

# Logo scripti
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonksiyon: Hata kontrolü
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Hata: \$1${NC}"
        exit 1
    fi
}

# Fonksiyon: Kullanıcı onayı
wait_for_confirmation() {
    while true; do
        read -p "\$1 (evet/hayır): " yn
        case $yn in
            [Ee]* ) return 0;;
            [Hh]* ) return 1;;
            * ) echo "Lütfen 'evet' veya 'hayır' yazın.";;
        esac
    done
}

clear
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Pipe Network Kurulum Scripti       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
# Sistem güncellemesi
echo -e "\n${YELLOW}[1/11]${NC} Sistem güncelleniyor..."
sudo apt update -y && sudo apt upgrade -y
check_error "Sistem güncellemesi başarısız"

# Port açma
echo -e "\n${YELLOW}[2/11]${NC} Gerekli portlar açılıyor..."
sudo ufw allow 8002/tcp
sudo ufw allow 8003/tcp
check_error "Port açma işlemi başarısız"

# Kullanıcıdan mail linklerini alma
echo -e "\n${YELLOW}[3/11]${NC} Mail bilgileri giriliyor..."
echo -e "${GREEN}Lütfen mail ile gelen linkleri giriniz:${NC}"
read -p "PIPE linki: " PIPE
read -p "DCDND linki: " DCDND

# Dizin oluşturma
echo -e "\n${YELLOW}[4/11]${NC} Dizinler oluşturuluyor..."
sudo mkdir -p $HOME/opt/dcdn
check_error "Dizin oluşturma başarısız"

# Dosyaları indirme
echo -e "\n${YELLOW}[5/11]${NC} Gerekli dosyalar indiriliyor..."
sudo wget -O $HOME/opt/dcdn/pipe-tool "$PIPE"
check_error "pipe-tool indirme başarısız"
sudo wget -O $HOME/opt/dcdn/dcdnd "$DCDND"
check_error "dcdnd indirme başarısız"

# İzinleri ayarlama
echo -e "\n${YELLOW}[6/11]${NC} İzinler ayarlanıyor..."
sudo chmod +x $HOME/opt/dcdn/pipe-tool
sudo chmod +x $HOME/opt/dcdn/dcdnd
sudo ln -s $HOME/opt/dcdn/pipe-tool /usr/local/bin/pipe-tool -f
sudo ln -s $HOME/opt/dcdn/dcdnd /usr/local/bin/dcdnd -f
check_error "İzin ayarlama başarısız"

# Service dosyası oluşturma
echo -e "\n${YELLOW}[7/11]${NC} Service dosyası oluşturuluyor..."
sudo cat > /etc/systemd/system/dcdnd.service << 'EOF'
[Unit]
Description=DCDN Node Service
After=network.target
Wants=network-online.target

[Service]
ExecStart=/opt/dcdn/dcdnd \
                --grpc-server-url=0.0.0.0:8002 \
                --http-server-url=0.0.0.0:8003 \
                --node-registry-url="https://rpc.pipedev.network" \
                --cache-max-capacity-mb=1024 \
                --credentials-dir=/root/.permissionless \
                --allow-origin=*
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=/opt/dcdn

[Install]
WantedBy=multi-user.target
EOF
check_error "Service dosyası oluşturma başarısız"

# Login işlemi
echo -e "\n${YELLOW}[8/11]${NC} Login işlemi başlatılıyor..."
echo -e "${YELLOW}ÖNEMLİ ADIMLAR:${NC}"
echo -e "1. Aşağıda bir QR kod ve 6 haneli kod gösterilecek"
echo -e "2. Gösterilen web sitesini tarayıcınızda açın"
echo -e "3. 6 haneli kodu girin"
echo -e "4. Mail adresinizle giriş yapın"
echo -e "5. Register işlemini tamamlayın\n"
echo -e "${GREEN}Hazır olduğunuzda devam etmek için enter'a basın...${NC}"
read

pipe-tool login --node-registry-url="https://rpc.pipedev.network"
check_error "Login işlemi başarısız"

if ! wait_for_confirmation "Register işlemini tamamladınız mı?"; then
    echo -e "${RED}İşlem kullanıcı tarafından iptal edildi${NC}"
    exit 1
fi

# Registration token oluşturma
echo -e "\n${YELLOW}[9/11]${NC} Registration token oluşturuluyor..."
pipe-tool generate-registration-token --node-registry-url="https://rpc.pipedev.network"
check_error "Token oluşturma başarısız"

if ! wait_for_confirmation "Registration token oluşturuldu mu?"; then
    echo -e "${RED}İşlem kullanıcı tarafından iptal edildi${NC}"
    exit 1
fi

# Servisi başlatma
echo -e "\n${YELLOW}[10/11]${NC} Servis başlatılıyor..."
sudo systemctl daemon-reload
sudo systemctl enable dcdnd
sudo systemctl restart dcdnd
check_error "Servis başlatma başarısız"

# Cüzdan oluşturma
echo -e "\n${YELLOW}[11/11]${NC} Cüzdan oluşturuluyor..."
echo -e "${YELLOW}NOT: Şifre oluşturmak opsiyoneldir, boş bırakabilirsiniz${NC}"
pipe-tool generate-wallet --node-registry-url="https://rpc.pipedev.network" --key-path=$HOME/.permissionless/key.json
check_error "Cüzdan oluşturma başarısız"

# Cüzdan bilgilerini gösterme
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Cüzdan Bilgileriniz           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}Private Key:${NC}"
pipe-tool show-private-key --key-path=$HOME/.permissionless/key.json

echo -e "\n${YELLOW}Public Key:${NC}"
pipe-tool show-public-key --key-path=$HOME/.permissionless/key.json

# Node durumunu kontrol etme
echo -e "\n${YELLOW}Node durumu kontrol ediliyor...${NC}"
pipe-tool list-nodes --node-registry-url="https://rpc.pipedev.network"

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Kurulum Tamamlandı!           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "\n${YELLOW}Log kayıtlarını görüntülemek için:${NC}"
echo -e "sudo journalctl -f -u dcdnd.service"
