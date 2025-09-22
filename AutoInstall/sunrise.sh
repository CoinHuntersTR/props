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
echo "export SUNRISE_CHAIN_ID="sunrise-1"" >> $HOME/.bash_profile
echo "export SUNRISE_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$SUNRISE_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$SUNRISE_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.24.5"
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
wget -O sunrised https://github.com/sunriselayer/sunrise/releases/download/v1.1.0/sunrised-linux-amd64
chmod +x $HOME/sunrised
sudo mv $HOME/sunrised /usr/local/bin/sunrised

# Verify installation
if command -v sunrised &> /dev/null; then
    echo "sunrised successfully installed"
    sunrised version
else
    echo "Error: sunrised installation failed"
    exit 1
fi

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
sunrised init $MONIKER --chain-id $SUNRISE_CHAIN_ID
sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  $HOME/.sunrise/config/config.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.sunrise/config/genesis.json https://ss.sunrise.nodestake.org/genesis.json
wget -O $HOME/.sunrise/config/addrbook.json https://ss.sunrise.nodestake.org/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="0c0e0cf617c1c58297f53f3a82cea86a7c860396@a.sunrise-test-1.cauchye.net:26656,db223ecc4fba0e7135ba782c0fd710580c5213a6@a-node.sunrise-test-1.cauchye.net:26656,82bc2fdbfc735b1406b9da4181036ab9c44b63be@b-node.sunrise-test-1.cauchye.net:26656,327fb4151de9f78f29ff10714085e347a4e3c836@rpc.sunrise.nodestake.org:666"
PEERS="34447c658f69fa1bc56125e991c207da1efbf137@65.109.59.22:28356,34e39405f02872a4a9403f241066cf0875a66ce2@65.108.7.249:28356,045eedb6b5d36056dc779e484e8a7e53750c22fa@65.109.122.90:28656,2404dca4d4b0831e69dd010539f0c391bcd0523a@95.217.128.50:26656,e776df4c573785a3416da430fb9c90be72ea795e@23.129.20.120:28356,7db7f656d36c420f39a8eab76c50c41cff440fa9@65.109.58.158:28356,2d712853b8aeca55161a71f1f5ca8bb27cc499d2@38.146.3.231:28356,bb69adc6246d31899055c2da852ef5c3fd5bbfe3@51.195.60.23:28356,f82a5e12227f6703a614263d61f0f88486ea7f98@51.68.248.230:26656,8b13908c44911f9797798e951557c17ef2490ee8@95.217.203.185:26656,2a30964e07118a0cb03bb1cae9185d37a967230a@207.148.68.35:26656,2494005ba072167d29e6f55a9b378a781872a49e@65.109.145.247:26656,13c1a5edd2e09c8ec3998fdc2c8ede330c6224bf@65.108.204.225:28356,60a83f51c20d39b7e69594f538513a80521eb0e8@45.32.30.169:26656,49be16d94c586f3ebd15f7cc7174d56765043b11@64.185.226.202:28356,366ef5ffeb16a2d8f018f483bf163bf75563d556@94.130.35.120:19656,401d10017915a9f217cb7e9ae9c888556c81e6da@65.108.230.75:18656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.sunrise/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${SUNRISE_PORT}317%g;
s%:8080%:${SUNRISE_PORT}080%g;
s%:9090%:${SUNRISE_PORT}090%g;
s%:9091%:${SUNRISE_PORT}091%g;
s%:8545%:${SUNRISE_PORT}545%g;
s%:8546%:${SUNRISE_PORT}546%g;
s%:6065%:${SUNRISE_PORT}065%g" $HOME/.sunrise/config/app.toml

# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${SUNRISE_PORT}658%g;
s%:26657%:${SUNRISE_PORT}657%g;
s%:6060%:${SUNRISE_PORT}060%g;
s%:26656%:${SUNRISE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${SUNRISE_PORT}656\"%;
s%:26660%:${SUNRISE_PORT}660%g" $HOME/.sunrise/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.sunrise/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.sunrise/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.sunrise/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.002urise"|g' $HOME/.sunrise/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.sunrise/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.sunrise/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/sunrised.service > /dev/null <<EOF
[Unit]
Description=sunrise node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.sunrise
ExecStart=$(which sunrised) start --home $HOME/.sunrise
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
sunrised tendermint unsafe-reset-all --home $HOME/.sunrise
if curl -s --head https://ss.sunrise.nodestake.org/2025-09-22_sunrise_753073.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://ss.sunrise.nodestake.org/2025-09-22_sunrise_753073.tar.lz4 | lz4 -d | tar -x -C $HOME/.sunrise
else
  echo "no snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable sunrised
sudo systemctl restart sunrised && sudo journalctl -u sunrised -fo cat
