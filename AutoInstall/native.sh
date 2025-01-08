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
echo "export NATIVE_CHAIN_ID="sunrise-test-0.2"" >> $HOME/.bash_profile
echo "export NATIVE_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$NATIVE_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$NATIVE_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.1"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
wget -O sunrised wget https://github.com/sunriselayer/sunrise/releases/download/v0.2.5-rc1/sunrised
chmod +x $HOME/sunrised
mv $HOME/sunrised $HOME/go/bin/sunrised


printGreen "5. Configuring and init app..." && sleep 1
# config and init app
sunrised init $MONIKER --chain-id $NATIVE_CHAIN_ID
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.gonative/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/native/genesis.json
wget -O $HOME/.gonative/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/native/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="0c0e0cf617c1c58297f53f3a82cea86a7c860396@a.gonative-test-1.cauchye.net:26656,db223ecc4fba0e7135ba782c0fd710580c5213a6@a-node.gonative-test-1.cauchye.net:26656,82bc2fdbfc735b1406b9da4181036ab9c44b63be@b-node.gonative-test-1.cauchye.net:26656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.gonative/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${NATIVE_PORT}317%g;
s%:8080%:${NATIVE_PORT}080%g;
s%:9090%:${NATIVE_PORT}090%g;
s%:9091%:${NATIVE_PORT}091%g;
s%:8545%:${NATIVE_PORT}545%g;
s%:8546%:${NATIVE_PORT}546%g;
s%:6065%:${NATIVE_PORT}065%g" $HOME/.gonative/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${NATIVE_PORT}658%g;
s%:26657%:${NATIVE_PORT}657%g;
s%:6060%:${NATIVE_PORT}060%g;
s%:26656%:${NATIVE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${NATIVE_PORT}656\"%;
s%:26660%:${NATIVE_PORT}660%g" $HOME/.gonative/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.gonative/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.gonative/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.gonative/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.002urise"|g' $HOME/.gonative/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.gonative/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.gonative/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/sunrised.service > /dev/null <<EOF
[Unit]
Description=sunrise node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.gonative
ExecStart=$(which sunrised) start --home $HOME/.gonative
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
sunrised tendermint unsafe-reset-all --home $HOME/.gonative
if curl -s --head curl https://snapshot.stir.network/sunrise/sunrise-test-0.2-v0.2.0.tar.gz | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshot.stir.network/sunrise/sunrise-test-0.2-v0.2.0.tar.gz | tar -xz -C $HOME/.gonative
    else
  echo "no snapshot founded"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable sunrised
sudo systemctl restart sunrised && sudo journalctl -u sunrised -f
