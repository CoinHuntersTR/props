#!/bin/bash

# Union Testnet Kurulumu - Cosmovisor Olmadan
# Port: 26, Moniker: CoinHunters

echo "=== Union Testnet Kurulumu Başlıyor ==="

# Moniker ayarla
MONIKER="CoinHunters"

# Sistem güncellemesi ve gerekli araçları kur
echo "Sistem güncelleniyor ve gerekli araçlar kuruluyor..."
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

# Go kurulumu
echo "Go kuruluyor..."
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.24.2.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

# Union binary indir ve kur
echo "Union binary indiriliyor ve kuruluyor..."
wget -O uniond https://github.com/unionlabs/union/releases/download/uniond%2Fv1.2.0-rc2.alpha1/uniond-release-x86_64-linux
chmod +x uniond
sudo mv uniond /usr/local/bin/

# Node'u initialize et
echo "Node initialize ediliyor..."
uniond init $MONIKER --chain-id union-testnet-10 --home=$HOME/.union

# Client konfigürasyonu
echo "Client konfigürasyonu yapılıyor..."
uniond config set client chain-id union-testnet-10 --home=$HOME/.union
uniond config set client keyring-backend test --home=$HOME/.union
uniond config set client node tcp://localhost:26657 --home=$HOME/.union

# Genesis ve addrbook indir
echo "Genesis ve addrbook indiriliyor..."
curl -Ls https://snapshots.kjnodes.com/union-testnet/genesis.json > $HOME/.union/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/union-testnet/addrbook.json > $HOME/.union/config/addrbook.json

# Konfigürasyon ayarları
echo "Konfigürasyon ayarları yapılıyor..."

# Seeds ekle
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@union-testnet.rpc.kjnodes.com:17159\"|" $HOME/.union/config/config.toml

# Live peers ekle
PEERS="39f02482a6b4de484174fd24c0ba86bde4a9cfc5@23.111.23.233:16656,a884f78b3b026847e8cbbde9073e2c53377ab6cb@89.58.24.181:26656,2bd4ff5345920f6a41ecd46ace99dc1f239fdf38@157.180.42.128:26656,629ed307bbfeeaddb26d2ff48f377fa2bc8e7ffa@95.217.200.98:22656,ce78c5255a5070eec0f2b1191534ebbebd53e482@184.107.57.139:57200"
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.union/config/config.toml

# Minimum gas price ayarla
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0muno\"|" $HOME/.union/config/app.toml

# Pruning ayarları
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.union/config/app.toml

# Port 26 ayarları (default portlar)
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:26658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:26657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:26060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:26656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":26660\"%" $HOME/.union/config/config.toml

sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:26317\"%; s%^address = \":8080\"%address = \":26080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:26090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:26091\"%; s%:8545%:26545%; s%:8546%:26546%; s%:6065%:26065%" $HOME/.union/config/app.toml

# Systemd service oluştur
echo "Systemd service oluşturuluyor..."
sudo tee /etc/systemd/system/union-testnet.service > /dev/null << EOF
[Unit]
Description=Union Testnet Node
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/uniond start --home=$HOME/.union
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable union-testnet.service

# Snapshot indir
echo "Snapshot indiriliyor..."
curl -o - -L https://snapshots.polkachu.com/testnet-snapshots/union/union_2096193.tar.lz4 | lz4 -c -d - | tar -x -C $HOME/.union

# Service'i başlat
echo "Service başlatılıyor..."
sudo systemctl start union-testnet.service

echo "=== Union Testnet Kurulumu Tamamlandı ==="
echo "Node durumunu kontrol etmek için:"
echo "sudo journalctl -u union-testnet.service -f --no-hostname -o cat"
echo ""
echo "Sync durumunu kontrol etmek için:"
echo "uniond status --home=$HOME/.union 2>&1 | jq .SyncInfo"
