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
echo "export DYMENSION_CHAIN_ID="froopyland_100-1"" >> $HOME/.bash_profile
echo "export DYMENSION_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$DYMENSION_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$DYMENSION_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.21.12"
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
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension
git checkout v2.0.0-alpha.8

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
dymd init $MONIKER --chain-id $DYMENSION_CHAIN_ID
sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  $HOME/.dymension/config/config.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.dymension/config/genesis.json https://snapshots.kjnodes.com/dymension-testnet/genesis.json
wget -O $HOME/.dymension/config/addrbook.json  https://snapshots.kjnodes.com/dymension-testnet/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="3f472746f46493309650e5a033076689996c8881@dymension-testnet.rpc.kjnodes.com:14659
PEERS=""ad2d039e64e554c9168e075273a7924de38244a5@85.10.201.125:60656,5bd59399d230a2074c5b2aa108b53ac9c8e06d64@51.159.138.189:26656,c404339dcbe08b2ed93b666a3995044b83982308@46.166.170.53:26656,5342f6f59c7b81b5ea3bef8cd9d6ad224b8eb473@95.217.176.55:26656,aa755789a28dd8701ad1cd447866a2c029412199@144.76.18.199:26656,e7857b8ed09bd0101af72e30425555efa8f4a242@148.251.177.108:20556,febc198f5086aed9bb578044c78cd9cfaf9023ac@65.108.229.93:29656,515b840bc20a321758f8f77e378a15dca58d9030@65.109.93.58:30656,784a6da030dc59fdee91d92745e7188bce6f6f1f@65.21.74.56:26656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:14656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.dymension/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${DYMENSION_PORT}317%g;
s%:8080%:${DYMENSION_PORT}080%g;
s%:9090%:${DYMENSION_PORT}090%g;
s%:9091%:${DYMENSION_PORT}091%g;
s%:8545%:${DYMENSION_PORT}545%g;
s%:8546%:${DYMENSION_PORT}546%g;
s%:6065%:${DYMENSION_PORT}065%g" $HOME/.dymension/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${DYMENSION_PORT}658%g;
s%:26657%:${DYMENSION_PORT}657%g;
s%:6060%:${DYMENSION_PORT}060%g;
s%:26656%:${DYMENSION_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${DYMENSION_PORT}656\"%;
s%:26660%:${DYMENSION_PORT}660%g" $HOME/.dymension/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.dymension/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.dymension/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.dymension/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "20000000000udym"|g' $HOME/.dymension/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.dymension/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.dymension/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/dymension-testnet.service > /dev/null <<EOF
[Unit]
Description=dymension-testnet.service
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.dymension
ExecStart=$(which dymd) start --home $HOME/.dymension
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
dymd tendermint unsafe-reset-all --home $HOME/.dymension
if curl -s --head curl https://snapshots.kjnodes.com/dymension-testnet/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.kjnodes.com/dymension-testnet/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.dymension
    else
  echo "no snapshot founded"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable dymension-testnet.service
sudo systemctl restart dymension-testnet.service && sudo journalctl -u dymension-testnet.service -f
