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
echo "export XRPL_CHAIN_ID="xrplevm_1449000-1"" >> $HOME/.bash_profile
echo "export XRPL_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$XRPL_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$XRPL_PORT\e[0m"
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
rm -rf xrp
git clone https://github.com/xrplevm/node.git
cd node
git checkout v7.0.0
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
exrpd config set client chain-id $XRPL_CHAIN_ID
exrpd init $MONIKER --chain-id $XRPL_CHAIN_ID
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${XRPL_PORT}657\"|" $HOME/.exrpd/config/client.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.exrpd/config/genesis.json https://server-1.itrocket.net/testnet/xrplevm/genesis.json
wget -O $HOME/.exrpd/config/addrbook.json  https://server-1.itrocket.net/testnet/xrplevm/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="6a271a9b7d07393a1521b1c7386a9fa9147a1762@xrplevm-testnet-seed.itrocket.net:16656"
PEERS="166f7e48e1c756cc663fee5be96ab2bbdb4db970@xrplevm-testnet-peer.itrocket.net:13656,d3d73f64abb4e785fd7d4541013b2f7a0b284612@135.181.210.47:56656,edda2d19e6f124fb05a09490d8463670c1e4cdd9@65.109.58.214:26656,727b11452d568d6f09d6378ae1e2718311c288ad@152.53.228.219:26656,5998f89c7549ec10672bf16a4d5b90786e856393@195.3.223.73:22656,c451a651b8d513b3e2cd8724537a80481c8cfdfd@152.53.51.57:13656,a601123b671af68731b9137dac59ab3ca5f1ce29@195.3.223.78:22656,788ee1661ed6f87e19015d4884ab94c51bc36a5f@116.202.210.177:13656,ce425e9ae057c4d34e63284a124404eea7d7b942@95.214.55.184:23656,a4f2d903cebf5bc83fcb66fbda0af5cb922a6436@135.181.139.249:47656,ab41e5911826a692c08ced4d737e905ffb3a6c28@65.108.199.62:56656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.exrpd/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${XRPL_PORT}317%g;
s%:8080%:${XRPL_PORT}080%g;
s%:9090%:${XRPL_PORT}090%g;
s%:9091%:${XRPL_PORT}091%g;
s%:8545%:${XRPL_PORT}545%g;
s%:8546%:${XRPL_PORT}546%g;
s%:6065%:${XRPL_PORT}065%g" $HOME/.exrpd/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${XRPL_PORT}658%g;
s%:26657%:${XRPL_PORT}657%g;
s%:6060%:${XRPL_PORT}060%g;
s%:26656%:${XRPL_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${XRPL_PORT}656\"%;
s%:26660%:${XRPL_PORT}660%g" $HOME/.exrpd/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.exrpd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.exrpd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.exrpd/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0axrp"|g' $HOME/.exrpd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.exrpd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.exrpd/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/exrpd.service > /dev/null <<EOF
[Unit]
Description=xrplevm node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.exrpd
ExecStart=$(which exrpd) start --home $HOME/.exrpd
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
exrpd tendermint unsafe-reset-all --home $HOME/.exrpd
if curl -s --head curl https://server-1.itrocket.net/testnet/xrplevm/xrplevm_2025-04-13_842633_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-1.itrocket.net/testnet/xrplevm/xrplevm_2025-04-13_842633_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.exrpd
    else
  echo "no snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable exrpd
sudo systemctl restart exrpd && sudo journalctl -u exrpd -f
