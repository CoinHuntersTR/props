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
echo "export BABYLON_CHAIN_ID="bbn-test-5"" >> $HOME/.bash_profile
echo "export BABYLON_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$BABYLON_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$BABYLON_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go
cd $HOME
VER="1.23.4"
sudo rm -rf /usr/local/go/
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"

# Configure Go
echo "export GOROOT=/usr/local/go" >> ~/.bash_profile
echo "export GOPATH=$HOME/go" >> ~/.bash_profile
echo "export GO111MODULE=on" >> ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile

echo $(go version) && sleep 1

printGreen "2. Installing Cosmovisor..." && sleep 1
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printGreen "3. Installing babylon binary..." && sleep 1
cd $HOME
rm -rf babylon
git clone https://github.com/babylonlabs-io/babylon.git
cd babylon
git checkout v1.0.0-rc.3
make install
babylond version

printGreen "4. Configuring and initializing node..." && sleep 1
babylond init $MONIKER --chain-id $BABYLON_CHAIN_ID

printGreen "5. Downloading genesis and addrbook..." && sleep 1
wget -O $HOME/.babylond/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/babylon/genesis.json
wget -O $HOME/.babylond/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/babylon/addrbook.json
sleep 1
echo done

printGreen "6. Setting up Cosmovisor..." && sleep 1
# Create Cosmovisor folders
mkdir -p ~/.babylond/cosmovisor/genesis/bin
mkdir -p ~/.babylond/cosmovisor/upgrades

# Copy binary to Cosmovisor folder
cp ~/go/bin/babylond ~/.babylond/cosmovisor/genesis/bin

printGreen "7. Configuring node..." && sleep 1
# set seeds and peers
PEERS="be232be53f7ac3c4a6628f98becb48fd25df1adf@babylon-testnet-seed.nodes.guru:55706,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656"
URL="https://babylon-testnet-rpc.polkachu.com/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)

sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|; s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.babylond/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${BABYLON_PORT}317%g;
s%:8080%:${BABYLON_PORT}080%g;
s%:9090%:${BABYLON_PORT}090%g;
s%:9091%:${BABYLON_PORT}091%g;
s%:8545%:${BABYLON_PORT}545%g;
s%:8546%:${BABYLON_PORT}546%g;
s%:6065%:${BABYLON_PORT}065%g" $HOME/.babylond/config/app.toml

# set custom ports in config.toml
sed -i.bak -e "s%:26658%:${BABYLON_PORT}658%g;
s%:26657%:${BABYLON_PORT}657%g;
s%:6060%:${BABYLON_PORT}060%g;
s%:26656%:${BABYLON_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${BABYLON_PORT}656\"%;
s%:26660%:${BABYLON_PORT}660%g" $HOME/.babylond/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.babylond/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.babylond/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.babylond/config/app.toml

# set minimum gas price and other configs
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.002ubbn"|g' $HOME/.babylond/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.babylond/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.babylond/config/config.toml
sleep 1
echo done

printGreen "8. Creating service file..." && sleep 1
# create service file with Cosmovisor
sudo tee /etc/systemd/system/babylon.service > /dev/null <<EOF
[Unit]
Description="babylon node"
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=babylond"
Environment="DAEMON_HOME=$HOME/.babylond"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

printGreen "9. Starting node..." && sleep 1
# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable babylon.service
sudo systemctl start babylon.service

printGreen "10. Node logs:" && sleep 1
sudo journalctl -fu babylon -o cat
