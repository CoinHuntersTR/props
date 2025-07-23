#!/bin/bash

# Update system and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install git gcc make jq curl lz4 -y

# Install Go
cd $HOME
VER=1.23.5
wget -qO go.tar.gz "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz
rm go.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bashrc
source ~/.bashrc
mkdir -p ~/go/bin

# Download binary and build
cd $HOME
rm -rf uniond
git clone https://github.com/unionlabs/union uniond
cd uniond
APP_VERSION=uniond/v1.2.0-rc2.alpha1
git checkout tags/$APP_VERSION -b $APP_VERSION
cd uniond && go build -o uniond ./cmd/uniond && mv uniond ../../go/bin/.

# Config and init app with CoinHunters moniker
uniond init CoinHunters --chain-id union-testnet-10
wget -O $HOME/.union/config/genesis.json https://st-snap-1.stakeme.pro/union/testnet/pruned/genesis.json
wget -O $HOME/.union/config/addrbook.json https://st-snap-1.stakeme.pro/union/testnet/pruned/addrbook.json

# Set seeds and peers
SEED=26a6eaf0494a269ec5b68610e61d8a73bb80198f@union-testnet-seed.stakeme.pro:17156
PEERS=d6d726120e84f36f3536cb8603b88c52cd27c0b3@176.9.157.142:24656,b7844e8d1372c1ddb9600c2175701b34aa5f640b@65.108.230.168:32220,6cd0316dff5e55ebec848b34051b0f3554d5213f@65.109.123.201:24656,417a70fa3ec2d7ccbaa957162818d1f88b966403@46.166.162.14:26656,4183260a719d26b8d3f291c26291b1ea46ab61f8@51.195.4.122:26656,18e3f9e9b49ab3b2794588010dafbf38fc1cae99@167.235.115.23:24656,716ed50a672cf36f65d74b3da985cfcc9a807433@148.72.141.31:26656,bf92bbe7954c73ecb0054c3f3bc23449ff536943@147.135.77.20:26656,dded6ce6052ff69976df1b5ee371221d57cc24d8@95.111.245.211:26656
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEED\"/}" -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.union/config/config.toml

# Set custom ports (26xxx)
sed -i.bak -e "s%:1317%:26317%g;
s%:8080%:26080%g;
s%:9090%:26090%g;
s%:9091%:26091%g;
s%:8545%:26545%g;
s%:8546%:26546%g;
s%:6065%:26065%g" $HOME/.union/config/app.toml

sed -i.bak -e "s%:26658%:26658%g;
s%:26657%:26657%g;
s%:6060%:26060%g;
s%:26656%:26656%g;
s%:26660%:26660%g" $HOME/.union/config/config.toml

# Config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.union/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.union/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.union/config/app.toml

# Set minimum gas price
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0muno"|g' $HOME/.union/config/app.toml

# Disable indexing
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.union/config/config.toml

# Create service file
sudo tee /etc/systemd/system/uniond.service > /dev/null <<EOF
[Unit]
Description=Uniond Daemon
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.union
ExecStart=$(which uniond) start
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# Reset and download snapshot
uniond tendermint unsafe-reset-all --home $HOME/.union
if curl -s --head https://st-snap-1.stakeme.pro/union/testnet/pruned/cosmos_data_union_testnet_20250723_180001.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://st-snap-1.stakeme.pro/union/testnet/pruned/cosmos_data_union_testnet_20250723_180001.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.union
else
  echo "no snapshot found"
fi

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable uniond.service
sudo systemctl restart uniond.service && sudo journalctl -u uniond.service -f -o cat
