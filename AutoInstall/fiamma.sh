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
echo "export FIAMMA_CHAIN_ID="fiamma-testnet-1"" >> $HOME/.bash_profile
echo "export FIAMMA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$FIAMMA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$FIAMMA_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.3"
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
rm -rf fiamma
git clone https://github.com/fiamma-chain/fiamma.git
cd fiamma
git checkout v1.0.0
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
fiammad init $MONIKER --chain-id $FIAMMA_CHAIN_ID
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${FIAMMA_PORT}657\"|" $HOME/.fiamma/config/client.toml
sed -i -e "s|^keyring-backend *=.*|keyring-backend = \"os\"|" $HOME/.fiamma/config/client.toml
sed -i -e "s|^chain-id *=.*|chain-id = \"fiamma-testnet-1\"|" $HOME/.fiamma/config/client.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.fiamma/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/fiamma/genesis.json
wget -O $HOME/.fiamma/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/fiamma/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
URL="https://fiamma-testnet-rpc.itrocket.net/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|; s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.fiamma/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${FIAMMA_PORT}317%g;
s%:8080%:${FIAMMA_PORT}080%g;
s%:9090%:${FIAMMA_PORT}090%g;
s%:9091%:${FIAMMA_PORT}091%g;
s%:8545%:${FIAMMA_PORT}545%g;
s%:8546%:${FIAMMA_PORT}546%g;
s%:6065%:${FIAMMA_PORT}065%g" $HOME/.fiamma/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${FIAMMA_PORT}658%g;
s%:26657%:${FIAMMA_PORT}657%g;
s%:6060%:${FIAMMA_PORT}060%g;
s%:26656%:${FIAMMA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${FIAMMA_PORT}656\"%;
s%:26660%:${FIAMMA_PORT}660%g" $HOME/.fiamma/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.fiamma/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.fiamma/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.fiamma/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.00001ufia"|g' $HOME/.fiamma/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.fiamma/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.fiamma/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/fiammad.service > /dev/null <<EOF
[Unit]
Description=fiamma node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.fiamma
ExecStart=$(which fiammad) start --home $HOME/.fiamma
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
fiammad tendermint unsafe-reset-all --home $HOME/.fiamma

# Automatically find the latest snapshot
SNAPSHOT_URL="https://server-5.itrocket.net/testnet/fiamma/"
LATEST_SNAPSHOT=$(curl -s $SNAPSHOT_URL | grep -oP 'fiamma_\d{4}-\d{2}-\d{2}_\d+_snap.tar.lz4' | sort | tail -n 1)

if [ -n "$LATEST_SNAPSHOT" ]; then
  echo "Downloading latest snapshot: $LATEST_SNAPSHOT"
  curl "${SNAPSHOT_URL}${LATEST_SNAPSHOT}" | lz4 -dc - | tar -xf - -C $HOME/.fiamma
else
  echo "No snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable fiammad
sudo systemctl restart fiammad && sudo journalctl -u fiammad -f
