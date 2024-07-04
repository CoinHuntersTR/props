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
echo "export NIBIRU_CHAIN_ID="cataclysm-1"" >> $HOME/.bash_profile
echo "export NIBIRU_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$NIBIRU_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$NIBIRU_PORT\e[0m"
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
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru.git
cd nibiru
git checkout v1.5.0
make build

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
lavad init $MONIKER --chain-id $NIBIRU_CHAIN_ID

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.nibid/config/genesis.json https://snapshots.kjnodes.com/nibiru/genesis.json
wget -O $HOME/.nibid/config/addrbook.json https://snapshots.kjnodes.com/nibiru/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="e98a7fc1c7c6b9052520a5783c5c60496e6818e9@rpc.nibiru.nodestake.org:666"
PEERS="b7262df35a7e1d1fb4027464efe9d9d6218ca4c7@35.233.111.89:26656,a36af139a487ffe939302b909ad7f502f2f11907@23.106.238.179:26656,b4d347b39b442571d9eb6a1a82bfebbb5fdf399b@95.214.55.138:24656,ba572c6156aefd0b0ac500bd5477ff2372d7ea28@141.94.195.151:19856,89757803f40da51678451735445ad40d5b15e059@164.152.161.5:26656,d1f31c6968712b2da1079cf0387153560d2f1cf7@95.217.204.58:19856,e7af24b15365bff9537e2776c2a5fdf01b933dc5@34.76.178.49:26656,d3c7f343d7ed815b73eef34d7d37948f10a1deab@34.76.80.206:26656,151acb0de556f4a059f9bd40d46190ee91f06422@34.38.151.176:26656,4f659d7db311a4fa2433ad372fa8c17850ec3bd7@185.218.124.63:26656,659e85aaf0bd4cbbfbe381eebc6b582f71d6993b@65.21.65.254:1510,637077d431f618181597706810a65c826524fd74@176.9.120.85:19856,05106550b6e738d8ce50cb857520124bbcce318f@34.140.34.185:26656,07faf6678cbcee9909348b6d705260f9ba6ca1ff@65.108.232.104:19856"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.nibid/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${NIBIRU_PORT}317%g;
s%:8080%:${NIBIRU_PORT}080%g;
s%:9090%:${NIBIRU_PORT}090%g;
s%:9091%:${NIBIRU_PORT}091%g;
s%:8545%:${NIBIRU_PORT}545%g;
s%:8546%:${NIBIRU_PORT}546%g;
s%:6065%:${NIBIRU_PORT}065%g" $HOME/.nibid/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${LAVA_PORT}658%g;
s%:26657%:${NIBIRU_PORT}657%g;
s%:6060%:${NIBIRU_PORT}060%g;
s%:26656%:${NIBIRU_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${NIBIRU_PORT}656\"%;
s%:26660%:${NIBIRU_PORT}660%g" $HOME/.nibid/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.nibid/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.025unibi"|g' $HOME/.nibid/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.nibid/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.nibid/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/nibid.service > /dev/null <<EOF
[Unit]
Description=nibid node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.nibid
ExecStart=$(which nibid) start --home $HOME/.nibid
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
nibid tendermint unsafe-reset-all --home $HOME/.nibid
if curl -s --head curl https://snapshots.kjnodes.com/nibiru/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.kjnodes.com/nibiru/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.nibid
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable nibid
sudo systemctl restart nibid && sudo journalctl -u nibid -f
