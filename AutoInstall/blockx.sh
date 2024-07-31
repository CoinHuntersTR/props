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
echo "export BLOCKX_CHAIN_ID="blockx_19191-1"" >> $HOME/.bash_profile
echo "export BLOCKX_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$BLOCKX_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$BLOCKX_PORT\e[0m"
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

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
rm -rf networks
git clone https://github.com/BlockXLabs/networks
cd ~/networks/chains/blockx_100-1/source
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
blockxd config node tcp://localhost:${BLOCKX_PORT}657
blockxd config keyring-backend os
blockxd config chain-id blockx_19191-1
blockxd init $MONIKER --chain-id blockx_19191-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.blockxd/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/blockx/genesis.json
wget -O $HOME/.blockxd/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/main/blockx/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="4452d0be36c123b971c2b052c54b2645fd3122a9@blockx-mainnet-seed.itrocket.net:19656"
PEERS="7e1c5fc00878f2a632e7c1fca3a279dcbd2e3f3c@blockx-mainnet-peer.itrocket.net:12656,521e01316a7afc5e9ba7322abb1a4ad10a7487b0@167.71.208.139:26656,5611e502ae2aff6f8c7758f465ae5db82d12420b@95.216.43.190:26656,f34a55c5d97a4aebf64e3585da2cc978d66a31b7@195.3.221.249:31656,7c840ad1ec4b478086f0888359b0f74984d4cafa@5.9.87.231:60956,a96e1b3272af95dddbb8f23372e937620be7eddb@65.109.115.56:12256,42addaaa1673f96b899ced10cfea7f6ab7c3be8f@46.4.23.120:49656,9b84b33d44a880a520006ae9f75ef030b259cbaf@137.184.38.212:26656,a87803a02f759ed52bf69f8ed9da06e5e9493231@49.12.150.42:26706,479dfa1948f49b08810cd16bf6c2d3256ae85423@137.184.7.64:26656,01017f9378decdc8dcb594d3299c4b822b1c366d@65.109.115.100:27464,66fccb6e7953e644ae61f974464a3716318a3275@54.211.219.127:26656,f8562a8be9c923e5bbf9689949d0c838e14fc642@109.199.104.27:30656,96825befa1957764c74a5d13c275cbe6ff2b800c@158.220.99.47:49656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.blockxd/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${BLOCKX_PORT}317%g;
s%:8080%:${BLOCKX_PORT}080%g;
s%:9090%:${BLOCKX_PORT}090%g;
s%:9091%:${BLOCKX_PORT}091%g;
s%:8545%:${BLOCKX_PORT}545%g;
s%:8546%:${BLOCKX_PORT}546%g;
s%:6065%:${BLOCKX_PORT}065%g" $HOME/.blockxd/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${BLOCKX_PORT}658%g;
s%:26657%:${BLOCKX_PORT}657%g;
s%:6060%:${BLOCKX_PORT}060%g;
s%:26656%:${BLOCKX_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${BLOCKX_PORT}656\"%;
s%:26660%:${BLOCKX_PORT}660%g" $HOME/.blockxd/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.blockxd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.blockxd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.blockxd/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0abcx"|g' $HOME/.blockxd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.blockxd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.blockxd/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/blockxd.service > /dev/null <<EOF
[Unit]
Description=blockx node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.blockxd
ExecStart=$(which blockxd) start --home $HOME/.blockxd
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
blockxd tendermint unsafe-reset-all --home $HOME/.blockxd
if curl -s --head curl https://server-3.itrocket.net/mainnet/blockx/blockx_2024-07-31_9867130_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-3.itrocket.net/mainnet/blockx/blockx_2024-07-31_9867130_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.blockxd
    else
  echo "no snapshot founded"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable blockxd
sudo systemctl restart blockxd && sudo journalctl -u blockxd -f
