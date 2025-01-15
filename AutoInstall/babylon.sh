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
# install go, if needed
cd $HOME
VER="1.23.4"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
rm -rf babylon
git clone https://github.com/babylonlabs-io/babylon.git
cd babylon
git checkout v1.0.0-rc.1
make install
babylond version

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
babylond init $MONIKER --chain-id $BABYLON_CHAIN_ID

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.babylond/config/genesis.json https://ss-t.babylon.nodestake.org/genesis.json
wget -O $HOME/.babylond/config/addrbook.json https://ss-t.babylon.nodestake.org/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
URL="https://rpc-t.babylon.nodestake.org/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|; s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.babylond/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${BABYLON_PORT}317%g;
s%:8080%:${BABYLON_PORT}080%g;
s%:9090%:${BABYLON_PORT}090%g;
s%:9091%:${BABYLON_PORT}091%g;
s%:8545%:${BABYLON_PORT}545%g;
s%:8546%:${BABYLON_PORT}546%g;
s%:6065%:${BABYLON_PORT}065%g" $HOME/.babylond/config/app.toml


# set custom ports in config.toml file
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

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.005ubbn"|g' $HOME/.babylond/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.babylond/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.babylond/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/babylond.service > /dev/null <<EOF
[Unit]
Description=babylond node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.babylond
ExecStart=$(which babylond) start --home $HOME/.babylond
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable babylond
sudo systemctl restart babylond && sudo journalctl -u babylond -f
