#!/bin/bash

# Kullanıcıdan $MONIKER ve wallet bilgilerini al
read -p "Lütfen MONIKER'ınızı girin: " MONIKER
read -p "Lütfen wallet bilginizi girin: " WALLET

# Kullanıcıya onay iste
read -p "Girilen bilgiler doğru mu? (E/H): " CONFIRM
if [ "$CONFIRM" != "E" ]; then
    echo "İşlem iptal edildi."
    exit 1
fi

# Gerekli bağımlılıkları yükle
echo "Gerekli bağımlılıkları yükleme işlemi başlatılıyor..."
cd $HOME && source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/update-cosmos.sh)

# Binleri indir ve derle
echo "Binleri indirme ve derleme işlemi başlatılıyor..."
git clone -b v0.1.0 https://github.com/0glabs/0g-chain.git
./0g-chain/networks/testnet/install.sh
source .profile
mkdir -p $HOME/.0gchain/cosmovisor/genesis/bin
cp $HOME/go/bin/0gchaind $HOME/.0gchain/cosmovisor/genesis/bin/
sudo ln -s $HOME/.0gchain/cosmovisor/genesis $HOME/.0gchain/cosmovisor/current -f
sudo ln -s $HOME/.0gchain/cosmovisor/current/bin/0gchaind /usr/local/bin/0gchaind -f

# Servis dosyası oluştur
echo "Servis dosyası oluşturuluyor..."
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0
sudo tee /etc/systemd/system/0gchain.service > /dev/null << EOF
[Unit]
Description=og node service
After=network-online.target
 
[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.0gchain"
Environment="DAEMON_NAME=0gchaind"
Environment="UNSAFE_SKIP_BACKUP=true"
 
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable 0gchain

# Değişkenleri ayarla
echo "Değişkenler ayarlanıyor..."
echo 'export CHAIN_ID="zgtendermint_16600-1"' >> ~/.bash_profile
echo "export WALLET_NAME=\"$WALLET\"" >> ~/.bash_profile
source $HOME/.bash_profile
0gchaind init $MONIKER --chain-id $CHAIN_ID
0gchaind config chain-id $CHAIN_ID
0gchaind config keyring-backend test 

# Genesis ve Addrbook dosyalarını indir
echo "Genesis ve Addrbook dosyaları indiriliyor..."
rm $HOME/.0gchain/config/genesis.json
wget https://github.com/0glabs/0g-chain/releases/download/v0.1.0/genesis.json -O $HOME/.0gchain/config/genesis.json

# Yapılandırma
echo "Yapılandırma yapılıyor..."
seeds=$(curl -s https://raw.githubusercontent.com/CoinHuntersTR/props/main/0g-Newton/seeds.txt)
sed -i.bak -e "s/^seeds *=.*/seeds = \"$seeds\"/" $HOME/.0gchain/config/config.toml
peers=$(curl -s https://raw.githubusercontent.com/CoinHuntersTR/props/main/0g-Newton/peers.txt)
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.0gchain/config/config.toml
sed -i.bak -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.0gchain/config/app.toml
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.00252ua0gi\"/" $HOME/.0gchain/config/app.toml
sed -i "s/^indexer *=.*/indexer = \"kv\"/" $HOME/.0gchain/config/config.toml

# Snapshot
echo "Snapshot alınıyor..."
sudo systemctl stop 0gchain
cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
rm -rf $HOME/.0gchain/data && mkdir -p $HOME/.0gchain/data
curl -L https://snap.vnbnode.com/0g/zgtendermint_16600-1_snapshot_latest.tar.lz4 | tar -I lz4 -xf - -C $HOME/.0gchain/data
mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json

# Servisi başlat
echo "Servis başlatılıyor..."
sudo systemctl restart 0gchain && sudo journalctl -u 0gchain -f
