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
echo "export AXELAR_CHAIN_ID="axelar-dojo-1"" >> $HOME/.bash_profile
echo "export AXELAR_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$AXELAR_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$AXELAR_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.23.0"
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
rm -rf axelar-core
git clone https://github.com/axelarnetwork/axelar-core.git
cd axelar-core
git checkout v1.0.2
make build
cp ./bin/axelard /usr/local/bin/

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
axelard init $MONIKER --chain-id $AXELAR_CHAIN_ID 
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${AXELAR_PORT}657\"|" $HOME/.axelar/config/client.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.axelar/config/genesis.json https://snapshots.polkachu.com/genesis/axelar/genesis.json
wget -O $HOME/.axelar/config/addrbook.json https://snapshots.polkachu.com/addrbook/axelar/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:15156"
URL="https://axelar-rpc.polkachu.com/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $CONFIG_PATH

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${AXELAR_PORT}317%g;
s%:8080%:${AXELAR_PORT}080%g;
s%:9090%:${AXELAR_PORT}090%g;
s%:9091%:${AXELAR_PORT}091%g;
s%:8545%:${AXELAR_PORT}545%g;
s%:8546%:${AXELAR_PORT}546%g;
s%:6065%:${AXELAR_PORT}065%g" $HOME/.axelar/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${AXELAR_PORT}658%g;
s%:26657%:${AXELAR_PORT}657%g;
s%:6060%:${AXELAR_PORT}060%g;
s%:26656%:${AXELAR_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${AXELAR_PORT}656\"%;
s%:26660%:${AXELAR_PORT}660%g" $HOME/.axelar/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.axelar/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.axelar/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.axelar/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0uaxl"|g' $HOME/.axelar/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.axelar/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.axelar/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/axelar.service > /dev/null <<EOF
[Unit]
Description=axelar node
After=network-online.target

[Service]
User=root
WorkingDirectory=/root/.axelar
ExecStart=/usr/local/bin/axelard start --home /root/.axelar
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1

# reset and download snapshot
axelard tendermint unsafe-reset-all --home $HOME/.axelar
if curl -s --head curl https://snapshots.polkachu.com/snapshots/axelar/axelar_15738993.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/snapshots/axelar/axelar_15738993.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.axelar
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable axelar.service
sudo systemctl restart axelar.service && sudo journalctl -u axelar.service -f
