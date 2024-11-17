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
echo "export AXONE_CHAIN_ID="axone-dentrite-1"" >> $HOME/.bash_profile
echo "export AXONE_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$AXONE_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$AXONE_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.8"
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
rm -rf axoned
git clone https://github.com/axone-protocol/axoned.git
cd axoned
git checkout v10.0.0

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
axoned config set client node tcp://localhost:${AXONE_PORT}657
axoned config set client keyring-backend test
axoned config set client chain-id axone-dentrite-1
axoned init $MONIKER --chain-id axone-dentrite-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.axoned/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/axone/genesis.json
wget -O $HOME/.axoned/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/axone/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
URL="https://axone-testnet-rpc.polkachu.com/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|; s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.axoned/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${AXONE_PORT}317%g;
s%:8080%:${AXONE_PORT}080%g;
s%:9090%:${AXONE_PORT}090%g;
s%:9091%:${AXONE_PORT}091%g;
s%:8545%:${AXONE_PORT}545%g;
s%:8546%:${AXONE_PORT}546%g;
s%:6065%:${AXONE_PORT}065%g" $HOME/.axoned/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${AXONE_PORT}658%g;
s%:26657%:${AXONE_PORT}657%g;
s%:6060%:${AXONE_PORT}060%g;
s%:26656%:${AXONE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${AXONE_PORT}656\"%;
s%:26660%:${AXONE_PORT}660%g" $HOME/.axoned/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.axoned/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.axoned/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.axoned/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0uaxone"|g' $HOME/.axoned/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.axoned/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.axoned/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/axoned.service > /dev/null <<EOF
[Unit]
Description=axone node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.axoned
ExecStart=$(which axoned) start --home $HOME/.axoned
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
axoned tendermint unsafe-reset-all --home $HOME/.axoned --home $HOME/.axoned
if curl -s --head curl https://snapshots.coinhunterstr.com/testnet/axone/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.coinhunterstr.com/testnet/axone/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.axoned
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable axoned
sudo systemctl restart axoned && sudo journalctl -u axoned -f
