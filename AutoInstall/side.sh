#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

printLogo

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export SIDE_CHAIN_ID="sidechain-testnet-4"" >> $HOME/.bash_profile
echo "export SIDE_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$SIDE_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$SIDE_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.21.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/refs/heads/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
rm -rf side
git clone https://github.com/sideprotocol/side.git
cd side
git checkout v0.9.4
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
sided config node tcp://localhost:${SIDE_PORT}657
sided config keyring-backend os
sided config chain-id sidechain-testnet-4
sided init $MONIKER --chain-id sidechain-testnet-4
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.side/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/Side/genesis.json
wget -O $HOME/.side/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/Side/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
URL="https://side-testnet-rpc.itrocket.net/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|; s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.side/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${SIDE_PORT}317%g;
s%:8080%:${SIDE_PORT}080%g;
s%:9090%:${SIDE_PORT}090%g;
s%:9091%:${SIDE_PORT}091%g;
s%:8545%:${SIDE_PORT}545%g;
s%:8546%:${SIDE_PORT}546%g;
s%:6065%:${SIDE_PORT}065%g" $HOME/.side/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${SIDE_PORT}658%g;
s%:26657%:${SIDE_PORT}657%g;
s%:6060%:${SIDE_PORT}060%g;
s%:26656%:${SIDE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${SIDE_PORT}656\"%;
s%:26660%:${SIDE_PORT}660%g" $HOME/.side/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.side/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.side/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.side/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.005uside"|g' $HOME/.side/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.side/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.side/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/sided.service > /dev/null <<EOF
[Unit]
Description=side node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.side
ExecStart=$(which sided) start --home $HOME/.side
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
sided tendermint unsafe-reset-all --home $HOME/.side

# Automatically find the latest snapshot
SNAPSHOT_URL="https://server-5.itrocket.net/testnet/side/"
LATEST_SNAPSHOT=$(curl -s $SNAPSHOT_URL | grep -oP 'side_\d{4}-\d{2}-\d{2}_\d+_snap.tar.lz4' | sort | tail -n 1)

if [ -n "$LATEST_SNAPSHOT" ]; then
  echo "Downloading latest snapshot: $LATEST_SNAPSHOT"
  curl "${SNAPSHOT_URL}${LATEST_SNAPSHOT}" | lz4 -dc - | tar -xf - -C $HOME/.side
else
  echo "No snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable sided
sudo systemctl restart sided && sudo journalctl -u sided -f
