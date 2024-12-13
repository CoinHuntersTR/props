#!/bin/bash

# Load common functions
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

# Print logo
printLogo

# Prompt for user inputs
read -p "Enter WALLET name: " WALLET
echo "export WALLET=$WALLET"
read -p "Enter your MONIKER: " MONIKER
echo "export MONIKER=$MONIKER"
read -p "Enter your PORT (for example 17, default port=26): " PORT
PORT=${PORT:-26} # Default port is 26 if not provided
echo "export PORT=$PORT"

# Set environment variables
echo "export WALLET=$WALLET" >> $HOME/.bash_profile
echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile
echo "export PELL_CHAIN_ID=ignite_186-1" >> $HOME/.bash_profile
echo "export PELL_PORT=$PORT" >> $HOME/.bash_profile
source $HOME/.bash_profile

# Display configuration
printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$PELL_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$PELL_PORT\e[0m"
printLine
sleep 1

# Install Go
printGreen "1. Installing Go..." && sleep 1
cd $HOME
GO_VERSION="1.22.6"
wget "https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$GO_VERSION.linux-amd64.tar.gz"
rm "go$GO_VERSION.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

# Verify Go installation
if ! go version &>/dev/null; then
  echo "Go installation failed. Exiting..."
  exit 1
fi
echo $(go version) && sleep 1

# Install dependencies
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/refs/heads/main/dependencies_install.sh)

# Install binary
printGreen "4. Installing binary..." && sleep 1
cd $HOME
wget -O pellcored https://github.com/0xPellNetwork/network-config/releases/download/v1.0.20-ignite/pellcored-v1.0.20-linux-amd64
chmod +x $HOME/pellcored
mv $HOME/pellcored $HOME/go/bin/pellcored

WASMVM_VERSION="v2.1.2"
export LD_LIBRARY_PATH=$HOME/.pellcored/lib
mkdir -p $LD_LIBRARY_PATH
wget "https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so" -O "$LD_LIBRARY_PATH/libwasmvm.$(uname -m).so"
echo "export LD_LIBRARY_PATH=$HOME/.pellcored/lib:$LD_LIBRARY_PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile

# Configure and initialize app
printGreen "5. Configuring and initializing app..." && sleep 1
pellcored config node tcp://localhost:${PELL_PORT}657
pellcored config keyring-backend os
pellcored config chain-id ignite_186-1
pellcored init "$MONIKER" --chain-id $PELL_CHAIN_ID
sleep 1
echo "Initialization done."

# Download genesis and addrbook
printGreen "6. Downloading genesis and addrbook..." && sleep 1
wget -O $HOME/.pellcored/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/pellnetwork/genesis.json
wget -O $HOME/.pellcored/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/pellnetwork/addrbook.json
sleep 1
echo "Genesis and addrbook downloaded."

# Configure custom ports, seeds, peers, pruning, and gas price
printGreen "7. Configuring custom ports, seeds, peers, pruning, and gas price..." && sleep 1
SEEDS="5f10959cc96b5b7f9e08b9720d9a8530c3d08d19@pell-testnet-seed.itrocket.net:58656"
PEERS="d003cb808ae91bad032bb94d19c922fe094d8556@pell-testnet-peer.itrocket.net:58656,d52c32a6a8510bdf0d33909008041b96d95c8408@34.87.39.12:26656,28c0fcd184c31ac7f3e2b3a91ae60dedc086b0c3@94.130.204.227:26656,9b955d07f05b02b3d622f9cb7a0e6cfecd719985@34.87.47.193:26656,4efd5164f02c3af4247fc0292922af8d08a46ae6@51.89.1.16:26656,c9a5d341547e06441e30e07db289fc337ec36f79@152.53.87.97:26656,a07fb3b45241b774db25f0704a65419f0e98be14@62.171.130.196:26656,be843b3784f43fd3425e9111a6884d05002bc705@113.176.142.7:26656,103b755578215a240d2e70a4294643e35ecfd6fa@152.53.66.0:21656,f1049cc2be2902053bcf5ea1a553414d8a978ef6@[2a01:4f8:110:4265::11]:26656,9e1a9bb8de646165705eb6ec92f6812f6b899fc5@37.27.41.4:57656"
sed -i -e "/^$p2p$/,/^$/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^$p2p$/,/^$/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.pellcored/config/config.toml

# Set custom ports in app.toml
sed -i.bak -e "s%:1317%:${PELL_PORT}317%g;
s%:8080%:${PELL_PORT}080%g;
s%:9090%:${PELL_PORT}090%g;
s%:9091%:${PELL_PORT}091%g;
s%:8545%:${PELL_PORT}545%g;
s%:8546%:${PELL_PORT}546%g;
s%:6065%:${PELL_PORT}065%g" $HOME/.pellcored/config/app.toml

# Set custom ports in config.toml
sed -i.bak -e "s%:26658%:${PELL_PORT}658%g;
s%:26657%:${PELL_PORT}657%g;
s%:6060%:${PELL_PORT}060%g;
s%:26656%:${PELL_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${PELL_PORT}656\"%;
s%:26660%:${PELL_PORT}660%g" $HOME/.pellcored/config/config.toml

# Configure pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.pellcored/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.pellcored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.pellcored/config/app.toml

# Set minimum gas price, enable Prometheus, and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0apell"|g' $HOME/.pellcored/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.pellcored/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.pellcored/config/config.toml
sleep 1
echo "Configuration done."

# Download snapshot and start node
printGreen "8. Downloading snapshot and starting node..." && sleep 1
pellcored tendermint unsafe-reset-all --home $HOME/.pellcored
SNAPSHOT_URL="https://snapshots.coinhunterstr.com/testnet/pell/snapshot_latest.tar.lz4"
if curl -s --head $SNAPSHOT_URL | head -n 1 | grep "200" > /dev/null; then
  curl $SNAPSHOT_URL | lz4 -dc - | tar -xf - -C $HOME/.pellcored
else
  echo "No snapshot found."
fi

# Create systemd service file
sudo tee /etc/systemd/system/pellcored.service > /dev/null <<EOF
[Unit]
Description=Pell node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.pellcored
ExecStart=$(which pellcored) start --home $HOME/.pellcored
Environment=LD_LIBRARY_PATH=$HOME/.pellcored/lib/
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable pellcored
sudo systemctl restart pellcored && sudo journalctl -u pellcored -f
