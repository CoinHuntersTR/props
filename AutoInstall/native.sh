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
echo "export NATIVE_CHAIN_ID="sunrise-test-0.2"" >> $HOME/.bash_profile
echo "export NATIVE_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$NATIVE_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$NATIVE_PORT\e[0m"
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

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME 
rm -rf $HOME/gonative
git clone https://github.com/gonative-cc/gonative.git
cd $HOME/gonative 
git checkout v0.1.1
make build && mv $HOME/gonative/out/gonative $HOME/go/bin

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
gonative config set client keyring-backend os
gonative config set client chain-id native-t1
gonative init $MONIKER --chain-id $NATIVE_CHAIN_ID
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.gonative/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/native/genesis.json
wget -O $HOME/.gonative/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/native/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:30656"
PEERS="612e6279e528c3fadfe0bb9916fd5532bc9be2cd@164.132.247.253:56406,d0e0d80be68cec942ad46b36419f0ba76d35d134@94.130.138.41:26444,2e2f0def6453e67a5d5872da7f73002caf55a010@195.3.221.110:52656,a7577f50cdefd9a7a5e4a673278d9004df9b4bb4@103.219.169.97:56406,236946946eacbf6ab8a6f15c99dac1c80db6f8a5@65.108.203.61:52656,49784fe6a1b812fd45f4ac7e5cf953c2a3630cef@136.243.17.170:38656,be5b6092815df2e0b2c190b3deef8831159bb9a2@64.225.109.119:26656,d856c6c6f195b791c54c18407a8ad4391bd30b99@142.132.156.99:24096,b80d0042f7096759ae6aada870b52edf0dcd74af@65.109.58.158:26056,2dacf537748388df80a927f6af6c4b976b7274cb@148.251.44.42:26656,2c1e6b6b54daa7646339fa9abede159519ca7cae@37.252.186.248:26656,7567880ef17ce8488c55c3256c76809b37659cce@161.35.157.54:26656,fbc51b668eb84ae14d430a3db11a5d90fc30f318@65.108.13.154:52656,5be5b41a6aef28a7779002f2af0989c7a7da5cfe@165.154.245.110:26656,48d0fdcc642690ede0ad774f3ba4dce6e549b4db@142.132.215.124:26656,b5f52d67223c875947161ea9b3a95dbec30041cb@116.202.42.156:32107"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.gonative/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${NATIVE_PORT}317%g;
s%:8080%:${NATIVE_PORT}080%g;
s%:9090%:${NATIVE_PORT}090%g;
s%:9091%:${NATIVE_PORT}091%g;
s%:8545%:${NATIVE_PORT}545%g;
s%:8546%:${NATIVE_PORT}546%g;
s%:6065%:${NATIVE_PORT}065%g" $HOME/.gonative/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${NATIVE_PORT}658%g;
s%:26657%:${NATIVE_PORT}657%g;
s%:6060%:${NATIVE_PORT}060%g;
s%:26656%:${NATIVE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${NATIVE_PORT}656\"%;
s%:26660%:${NATIVE_PORT}660%g" $HOME/.gonative/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.gonative/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.gonative/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.gonative/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.08untiv"|g' $HOME/.gonative/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.gonative/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.gonative/config/config.toml
sleep 1
echo done

# Install cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0
mkdir -p ~/.gonative/cosmovisor/genesis/bin
mkdir -p ~/.gonative/cosmovisor/upgrades
cp ~/go/bin/gonative ~/.gonative/cosmovisor/genesis/bin

sudo tee /etc/systemd/system/gonatived.service > /dev/null << EOF
[Unit]
Description=Native Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=3
LimitNOFILE=10000
Environment="DAEMON_NAME=gonative"
Environment="DAEMON_HOME=$HOME/.gonative"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
[Install]
WantedBy=multi-user.target
EOF
printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
gonative tendermint unsafe-reset-all --home $HOME/.gonative
if curl -s --head curl https://snapshots-testnet.stake-town.com/native/native-t1_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots-testnet.stake-town.com/native/native-t1_latest.tar.lz4 | tar -xz -C $HOME/.gonative
    else
  echo "no snapshot founded"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable gonatived
sudo systemctl restart gonatived && sudo journalctl -fu gonatived -o cat
