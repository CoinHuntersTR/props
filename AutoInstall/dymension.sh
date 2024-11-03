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
echo "export DYMENSION_CHAIN_ID="dymension_1100-1"" >> $HOME/.bash_profile
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
wget -O dymd https://github.com/dymensionxyz/dymension/releases/download/v3.1.0/dymd
chmod +x $HOME/dymd
mv $HOME/dymd $HOME/go/bin/dymd

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
dymd config chain-id dymension_1100-1
dymd config keyring-backend file
dymd config node tcp://localhost:${DYMENSION_PORT}657
dymd init $MONIKER --chain-id dymension_1100-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
curl -Ls https://snapshots.kjnodes.com/dymension/genesis.json > $HOME/.dymension/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/dymension/addrbook.json > $HOME/.dymension/config/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="d9bfa29e0cf9c4ce0cc9c26d98e5d97228f93b0b@dymension.rpc.kjnodes.com:14656"
PEERS="6f2f8e1941d0a0b5981e980564172966f49207b9@46.4.32.57:36656,c9d7403a4d97c4b8e3660e24606ea44d20561878@159.69.95.88:26652,c76a0c2650c24d569448e6c94afd0775208af8e1@95.217.140.237:20556,4e9d335af4bcc44422ed38d436d2742441dbd955@54.169.78.250:26656,ebbc4b053809c3b9bd597651cb641c74bd625927@160.202.128.199:55696,7d1c3be5cc42d8c5d05080fb716539eab906ce78@65.109.37.154:4000,0f86f6a7c75ad7e940dc4c995fcfca28de34e408@38.91.107.37:26656,c600039ef70040740ae130d455768c509d173b12@85.10.200.232:23836,67a91d3e8266b46ce9418f1d6521352ebbd2c41b@162.19.233.18:26656,15a4ce392dcf6da6a2357c0b5e199766cf3a060b@164.152.161.131:26656,672ccb1ecdacea0001ca37391ce4aab5a935926c@51.81.109.116:26656,634bbd8bd0648b26ac8d71bc7b3ae984bc3b3787@168.119.141.105:24656,e7c9dabe155b56a2c1eddcfcdc68843abeb5ee97@162.19.83.220:26656,a413834999fa34ae17d6a32a36017bceb68783ca@78.46.65.144:29656,27edb41abfb28796a4b843f73560fa0b25006fca@141.95.97.21:56656,9f8c77d92b5b7f708eb3b2cab13f68edb5cf5c13@5.9.89.67:15672,a09e360944ca04ffb481e4500580a3a0eebf2684@51.210.214.120:26656,1f8add673d31c3da191d21758edd4ec672f21e8e@46.4.88.26:26656,e949e2ea40eb235028a78210ce8860b3d2a5ff46@23.146.184.206:7656,d787bf79e17f8841ced9a5fb6956dc2ae25c2fb7@135.181.220.61:33656,edb138287280478a4723d7d42021f72b40896857@51.91.66.96:26656,6ab867e5a295dd9a7e4a51643bd77dbf9eda1b8d@206.116.105.75:26656,a1171ca983c290b58a20d5fd665db36e800802be@213.168.227.52:26656,cb973c899ca82bd50ba8c64377988ba32e911dbc@142.132.248.34:20556,7bb0e1d32097ffa7118d9bd84d15f7847637c662@169.155.168.185:26656,fad88f79f3c2b8e0b29ff70b3a8bd04381cb073c@65.108.75.107:40659,bbe01309a3d0cbf0a52ec2fd8768b114ef36b6d1@35.76.185.2:26656,d9bfa29e0cf9c4ce0cc9c26d98e5d97228f93b0b@65.108.233.103:14656,b884dbc6e57dd06cc36f231a869ed1dbeaabdfab@65.109.104.223:45639"
sed -i -e "/^$p2p$/,/^$/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^$p2p$/,/^$/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
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
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "20000000000adym"|g' $HOME/.dymension/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.dymension/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.dymension/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/dymd.service > /dev/null <<EOF
[Unit]
Description=dymension.service
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
if curl -s --head curl https://snapshots.kjnodes.com/dymension/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.kjnodes.com/dymension/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.dymension
else
  echo "no snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable dymd.service
sudo systemctl restart dymd

# Monitor logs and check for errors
echo -e "\e[32mNetwork setup complete. Synchronization is pending.\e[0m" && sleep 1
