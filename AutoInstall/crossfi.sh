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
echo "export CROSSFI_CHAIN_ID="crossfi-mainnet-1"" >> $HOME/.bash_profile
echo "export CROSSFI_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$CROSSFI_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$CROSSFI_PORT\e[0m"
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

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
rm -rf bin
wget https://github.com/crossfichain/crossfi-node/releases/download/v0.3.0/crossfi-node_0.3.0_linux_amd64.tar.gz && tar -xf crossfi-node_0.3.0_linux_amd64.tar.gz
rm crossfi-node_0.3.0_linux_amd64.tar.gz
mv $HOME/bin/crossfid $HOME/go/bin/crossfid

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
rm -rf testnet ~/.mineplex-chain
git clone https://github.com/crossfichain/mainnet.git
mv $HOME/mainnet/ $HOME/.crossfid/
sed -i '99,114 s/^\( *enable =\).*/\1 "false"/' $HOME/.crossfid/config/config.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.crossfid/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/crossfi/genesis.json
wget -O $HOME/.crossfid/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/crossfi/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="693d9fe729d41ade244717176ab1415b2c06cf86@crossfi-mainnet-seed.itrocket.net:48656"
PEERS="641157ecbfec8e0ec37ca4c411c1208ca1327154@crossfi-mainnet-peer.itrocket.net:11656,9dd9a718a70c17eda4a2f2e262a6fcdafa380b04@95.217.45.201:23656,c482ab7bb52202149477fded22d6741d746d7e45@95.217.204.58:26056,d996012096cfef860bf24543740d58da45e5b194@37.27.183.62:26656,6b90dd8399533bca9066030f6193dca37f1565e1@65.109.234.80:26656,adb475675d97a9ce67bcea8cfdd66f23b92f1162@89.110.91.158:26656,9c8bf508ead86588f41ecc76cc6021c88493c199@57.129.32.223:26656,f27eff68f2f3542a317bad66fdf9f1cc93a80dc1@49.13.76.170:26656,f8cbc62fb487ae825edf79c580206d0e34ee9f51@5.161.229.160:26656,90fd2ad4f2b57bf6fa0c40cd579310f5ceebf0f5@5.78.128.70:26656,f5d2b1a6ab68ac9357366afe424564ab42a9d444@185.107.82.171:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.crossfid/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${CROSSFI_PORT}317%g;
s%:8080%:${CROSSFI_PORT}080%g;
s%:9090%:${CROSSFI_PORT}090%g;
s%:9091%:${CROSSFI_PORT}091%g;
s%:8545%:${CROSSFI_PORT}545%g;
s%:8546%:${CROSSFI_PORT}546%g;
s%:6065%:${CROSSFI_PORT}065%g" $HOME/.crossfid/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${CROSSFI_PORT}658%g;
s%:26657%:${CROSSFI_PORT}657%g;
s%:6060%:${CROSSFI_PORT}060%g;
s%:26656%:${CROSSFI_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CROSSFI_PORT}656\"%;
s%:26660%:${CROSSFI_PORT}660%g" $HOME/.crossfid/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.crossfid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.crossfid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.crossfid/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "10000000000000mpx"|g' $HOME/.crossfid/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.crossfid/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.crossfid/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/crossfid.service > /dev/null <<EOF
[Unit]
Description=crossfi node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.crossfid
ExecStart=$(which crossfid) start --home $HOME/.crossfid
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
crossfid tendermint unsafe-reset-all --home $HOME/.crossfid
BASE_URL="https://server-3.itrocket.net/mainnet/crossfi/"
LATEST_SNAPSHOT=$(curl -s $BASE_URL | grep -oP 'crossfi_\d+\.tar\.lz4' | sort -V | tail -n 1)

if [ -n "$LATEST_SNAPSHOT" ]; then
  FULL_URL="${BASE_URL}${LATEST_SNAPSHOT}"
  if curl -s --head "$FULL_URL" | head -n 1 | grep "200" > /dev/null; then
    curl "$FULL_URL" | lz4 -dc - | tar -xf - -C $HOME/.crossfid
  else
    echo "Snapshot URL is not valid."
  fi
else
  echo "No snapshot found."
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable crossfid
sudo systemctl restart crossfid && sudo journalctl -u crossfid -f
