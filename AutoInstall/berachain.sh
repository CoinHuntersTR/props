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
echo "export BERA_CHAIN_ID="bartio-beacon-80084"" >> $HOME/.bash_profile
echo "export BERA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$BERA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$BERA_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.5"
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
wget -O beacond-v0.2.0-alpha.4-linux-amd64.tar.gz https://github.com/berachain/beacon-kit/releases/download/v0.2.0-alpha.4/beacond-v0.2.0-alpha.4-linux-amd64.tar.gz
tar -xzf beacond-v0.2.0-alpha.4-linux-amd64.tar.gz -C $HOME
chmod +x beacond-v0.2.0-alpha.4-linux-amd64.tar.gz
mv $HOME/beacond-v0.2.0-alpha.4-linux-amd64.tar.gz $HOME/go/bin/beacond

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
beacond init $MONIKER --chain-id $BERA_CHAIN_ID
sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  $HOME/.beacond/config/config.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.beacond/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/berachainv2/genesis.json
wget -O $HOME/.beacond/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/berachainv2/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="2f8ce8462cddc9ae865ab8ec1f05cc286f07c671@34.152.0.40:26656,3037b09eaa2eed5cd1b1d3d733ab8468bf4910ee@35.203.36.128:26656,add35d414bee9c0be3b10bcf8fbc12a059eb9a3b@35.246.180.53:26656,925221ce669017eb2fd386bc134f13c03c5471d4@34.159.151.132:26656,ae50b817fcb2f35da803aa0190a5e37f4f8bcdb5@34.64.62.166:26656,773b940b33dab98963486f0e5cbfc5ca8fc688b0@34.47.91.211:26656,977edf20575a0fc1d70fca035e5e53a02be80d9a@35.240.177.67:26656,5956d13b5285896a5c703ef6a6b28bf815f7bb22@34.124.148.177:26656"
PEERS="0c36dc6465dcda194103c7a66e18f3445d0c3a42@37.27.134.61:26656,8a0fbd4a06050519b6bce88c03932bd0a57060bd@139.84.172.174:26656,eb664944db9b97451b19400eede970706bd3724f@101.44.34.35:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.beacond/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${BERA_PORT}317%g;
s%:8080%:${BERA_PORT}080%g;
s%:9090%:${BERA_PORT}090%g;
s%:9091%:${BERA_PORT}091%g;
s%:8545%:${BERA_PORT}545%g;
s%:8546%:${BERA_PORT}546%g;
s%:6065%:${BERA_PORT}065%g" $HOME/.beacond/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${BERA_PORT}658%g;
s%:26657%:${BERA_PORT}657%g;
s%:6060%:${BERA_PORT}060%g;
s%:26656%:${BERA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${BERA_PORT}656\"%;
s%:26660%:${BERA_PORT}660%g" $HOME/.beacond/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.beacond/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.beacond/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.beacond/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0abgt"|g' $HOME/.beacond/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.beacond/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.beacond/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/beacond.service > /dev/null <<EOF
[Unit]
Description=beacon node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.beacond
ExecStart=$(which beacond) start --home $HOME/.beacond
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
beacond tendermint unsafe-reset-all --home $HOME/.beacond
if curl -s --head https://services.staketab.org/beacon-testnet/bartio-beacon-80084_2024-08-11.tar | head -n 1 | grep "200" > /dev/null; then
  curl https://services.staketab.org/beacon-testnet/bartio-beacon-80084_2024-08-11.tar | tar -xf - -C $HOME/.beacond
else
  echo "no snapshot founded"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable beacond
sudo systemctl restart beacond && sudo journalctl -u beacond -f
