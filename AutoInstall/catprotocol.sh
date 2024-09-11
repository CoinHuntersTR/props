#!/bin/bash

# Başlangıçta başlık metni
echo -e "\033[0;31m"
echo "  ____      _         _   _             _                 "  
echo " / ___|___ (_)_ __   | | | |_   _ _ __ | |_ ___ _ __ ___  "
echo "| |   / _ \| | '_ \  | |_| | | | | '_ \| __/ _ \ '__/ __| " 
echo "| |__| (_) | | | | | |  _  | |_| | | | | ||  __/ |  \__ \ "
echo " \____\___/|_|_| |_| |_| |_|\__,_|_| |_|\__\___|_|  |___/ "
echo -e "\e[0m"

# Renkler için stil
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_CYAN="\e[36m"
COLOR_RESET="\e[0m"

# Emoji desteği ile log fonksiyonu
log() {
    echo -e "${COLOR_CYAN}\${COLOR_RESET}"
}

# Emoji desteği ile hata işleme
handle_error() {
    echo -e "${COLOR_RED}❌ Hata: \${COLOR_RESET}"
    exit 1
}

# Dosyanın var olup olmadığını kontrol eden fonksiyon
check_file_exists() {
    if [ -f "$1" ]; then
        log "${COLOR_YELLOW}⚠️  Dosya \$1 zaten mevcut, indirme atlanıyor.${COLOR_RESET}"
        return 1
    fi
    return 0
}

# Dizin var olup olmadığını kontrol eden fonksiyon
check_directory_exists() {
    if [ -d "$1" ]; then
        log "${COLOR_GREEN}📁 Dizin $1 zaten mevcut.${COLOR_RESET}"
    else
        log "${COLOR_YELLOW}📂 Dizin $1 oluşturuluyor...${COLOR_RESET}"
        mkdir -p "$1" || handle_error "Dizin $1 oluşturulamadı."
    fi
}

# Yüklü olmayan paketleri kontrol edip yükleme
check_and_install_package() {
    if ! dpkg -l | grep -qw "$1"; then
        log "${COLOR_YELLOW}📦 $1 yükleniyor...${COLOR_RESET}"
        sudo apt-get install -y "$1" || handle_error "$1 yüklenemedi."
    else
        log "${COLOR_GREEN}✔️  $1 zaten yüklü!${COLOR_RESET}"
    fi
}

# Sunucuyu hazırlama: Güncelleme ve gerekli paketleri yükleme
prepare_server() {
    log "${COLOR_BLUE}🔄 Sunucu güncelleniyor ve gerekli paketler yükleniyor...${COLOR_RESET}"
    sudo apt-get update -y && sudo apt-get upgrade -y || handle_error "Sunucu güncellenemedi."

    local packages=("make" "build-essential" "pkg-config" "libssl-dev" "unzip" "tar" "lz4" "gcc" "git" "jq" "nodejs" "npm" "docker.io")
    for package in "${packages[@]}"; do
        check_and_install_package "$package"
    done

    # Yarn'ı global olarak yükle
    log "${COLOR_YELLOW}📦 Yarn yükleniyor...${COLOR_RESET}"
    npm install -g yarn || handle_error "Yarn yüklenemedi."
}

# Fractal Node'u indir ve çıkar
download_and_extract() {
    local url="https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.1.7/fractald-0.1.7-x86_64-linux-gnu.tar.gz"
    local filename="fractald-0.1.7-x86_64-linux-gnu.tar.gz"
    local dirname="fractald-0.1.7-x86_64-linux-gnu"

    check_file_exists "$filename"
    if [ $? -eq 0 ]; then
        log "${COLOR_BLUE}⬇️  Fractal Node indiriliyor...${COLOR_RESET}"
        wget -q "$url" -O "$filename" || handle_error "$filename indirilemedi."
    fi

    log "${COLOR_BLUE}🗜️  $filename çıkarılıyor...${COLOR_RESET}"
    tar -zxvf "$filename" || handle_error "$filename çıkarılamadı."

    check_directory_exists "$dirname/data"
    cp "$dirname/bitcoin.conf" "$dirname/data" || handle_error "bitcoin.conf $dirname/data dizinine kopyalanamadı."
}

# Cüzdanın var olup olmadığını kontrol et
check_wallet_exists() {
    if [ -f "$HOME/.bitcoin/wallets/wallet/wallet.dat" ]; then
        log "${COLOR_GREEN}💰 Cüzdan zaten mevcut, cüzdan oluşturma atlanıyor.${COLOR_RESET}"
        return 1
    fi
    return 0
}

# Yeni cüzdan oluştur
create_wallet() {
    log "${COLOR_BLUE}🔍 Cüzdanın var olup olmadığı kontrol ediliyor...${COLOR_RESET}"
    check_wallet_exists
    if [ $? -eq 1 ]; then
        log "${COLOR_GREEN}✅ Cüzdan zaten mevcut, yeni cüzdan oluşturmaya gerek yok.${COLOR_RESET}"
        return
    fi

    log "${COLOR_BLUE}💼 Yeni cüzdan oluşturuluyor...${COLOR_RESET}"

    cd fractald-0.1.7-x86_64-linux-gnu/bin || handle_error "bin dizinine girilemedi."
    ./bitcoin-wallet -wallet=wallet -legacy create || handle_error "Cüzdan oluşturulamadı."

    log "${COLOR_BLUE}🔑 Cüzdan özel anahtarı dışa aktarılıyor...${COLOR_RESET}"
    ./bitcoin-wallet -wallet=$HOME/.bitcoin/wallets/wallet/wallet.dat -dumpfile=$HOME/.bitcoin/wallets/wallet/MyPK.dat dump || handle_error "Cüzdan özel anahtarı dışa aktarılamadı."

    PRIVATE_KEY=$(awk -F 'checksum,' '/checksum/ {print "Cüzdan özel anahtarı:" \$2}' $HOME/.bitcoin/wallets/wallet/MyPK.dat)
    log "${COLOR_RED}$PRIVATE_KEY${COLOR_RESET}"
    log "${COLOR_YELLOW}⚠️  Lütfen özel anahtarınızı kaydedin!${COLOR_RESET}"
}

# Fractal Node için systemd servis dosyası oluştur
create_service_file() {
    log "${COLOR_BLUE}🛠️  Fractal Node için sistem servisi oluşturuluyor...${COLOR_RESET}"

    if [ -f "/etc/systemd/system/fractald.service" ]; then
        log "${COLOR_YELLOW}⚠️  Servis dosyası zaten mevcut, oluşturma atlanıyor.${COLOR_RESET}"
    else
        sudo tee /etc/systemd/system/fractald.service > /dev/null << EOF
[Unit]
Description=Fractal Node
After=network-online.target
[Service]
User=$USER
ExecStart=$HOME/fractald-0.1.7-x86_64-linux-gnu/bin/bitcoind -datadir=$HOME/fractald-0.1.7-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=5
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload || handle_error "daemon-reload çalıştırılamadı."
        sudo systemctl enable fractald || handle_error "fractald servisi etkinleştirilemedi."
    fi
}

# Fractal Node servisini başlat
start_node() {
    log "${COLOR_BLUE}🚀 Fractal Node başlatılıyor...${COLOR_RESET}"
    sudo systemctl start fractald || handle_error "fractald servisi başlatılamadı."
    log "${COLOR_GREEN}🎉 Fractal Node başarıyla başlatıldı！${COLOR_RESET}"
    log "${COLOR_CYAN}📝 Node loglarını görmek için şu komutu çalıştırın: ${COLOR_BLUE}sudo journalctl -u fractald -f --no-hostname -o cat${COLOR_RESET}"
}

# CAT Protocol'ü ayarla
setup_cat_protocol() {
    log "${COLOR_BLUE}🔄 CAT Protocol ayarlanıyor...${COLOR_RESET}"

    git clone https://github.com/CATProtocol/cat-token-box.git || handle_error "CAT Protocol deposu klonlanamadı."
    cd cat-token-box || handle_error "cat-token-box dizinine girilemedi."

    yarn install || handle_error "CAT Protocol bağımlılıkları yüklenemedi."
    yarn build || handle_error "CAT Protocol derlenemedi."

    cd packages/tracker || handle_error "packages/tracker dizinine girilemedi."
    yarn install || handle_error "tracker bağımlılıkları yüklenemedi."
    yarn build || handle_error "tracker derlenemedi."

    docker compose up -d || handle_error "Docker Compose başlatılamadı."

    cd ../../ && docker build -t tracker:latest . || handle_error "Docker imajı oluşturulamadı."

    docker run -d \
    --name tracker \
    --add-host="host.docker.internal:host-gateway" \
    -e DATABASE_HOST="host.docker.internal" \
    -e RPC_HOST="host.docker.internal" \
    -p 3000:3000 \
    tracker:latest || handle_error "Docker konteyneri çalıştırılamadı."

    log "${COLOR_GREEN}🎉 CAT Protocol başarıyla ayarlandı！${COLOR_RESET}"
}

# CAT minting otomasyonu
automate_cat_minting() {
    log "${COLOR_BLUE}🔄 CAT minting otomasyonu yapılıyor...${COLOR_RESET}"

    cd packages/cli || handle_error "packages/cli dizinine girilemedi."
    yarn install || handle_error "CLI bağımlılıkları yüklenemedi."
    yarn build || handle_error "CLI derlenemedi."

    # Cüzdan oluştur ve adres al
    yarn cli wallet create || handle_error "CLI cüzdanı oluşturulamadı."
    yarn cli wallet address || handle_error "CLI cüzdan adresi alınamadı."

    # Minting otomasyonu
    while true; do
        yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5 --fee-rate 250 || handle_error "CAT minting başarısız oldu."
        log "${COLOR_GREEN}🎉 Başarıyla 5 CAT mintlendi！120 saniye sonra devam ediliyor...${COLOR_RESET}"
        sleep 120
    done
}

# Ana fonksiyon, scriptin yürütülme akışını kontrol eder
main() {
    prepare_server
    download_and_extract
    create_service_file
    create_wallet
    start_node
    setup_cat_protocol
    automate_cat_minting
}

# Ana süreci başlat
main
