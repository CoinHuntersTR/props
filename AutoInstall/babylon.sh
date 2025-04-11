#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

printLogo

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT
read -p "Enter your BLS password:" BLS_PASSWORD
echo 'export BLS_PASSWORD='$BLS_PASSWORD

# set vars
echo "export WALLET=\"$WALLET\"" >> $HOME/.bash_profile
echo "export MONIKER=\"$MONIKER\"" >> $HOME/.bash_profile
echo "export BABYLON_CHAIN_ID=\"bbn-1\"" >> $HOME/.bash_profile
echo "export BABYLON_PORT=\"$PORT\"" >> $HOME/.bash_profile
echo "export BABYLON_BLS_PASSWORD=\"$BLS_PASSWORD\"" >> $HOME/.bash_profile
source $HOME/.bash_profile

# Create BLS password file
echo "$BLS_PASSWORD" > $HOME/bls_password.txt

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$BABYLON_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$BABYLON_PORT\e[0m"
echo -e "BLS Password:   \e[1m\e[32mSaved\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.23.4"
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
git clone https://github.com/babylonlabs-io/babylon.git babylon
cd babylon
git checkout v1.0.1
make install
babylond version

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
babylond init $MONIKER --chain-id $BABYLON_CHAIN_ID --home $HOME/.babylond

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.babylond/config/genesis.json https://snapshots.polkachu.com/genesis/babylon/genesis.json
wget -O $HOME/.babylond/config/addrbook.json  https://snapshots.polkachu.com/addrbook/babylon/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="42fad8afbf7dfca51020c3c6e1a487ce17c4c218@babylon-seed-1.nodes.guru:55706,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:20656"
PEERS="f0d280c08608400cac0ccc3d64d67c63fabc8bcc@91.134.70.52:55706,4c1406cb6867232b7ea130ed3a3d25996ca06844@23.88.6.237:20656,b40a147910a608018c47a0e0225106d00d2651ed@5.9.99.42:20656,184db83783c9158a3e99809ffed3752e180597be@65.108.205.121:20656,1f06b55dfbae181fa40ec08fe145b3caef6d3c83@5.9.81.54:2080,7d728de314f9746e499034bfcfc5a9023c672df5@84.32.32.149:18800"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.babylond/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${BABYLON_PORT}317%g;
s%:8080%:${BABYLON_PORT}080%g;
s%:9090%:${BABYLON_PORT}090%g;
s%:9091%:${BABYLON_PORT}091%g;
s%:8545%:${BABYLON_PORT}545%g;
s%:8546%:${BABYLON_PORT}546%g;
s%:6065%:${BABYLON_PORT}065%g" $HOME/.babylond/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${BABYLON_PORT}658%g;
s%:26657%:${BABYLON_PORT}657%g;
s%:6060%:${BABYLON_PORT}060%g;
s%:26656%:${BABYLON_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${BABYLON_PORT}656\"%;
s%:26660%:${BABYLON_PORT}660%g" $HOME/.babylond/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.babylond/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.babylond/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.babylond/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.002ubbn"|g' $HOME/.babylond/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.babylond/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.babylond/config/config.toml

# set additional requested configurations for app.toml
sed -i '/\[mempool\]/,/\[/ s/^max-txs *=.*/max-txs = 0/' $HOME/.babylond/config/app.toml
# Add btc-config if it doesn't exist
if ! grep -q "\[btc-config\]" $HOME/.babylond/config/app.toml; then
  echo -e "\n[btc-config]\nnetwork = \"mainnet\"" >> $HOME/.babylond/config/app.toml
else
  sed -i '/\[btc-config\]/,/\[/ s/^network *=.*/network = "mainnet"/' $HOME/.babylond/config/app.toml
fi

# set timeout_commit in config.toml
sed -i '/\[consensus\]/,/\[/ s/^timeout_commit *=.*/timeout_commit = "9200ms"/' $HOME/.babylond/config/config.toml

sleep 1
echo done

# create service file with BLS password environment variable
sudo tee /etc/systemd/system/babylond.service > /dev/null <<EOF
[Unit]
Description=babylond.service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.babylond
Environment="BABYLON_BLS_PASSWORD=$BLS_PASSWORD"
ExecStart=$(which babylond) start --home $HOME/.babylond
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# Remove any existing BLS key to avoid decryption issues
if [ -f $HOME/.babylond/config/bls_key.json ]; then
  rm $HOME/.babylond/config/bls_key.json
  printGreen "Removed existing BLS key file to avoid decryption issues"
fi

# reset and download snapshot
babylond tendermint unsafe-reset-all --home $HOME/.babylond
if curl -s --head curl https://snapshots.polkachu.com/snapshots/babylon/babylon_26504.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/snapshots/babylon/babylon_26504.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.babylond
else
  echo "No snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable babylond
sudo systemctl restart babylond && sudo journalctl -u babylond -fo cat
