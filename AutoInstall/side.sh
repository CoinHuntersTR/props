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
echo "export SIDE_CHAIN_ID="sidechain-1"" >> $HOME/.bash_profile
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
git checkout v1.0.0
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
sided config node tcp://localhost:${SIDE_PORT}657
sided config keyring-backend os
sided config chain-id sidechain-1
sided init $MONIKER --chain-id sidechain-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.side/config/genesis.json https://server-2.itrocket.net/mainnet/side/genesis.json
wget -O $HOME/.side/config/addrbook.json  https://server-2.itrocket.net/mainnet/side/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="9355d3fe49475485444f64db4745dd8a970d7a72@side-mainnet-seed.itrocket.net:18656,a1c99cc234a524e53db8eb44e0c7df7115edd1b4@rpc.side.nodestake.org:666,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:26356"
PEERS="cfc22ac13d20a6f3bd394a8a2dba787bc10c1b32@side-mainnet-peer.itrocket.net:14656,973538e4eb39bac08c9675830239a6358a1e442c@195.201.59.216:26656,8f5a8d7d6c29cd24bc2f844494c75d5044913b53@176.9.124.52:26356,db1df6aed42324c975209edceeba0daf6e8b0bab@160.202.131.55:24656,fc4192d1f80d783dec495abe4101169183d94190@8.52.153.92:14656,4192e340dc7a5e297143e271daf6b52e9e6aea0d@195.14.6.192:26656,24224badba137eb775916d9d5c4ff8f3ceff874b@[2a03:cfc0:8000:13::b910:27be]:11056,05cb5856192b389cff8c3851e0d30ae6a400187d@143.198.41.115:26656,75da8087bdc75ba0eed3c20a0c7a055721ecdb00@46.232.248.39:18656,b34c1431376443769554d89a3737ad65015a16a7@91.134.9.162:26356"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.side/config/config.toml

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
if curl -s --head curl https://snapshots.coinhunterstr.com/mainnet/side/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.coinhunterstr.com/mainnet/side/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.side
    else
  echo "no snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable sided
sudo systemctl restart sided && sudo journalctl -u sided -fo cat
