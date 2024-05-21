#!/bin/bash

# Kullanıcıdan MONIKER ismini al
read -p "Lütfen validator isminizi girin: " MONIKER

# MONIKER'i değişken olarak ayarla
echo "MONIKER=\"$MONIKER\""

# Sistem güncelleme ve gerekli araçların kurulumu
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

# Go kurulumu
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh
echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile
source /etc/profile.d/golang.sh
source $HOME/.profile

# Binarilerin indirilmesi
mkdir -p $HOME/.soarchain/cosmovisor/genesis/bin
wget -O $HOME/.soarchain/cosmovisor/genesis/bin/soarchaind https://github.com/soar-robotics/testnet-binaries/raw/main/v0.2.10/ubuntu22.04/soarchaind
chmod +x $HOME/.soarchain/cosmovisor/genesis/bin/soarchaind

# Libwasmvm kütüphanesinin kurulumu
sudo wget -O /var/lib/libwasmvm.x86_64.so https://snapshots.kjnodes.com/soarchain-testnet/libwasmvm.x86_64.so

# Uygulama symlink'lerinin oluşturulması
sudo ln -s $HOME/.soarchain/cosmovisor/genesis $HOME/.soarchain/cosmovisor/current -f
sudo ln -s $HOME/.soarchain/cosmovisor/current/bin/soarchaind /usr/local/bin/soarchaind -f

# Cosmovisor kurulumu ve servis oluşturulması
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

# Servis dosyasının oluşturulması
sudo tee /etc/systemd/system/soarchain.service > /dev/null << EOF
[Unit]
Description=soarchain node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.soarchain"
Environment="DAEMON_NAME=soarchaind"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.soarchain/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable soarchain.service

# Node'un başlatılması
soarchaind config chain-id soarchaintestnet
soarchaind config keyring-backend test
soarchaind config node tcp://localhost:17257
soarchaind init $MONIKER --chain-id soarchaintestnet

# Genesis ve addrbook dosyalarının indirilmesi
curl -Ls https://snapshots.kjnodes.com/soarchain-testnet/genesis.json > $HOME/.soarchain/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/soarchain-testnet/addrbook.json > $HOME/.soarchain/config/addrbook.json

# Seeds eklenmesi
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@soarchain-testnet.rpc.kjnodes.com:17259\"|" $HOME/.soarchain/config/config.toml

# Minimum gas price ayarı
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.0001utsoar\"|" $HOME/.soarchain/config/app.toml

# Pruning ayarları
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.soarchain/config/app.toml

# Özel port ayarları
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:17258\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:17257\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:17260\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:17256\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":17266\"%" $HOME/.soarchain/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:17217\"%; s%^address = \":8080\"%address = \":17280\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:17290\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:17291\"%; s%:8545%:17245%; s%:8546%:17246%; s%:6065%:17265%" $HOME/.soarchain/config/app.toml

# Özel timeout ayarı
sed -i -e "s|^timeout_commit *=.*|timeout_commit = \"15s\"|" $HOME/.soarchain/config/app.toml

# En son zincir snapshot'unun indirilmesi
curl -L https://snapshots.kjnodes.com/soarchain-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.soarchain
[[ -f $HOME/.soarchain/data/upgrade-info.json ]] && cp $HOME/.soarchain/data/upgrade-info.json $HOME/.soarchain/cosmovisor/genesis/upgrade-info.json

# Servisi başlat ve logları kontrol et
sudo systemctl start soarchain.service && sudo journalctl -u soarchain.service -f --no-hostname -o cat
