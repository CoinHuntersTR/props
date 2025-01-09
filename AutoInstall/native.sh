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
echo "export NATIVE_CHAIN_ID="native-t1"" >> $HOME/.bash_profile
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
VER="1.23.1"
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
wget -O gonative-v0.1.1-linux-amd64.gz https://github.com/gonative-cc/gonative/releases/download/v0.1.1/gonative-v0.1.1-linux-amd64.gz
gunzip gonative-v0.1.1-linux-amd64.gz
mv gonative-v0.1.1-linux-amd64 gonative
chmod +x gonative
mv gonative $HOME/go/bin/
echo "export PATH=$PATH:$HOME/go/bin" >> ~/.bashrc
source ~/.bashrc

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
gonative config set client keyring-backend os
gonative config set client chain-id $NATIVE_CHAIN_ID
gonative init $MONIKER --chain-id $NATIVE_CHAIN_ID
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.gonative/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/native/genesis.json
wget -O $HOME/.gonative/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/native/addrbook.json
sleep 1
echo done

printGreen "7. Setting up config files..." && sleep 1
# Set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:30656"
PEERS="612e6279e528c3fadfe0bb9916fd5532bc9be2cd@164.132.247.253:56406,d0e0d80be68cec942ad46b36419f0ba76d35d134@94.130.138.41:26444,2e2f0def6453e67a5d5872da7f73002caf55a010@195.3.221.110:52656,a7577f50cdefd9a7a5e4a673278d9004df9b4bb4@103.219.169.97:56406,236946946eacbf6ab8a6f15c99dac1c80db6f8a5@65.108.203.61:52656,49784fe6a1b812fd45f4ac7e5cf953c2a3630cef@136.243.17.170:38656,be5b6092815df2e0b2c190b3deef8831159bb9a2@64.225.109.119:26656,d856c6c6f195b791c54c18407a8ad4391bd30b99@142.132.156.99:24096,b80d0042f7096759ae6aada870b52edf0dcd74af@65.109.58.158:26056,2dacf537748388df80a927f6af6c4b976b7274cb@148.251.44.42:26656,2c1e6b6b54daa7646339fa9abede159519ca7cae@37.252.186.248:26656,7567880ef17ce8488c55c3256c76809b37659cce@161.35.157.54:26656,fbc51b668eb84ae14d430a3db11a5d90fc30f318@65.108.13.154:52656,5be5b41a6aef28a7779002f2af0989c7a7da5cfe@165.154.245.110:26656,48d0fdcc642690ede0ad774f3ba4dce6e549b4db@142.132.215.124:26656,b5f52d67223c875947161ea9b3a95dbec30041cb@116.202.42.156:32107"

# Update config.toml
cat > $HOME/.gonative/config/config.toml << EOF
minimum-gas-prices = "0.08untiv"
pruning = "custom"
pruning-keep-recent = "100"
pruning-keep-every = "0"
pruning-interval = "50"
halt-height = 0
halt-time = 0
min-retain-blocks = 0
inter-block-cache = true
index-events = []

[telemetry]
enabled = true
prometheus-retention-time = 60

[api]
enable = true
swagger = true
address = "tcp://0.0.0.0:${NATIVE_PORT}317"
max-open-connections = 1000

[grpc]
enable = false
address = "0.0.0.0:${NATIVE_PORT}090"

[grpc-web]
enable = false
address = "0.0.0.0:${NATIVE_PORT}091"

[state-sync]
snapshot-interval = 0
snapshot-keep-recent = 2

[p2p]
laddr = "tcp://0.0.0.0:${NATIVE_PORT}656"
external-address = "$(wget -qO- eth0.me):${NATIVE_PORT}656"
seeds = "${SEEDS}"
persistent-peers = "${PEERS}"
max-num-inbound-peers = 50
max-num-outbound-peers = 50
max-connections = 100
handshake-timeout = "20s"
dial-timeout = "3s"

[mempool]
size = 5000
max-tx-bytes = 1048576
max-batch-bytes = 0

[consensus]
wal-file = "data/cs.wal/wal"
timeout-propose = "2s"
timeout-propose-delta = "500ms"
timeout-prevote = "1s"
timeout-prevote-delta = "500ms"
timeout-precommit = "1s"
timeout-precommit-delta = "500ms"
timeout-commit = "3s"
skip-timeout-commit = false
create-empty-blocks = true
create-empty-blocks-interval = "0s"
peer-gossip-sleep-duration = "100ms"
peer-query-maj23-sleep-duration = "2s"
EOF

# Update app.toml
cat > $HOME/.gonative/config/app.toml << EOF
minimum-gas-prices = "0.08untiv"
pruning = "custom"
pruning-keep-recent = "100"
pruning-keep-every = "0"
pruning-interval = "50"
halt-height = 0
halt-time = 0

[telemetry]
enabled = true
prometheus-retention-time = 60

[api]
enable = true
swagger = true
address = "tcp://0.0.0.0:${NATIVE_PORT}317"
max-open-connections = 1000

[grpc]
enable = false
address = "0.0.0.0:${NATIVE_PORT}090"

[state-sync]
snapshot-interval = 0
snapshot-keep-recent = 2
EOF

sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/gonatived.service > /dev/null <<EOF
[Unit]
Description=gonative node
After=network-online.target

[Service]
User=$USER
ExecStart=$(which gonative) start
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
gonative comet unsafe-reset-all --home $HOME/.gonative
if curl -s --head curl https://snapshots-testnet.stake-town.com/native/native-t1_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots-testnet.stake-town.com/native/native-t1_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.gonative
    else
  echo "no snapshot founded"
fi

# Configure firewall
sudo apt update
sudo apt install ufw -y
sudo ufw allow ${NATIVE_PORT}656
sudo ufw allow ${NATIVE_PORT}657
sudo ufw allow ${NATIVE_PORT}660
sudo ufw allow ${NATIVE_PORT}090
sudo ufw allow ${NATIVE_PORT}091
sudo ufw enable

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable gonatived
sudo systemctl restart gonatived && sudo journalctl -fu gonatived -o cat
