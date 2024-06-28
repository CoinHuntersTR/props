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
echo "export ALLORA_CHAIN_ID="edgenet"" >> $HOME/.bash_profile
echo "export ALLORA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$ALLORA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ALLORA_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.4"
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
rm -rf allora-chain
git clone https://github.com/allora-network/allora-chain.git
cd allora-chain
git checkout v0.0.10
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
allorad init $MONIKER --chain-id $ALLORA_CHAIN_ID

echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.lava/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/allora/genesis.json

sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
sed -i -e "s|^seeds *=.*|seeds = \"3d3b82e78875b4607c2612b530e835dffde77824@seed-0.edgenet.allora.network:32030,7f47aec3539715a70853589bd7ef8d2fd7995122@seed-1.edgenet.allora.network:32031,f331a946a7bb06d1860b36bbb96345ee99fd737b@seed-2.edgenet.allora.network:32032\"|" $HOME/.allorad/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${ALLORA_PORT}317%g;
s%:8080%:${ALLORA_PORT}080%g;
s%:9090%:${ALLORA_PORT}090%g;
s%:9091%:${ALLORA_PORT}091%g;
s%:8545%:${ALLORA_PORT}545%g;
s%:8546%:${ALLORA_PORT}546%g;
s%:6065%:${ALLORA_PORT}065%g" $HOME/.allorad/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${LAVA_PORT}658%g;
s%:26657%:${ALLORA_PORT}657%g;
s%:6060%:${ALLORA_PORT}060%g;
s%:26656%:${ALLORA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ALLORA_PORT}656\"%;
s%:26660%:${ALLORA_PORT}660%g" $HOME/.allorad/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.allorad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.allorad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.allorad/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0uallo"|g' $HOME/.allorad/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.allorad/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.allorad/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/allorad.service > /dev/null <<EOF
[Unit]
Description=allora node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.allorad
ExecStart=$(which allorad) start --home $HOME/.allorad
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable allorad
sudo systemctl restart allorad && sudo journalctl -u allorad -f
