#!/bin/bash

# Moniker al
read -p "Lütfen Moniker'ınızı girin: " MONIKER

echo -e "\e[1m\e[32m1. Update && Upgrade... \e[0m"
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m1. Paketleri yükleniyor... \e[0m"
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make lz4 unzip ncdu -y

echo -e "\e[1m\e[32m1. GO'yu yükleniyor... \e[0m"
ver="1.21.5"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"

sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"

echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo -e "\e[1m\e[32m1. Binary dosyasını indiriliyor... \e[0m"
wget https://github.com/airchains-network/junction/releases/download/v0.1.0/junctiond
chmod +x junctiond
sudo mv junctiond /usr/local/bin

echo -e "\e[1m\e[32m1. Config, Addrbook ve Genesis dosyalarını ayarlanıyor... \e[0m"
junctiond config chain-id junction
junctiond init "$MONIKER" --chain-id junction

sudo wget -O $HOME/.junction/config/genesis.json https://files.dymion.cloud/junction/genesis.json
sudo wget -O $HOME/.junction/config/addrbook.json https://files.dymion.cloud/junction/addrbook.json

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025amf\"/;" ~/.junction/config/app.toml

echo -e "\e[1m\e[32m1. # Pruning... \e[0m"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.junction/config/app.toml

echo -e "\e[1m\e[32m1. Set Peers... \e[0m"
PEERS=$(curl -sS https://junction-rpc.dymion.cloud/net_info | \
jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | \
awk -F ':' '{printf "%s:%s%s", $1, $(NF), NR==NF?"":","}')
echo "$PEERS"

sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.junction/config/config.toml

echo -e "\e[1m\e[32m1. Servis oluşturuluyor... \e[0m"
sudo tee /etc/systemd/system/junctiond.service > /dev/null <<EOF
[Unit]
Description=junction
After=network-online.target
[Service]
User=$USER
ExecStart=$(which junctiond) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable junctiond

echo -e "\e[1m\e[32m1. Snapshot indiriliyor... \e[0m"
sudo systemctl stop junctiond
junctiond tendermint unsafe-reset-all --home ~/.junction/ --keep-addr-book
curl https://files.dymion.cloud/junction/data.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.junction
sudo systemctl restart junctiond

echo -e "\e[1m\e[32m1.Log kontrolü... \e[0m"
journalctl -u junctiond -f -o cat
