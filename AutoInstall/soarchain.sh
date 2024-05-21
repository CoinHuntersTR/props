#!/bin/bash

# Prompt the user to enter the node name
read -p "Enter your node name: " NODE_NAME

# Update system and install build tools
sudo apt update
sudo apt-get install git curl build-essential make jq gcc snapd chrony lz4 tmux unzip bc -y

# Install Go
rm -rf $HOME/go
sudo rm -rf /usr/local/go
cd $HOME
curl https://dl.google.com/go/go1.20.5.linux-amd64.tar.gz | sudo tar -C /usr/local -zxvf -
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.profile
go version

# Install Node
cd $HOME
mkdir -p $HOME/go/bin/
wget https://ss-t.soarchain.nodestake.org/soarchaind
chmod +x soarchaind
mv soarchaind $HOME/go/bin/
soarchaind version

# Initialize Node
soarchaind init $NODE_NAME --chain-id=soarchaintestnet

# Download Genesis
curl -Ls https://ss-t.soarchain.nodestake.org/genesis.json > $HOME/.soarchaind/config/genesis.json

# Download addrbook
curl -Ls https://ss-t.soarchain.nodestake.org/addrbook.json > $HOME/.soarchaind/config/addrbook.json

# Create Service
sudo tee /etc/systemd/system/soarchaind.service > /dev/null <<EOF
[Unit]
Description=soarchaind Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which soarchaind) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable soarchaind

# Download Snapshot (optional)
SNAP_NAME=$(curl -s https://ss-t.soarchain.nodestake.org/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
curl -o - -L https://ss-t.soarchain.nodestake.top/${SNAP_NAME} | lz4 -c -d - | tar -x -C $HOME/.soarchaind

# Launch Node
sudo systemctl restart soarchaind
journalctl -u soarchaind -f
