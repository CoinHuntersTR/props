#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

printLogo

# Solana wallet adresi isteme
read -p "Enter your Solana wallet address: " SOLANA_WALLET

# Sistem güncellemelerini yükleme
echo "System updating..."
sudo apt update && sudo apt upgrade -y
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang aria2 bsdmainutils ncdu unzip libleveldb-dev -y

# Dizinleri oluşturma
echo "Creating directories..."
mkdir -p /root/pipenetwork
mkdir -p /root/pipenetwork/download_cache
cd /root/pipenetwork

# Port açma
echo "Opening port 8003..."
ufw allow 8003/tcp

# Waitlist kontrolü
echo "Did you receive a waitlist email from Pipe Network?"
echo "1) Yes"
echo "2) No"
read -p "Enter your choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    read -p "Enter the URL from email: " EMAIL_URL
    curl -L -o pop "$EMAIL_URL"
else
    wget -O pop "https://dl.pipecdn.app/v0.2.4/pop"
fi

# Çalıştırma izni verme
chmod +x pop

# Kaydolma
./pop --signup-by-referral-route def5b8424373f8f8

# Servis dosyası oluşturma
echo "Creating service file..."
cat > /etc/systemd/system/pipe-pop.service << EOF
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=root
Group=root
ExecStart=/root/pipenetwork/pop --ram=12 --pubKey $SOLANA_WALLET --max-disk 300 --cache-dir /var/cache/pop/download_cache
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=/root/pipenetwork

[Install]
WantedBy=multi-user.target
EOF

# Servisi başlatma
echo "Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable pipe-pop
sudo systemctl start pipe-pop

# Durum kontrolü
echo "Checking service status..."
sudo systemctl status pipe-pop

# Puan ve uptime kontrolü
echo "Checking score and uptime..."
./pop --status

echo "Installation completed! You can check logs with: journalctl -u pipe-pop -f"
