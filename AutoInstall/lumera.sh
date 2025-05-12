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
echo "export LUMERA_CHAIN_ID="lumera-testnet-1"" >> $HOME/.bash_profile
echo "export LUMERA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$LUMERA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$LUMERA_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go
cd $HOME
rm -rf $HOME/go
sudo rm -rf /usr/local/go
VER="1.23.5"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export GOROOT=/usr/local/go" >> ~/.bash_profile
echo "export GOPATH=$HOME/go" >> ~/.bash_profile
echo "export GO111MODULE=on" >> ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/refs/heads/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
wget https://github.com/LumeraProtocol/lumera/releases/download/v0.4.1/lumera_v0.4.1_linux_amd64.tar.gz
tar -xvf lumera_v0.4.1_linux_amd64.tar.gz
rm lumera_v0.4.1_linux_amd64.tar.gz
rm -f install.sh
sudo mv libwasmvm.x86_64.so /usr/lib/
chmod +x lumerad
mv lumerad $HOME/go/bin/
lumerad version

printGreen "5. Configuring and init app..." && sleep 1
# init app
lumerad init $MONIKER --chain-id $LUMERA_CHAIN_ID
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${LUMERA_PORT}657\"|" $HOME/.lumera/config/client.toml
sed -i -e "s|^keyring-backend *=.*|keyring-backend = \"os\"|" $HOME/.lumera/config/client.toml
sed -i -e "s|^chain-id *=.*|chain-id = \"lumera-testnet-1\"|" $HOME/.lumera/config/client.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
curl -Ls https://ss-t.lumera.nodestake.org/genesis.json > $HOME/.lumera/config/genesis.json 
curl -Ls https://ss-t.lumera.nodestake.org/addrbook.json > $HOME/.lumera/config/addrbook.json
sleep 1
echo done

printGreen "7. Configuring custom ports, pruning, minimum gas price..." && sleep 1
# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${LUMERA_PORT}317%g;
s%:8080%:${LUMERA_PORT}080%g;
s%:9090%:${LUMERA_PORT}090%g;
s%:9091%:${LUMERA_PORT}091%g;
s%:8545%:${LUMERA_PORT}545%g;
s%:8546%:${LUMERA_PORT}546%g;
s%:6065%:${LUMERA_PORT}065%g" $HOME/.lumera/config/app.toml

# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${LUMERA_PORT}658%g;
s%:26657%:${LUMERA_PORT}657%g;
s%:6060%:${LUMERA_PORT}060%g;
s%:26656%:${LUMERA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${LUMERA_PORT}656\"%;
s%:26660%:${LUMERA_PORT}660%g" $HOME/.lumera/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.lumera/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.lumera/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.lumera/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.00001ulura"|g' $HOME/.lumera/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.lumera/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.lumera/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/lumerad.service > /dev/null <<EOF
[Unit]
Description=lumerad Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which lumerad) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
lumerad tendermint unsafe-reset-all --home $HOME/.lumera

# Automatically find the latest snapshot
SNAP_NAME=$(curl -s https://ss-t.lumera.nodestake.org/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
if [ -n "$SNAP_NAME" ]; then
  echo "Downloading latest snapshot: $SNAP_NAME"
  curl -o - -L https://ss-t.lumera.nodestake.org/${SNAP_NAME} | lz4 -c -d - | tar -x -C $HOME/.lumera
else
  echo "No snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable lumerad
sudo systemctl restart lumerad && sudo journalctl -u lumerad -f
