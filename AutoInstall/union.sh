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
echo "export UNION_CHAIN_ID="union-testnet-8"" >> $HOME/.bash_profile
echo "export UNION_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$UNION_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$UNION_PORT\e[0m"
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

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
wget -O uniond https://snapshots.kjnodes.com/union-testnet/uniond-v0.24.0-linux-amd64
chmod +x uniond
mv uniond $HOME/go/bin/

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
uniond --home $HOME/.union init $MONIKER --chain-id union-testnet-8
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.union/config/genesis.json https://testnet-files.itrocket.net/union/genesis.json
wget -O $HOME/.union/config/addrbook.json https://testnet-files.itrocket.net/union/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="2812a4ae3ebfba02973535d05d2bbcc80b7d215f@union-testnet-seed.itrocket.net:23656"
PEERS="a05dde8737e66c99260edfd45180055fe7f8bd9d@union-testnet-peer.itrocket.net:23656,8ac7ea528b1bb6255022eae6c62dfb2ffefa534f@162.250.127.226:26656,4761850effbd601ca6bee5f79d53aca02da4e3dc@88.99.3.158:24656,d4bf3b30d1ea83dc339b2122a68dfa4f2ce26687@135.181.134.151:24656,224f6319a9f478d43a91ccfa712fd252a207a273@65.109.68.87:26656,6527b4e4a8e2a2b37d95517ac38c431ca271cd31@45.159.220.106:26656,c5ba0247be935b7d6fcc30585c86f00eb43f113c@45.159.220.112:26656,e16bf70fcd8d2945e43244c92feba2e1e27afe5f@144.76.76.176:3000"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.union/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${UNION_PORT}317%g;
s%:8080%:${UNION_PORT}080%g;
s%:9090%:${UNION_PORT}090%g;
s%:9091%:${UNION_PORT}091%g;
s%:8545%:${UNION_PORT}545%g;
s%:8546%:${UNION_PORT}546%g;
s%:6065%:${UNION_PORT}065%g" $HOME/.union/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${UNION_PORT}658%g;
s%:26657%:${UNION_PORT}657%g;
s%:6060%:${UNION_PORT}060%g;
s%:26656%:${UNION_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${UNION_PORT}656\"%;
s%:26660%:${UNION_PORT}660%g" $HOME/.union/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.union/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.union/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.union/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0muno"|g' $HOME/.union/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.union/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.union/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/uniond.service > /dev/null <<EOF
[Unit]
Description=union node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.union
ExecStart=$(which uniond) start --home $HOME/.union
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
uniond tendermint unsafe-reset-all --home $HOME/.union --home $HOME/.union
if curl -s --head curl https://testnet-files.itrocket.net/union/snap_union.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/union/snap_union.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.union
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable uniond
sudo systemctl restart uniond && sudo journalctl -u uniond -f
