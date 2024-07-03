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
echo "export SUNRISE_CHAIN_ID="sunrise-test-1"" >> $HOME/.bash_profile
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
git clone https://github.com/sunriselayer/sunrise.git 
cd sunrise 
git checkout v0.0.8
make install

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
wget -O $HOME/.sunrise/config/genesis.json https://snapshots.polkachu.com/testnet-genesis/sunrise/genesis.json
wget -O $HOME/.sunrise/config/addrbook.json https://snapshots.polkachu.com/testnet-addrbook/sunrise/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:28356"
PEERS="513363c604e7d40400c790ce8080d7740043ad5a@95.217.193.182:26656,7158ed4aef068458755d358c998215c85b71629b@188.40.66.173:28356,8f80802f7d2d9daea07e3735ccd43434a299ece7@128.140.125.250:26656,72c6f84cd821cd570f8da67b36d9618f62e0e231@160.202.128.199:56326,e7cb7babc5d26f8494d3033320ee4879c134eff9@144.217.68.182:24356,5387ae41a200c28404548b6da4215e171fe9cab5@141.95.100.132:26656,b53fec5f6a2b17397535654833fe4183b503997c@34.143.188.112:26656,120b994a9de2edca8d2c5631ee77cc63f9fd622a@3.1.6.122:26656,f252bb8e6108b386f5f5b19188f4859896679abc@103.164.81.211:26656,e0cc95566295a62c84de4d762e02b6f13f53b910@54.174.27.95:26656,5a0b620c2e9fd57a52c4d57e6d15777dcbf8ab3a@38.242.238.248:26656,6935f7986619a6f0cbd6a31ae4f49610913a2274@15.235.55.158:26656,5c2a752c9b1952dbed075c56c600c3a79b58c395@195.3.220.140:27566,0fd113bbb7607e3f67706b4783c19a13f09b578c@65.21.47.120:29656,50ba4d02206b5efe28a83116fe750e6a1980cae1@62.195.206.235:26656,e0872e23f8f4533b1d4b5ec047c0c7265e2bef24@113.43.234.98:26556,ae6aabc5e68630835cbc595271cd26b81b36c907@141.94.143.203:56326"
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
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.sunrise/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.sunrise/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0ulava"|g' $HOME/.sunrise/config/app.toml
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
if curl -s --head curl https://snapshots.polkachu.com/testnet-snapshots/sunrise/sunrise_432248.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/testnet-snapshots/sunrise/sunrise_432248.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.sunrise
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable sunrised
sudo systemctl restart sunrised && sudo journalctl -u sunrised -f
