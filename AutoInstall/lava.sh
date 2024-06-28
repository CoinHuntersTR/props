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
echo "export LAVA_CHAIN_ID="lava-mainnet-1"" >> $HOME/.bash_profile
echo "export LAVA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$LAVA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$LAVA_PORT\e[0m"
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

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
git clone https://github.com/lavanet/lava.git 
cd lava 
git checkout v2.2.0
export LAVA_BINARY=lavad
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
lavad init $MONIKER --chain-id $LAVA_CHAIN_ID
sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  $HOME/.lava/config/config.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.lava/config/genesis.json https://services.lava-mainnet-1.lava.aviaone.com/genesis.json
wget -O $HOME/.lava/config/addrbook.json https://snapshots.kjnodes.com/lava/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="258f523c96efde50d5fe0a9faeea8a3e83be22ca@seed.lava-mainnet-1.lava.aviaone.com:10291,ebacd3e666003397fb685cd44956d33419219950@seed2.lava.chainlayer.net:26656,1105d3a3384edaa450f4f63c2b1ff08d366ee256@159.203.86.102:26656,f1caeaacfac32e4dd00916e8d912e1d834e94eb3@lava-seed.stakecito.com:26666,e4eb68c6fdfab1575b8794205caed47d4f737df4@lava-mainnet-seed.01node.com:26107,2d4db6b95804ea97e1f3655d043e6becf9bffc94@lava-seeds2.w3coins.io:11156,dcbfb490ea930fe9e8058089e3f6a14ca274c1c4@217.182.136.79:26656,e023c3892862744081360a99a2666e8111b196d3@38.242.213.53:26656,eafff29ec471bdd0985a9360b2c103997539c939@lava-seed.node.monster:26649,6a9a65d92b4820a5d198dd95743aa3059d0d3d4c@seed-lava.hashkey.cloud:26656"
sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|" $HOME/.lava/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${LAVA_PORT}317%g;
s%:8080%:${LAVA_PORT}080%g;
s%:9090%:${LAVA_PORT}090%g;
s%:9091%:${LAVA_PORT}091%g;
s%:8545%:${LAVA_PORT}545%g;
s%:8546%:${LAVA_PORT}546%g;
s%:6065%:${LAVA_PORT}065%g" $HOME/.lava/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${LAVA_PORT}658%g;
s%:26657%:${LAVA_PORT}657%g;
s%:6060%:${LAVA_PORT}060%g;
s%:26656%:${LAVA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${LAVA_PORT}656\"%;
s%:26660%:${LAVA_PORT}660%g" $HOME/.lava/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.lava/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0ulava"|g' $HOME/.lava/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.lava/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.lava/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/lavad.service > /dev/null <<EOF
[Unit]
Description=lava node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.lava
ExecStart=$(which lavad) start --home $HOME/.lava
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
lavad tendermint unsafe-reset-all --home $HOME/.lava
if curl -s --head curl https://snapshots.autostake.com/lyIs25DaSWMSm8evWKHGQrb/lava-mainnet-1/latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/lava/snap_lava.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable lavad
sudo systemctl restart lavad && sudo journalctl -u lavad -f
