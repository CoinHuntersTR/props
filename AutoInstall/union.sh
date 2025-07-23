#!/bin/bash

# Union Node Installation Script
# Moniker: CoinHunters

echo "Starting Union Node installation..."

# Update system and install required tools
echo "Updating system and installing required tools..."
sudo apt update
sudo apt-get install git curl build-essential make jq gcc snapd chrony lz4 tmux unzip bc -y

# Install Go
echo "Installing Go..."
cd $HOME
curl https://dl.google.com/go/go1.23.1.linux-amd64.tar.gz | sudo tar -C/usr/local -zxvf -

# Update environment variables
echo "Setting up Go environment variables..."
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF

source $HOME/.profile

# Check Go version
echo "Checking Go version..."
go version

# Install Union node
echo "Installing Union node..."
wget -O uniond https://support.synergynodes.com/misc/uniond
chmod +x uniond
mv uniond ~/go/bin/
uniond version

# Initialize the Node
echo "Initializing the node with moniker: CoinHunters..."
cd
mkdir $HOME/.union
uniond init CoinHunters --chain-id=union-testnet-10 --home $HOME/.union

# Download Genesis file
echo "Downloading Genesis file..."
curl -Ls https://support.synergynodes.com/genesis2/union_testnet/genesis.json > $HOME/.union/config/genesis.json

# Download Addrbook file
echo "Downloading Addrbook file..."
curl -Ls https://support.synergynodes.com/addrbook/union_testnet/addrbook.json > $HOME/.union/config/addrbook.json

# Add / Update Persistent Peers
echo "Adding persistent peers..."
PEERS=ea80b3d17264ddd25f0fe7b5b72b06a785be0be7@167.235.1.51:24656,57d817a99049c963e1adaed7735cbd1ce388e912@16.62.79.119:26656,651b3698131a9c32f46556846017ce013c5c2980@167.235.115.23:24656,232b01bad118d54cb6c50c2005252b4ed6a272b3@173.231.40.186:24656,2e4338eb94b6a04f5acd80d935f043be2a73a858@62.84.190.33:26676,3ca744ee6b3871cf45bb23a6ecefd9a11dcee294@62.84.190.37:26676,4b81ca0a131659f316cfb8f7c755b2ada3e276ea@157.90.170.177:26656,acee1549c9ba5d69228d054532a1d5864e12faac@31.220.75.27:26676,1c70431e4126fd793669b4313f914a256e489c50@51.91.116.146:36656,06de8a52cd5fcf6144d534129e3bc5b8ca2966b7@65.108.105.48:24656
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.union/config/config.toml

# Download & decompress Snapshot
echo "Downloading and decompressing snapshot..."
cd $HOME
sudo systemctl stop uniond 2>/dev/null || true
cp $HOME/.union/data/priv_validator_state.json $HOME/.union/priv_validator_state.json.backup 2>/dev/null || true
rm -rf $HOME/.union/data
wget -O union_testnet_2097968.tar.lz4 https://support.synergynodes.com/snapshots/union_testnet/union_testnet_2097968.tar.lz4
lz4 -c -d union_testnet_2097968.tar.lz4 | tar -x -C $HOME/.union
mv $HOME/.union/priv_validator_state.json.backup $HOME/.union/data/priv_validator_state.json 2>/dev/null || true

# Create Service File
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/uniond.service > /dev/null <<EOF
[Unit]
Description=uniond Daemon
After=network.target
StartLimitInterval=350
StartLimitBurst=10

[Service]
Type=simple
User=$USER
ExecStart=$HOME/go/bin/uniond start --home $HOME/.union
Restart=on-abort
RestartSec=30
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# Start the Node
echo "Starting the node..."
sudo systemctl daemon-reload
sudo systemctl enable uniond
sudo systemctl start uniond

echo "Union Node installation completed!"
echo "Moniker: CoinHunters"
echo "Chain ID: union-testnet-10"
echo ""
echo "To check logs, run: sudo journalctl -fu uniond"
echo "To check status, run: sudo systemctl status uniond"
