#!/bin/bash

# Load and print logo
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)
printLogo

# Step 1: Update and Upgrade VPS
printGreen "Updating and upgrading VPS..." && sleep 1
sudo apt update && sudo apt upgrade -y

# Step 2: Install Required Packages
printGreen "Installing required packages..." && sleep 1
sudo apt install -y wget curl lz4 jq

# Step 3: Install Go
printGreen "Installing Go..." && sleep 1
cd $HOME
ver="1.22.3"
wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

# Step 4: Download and Install Story-Geth Binary
printGreen "Downloading and installing Story-Geth binary..." && sleep 1
cd $HOME
wget -O geth geth https://github.com/piplabs/story-geth/releases/download/v0.11.0/geth-linux-amd64
chmod +x $HOME/geth
mv $HOME/geth ~/go/bin/
[ ! -d "$HOME/.story/story" ] && mkdir -p "$HOME/.story/story"
[ ! -d "$HOME/.story/geth" ] && mkdir -p "$HOME/.story/geth"


# Step 5: Download and Install Story Binary
# install Story
cd $HOME
rm -rf story
git clone https://github.com/piplabs/story
cd story
git checkout v0.13.0
go build -o story ./client 
mv $HOME/story/story $HOME/go/bin/

# Step 6: Initialize the odyssey Network Node
printGreen "Initializing odyssey network node..." && sleep 1
$HOME/go/bin/story init --network odyssey

# Step 7: Create and Configure systemd Service for Story-Geth
printGreen "Creating systemd service for Story-Geth..." && sleep 1
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=$HOME/go/bin/geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Step 8: Create and Configure systemd Service for Story
printGreen "Creating systemd service for Story..." && sleep 1
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=$HOME/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Step 9: Ask for Moniker and Update config.toml
printGreen "Please enter the moniker for your node (e.g., your node's name):" && sleep 1
read -r moniker

# Step 10: Update Ports in config.toml Based on User Input
printGreen "Please enter the starting port number (between 11 and 64). Default is 26:" && sleep 1
read -r start_port

# Default value check for port
if [ -z "$start_port" ]; then
  start_port=26
elif ! [[ "$start_port" =~ ^[0-9]+$ ]] || [ "$start_port" -lt 11 ] || [ "$start_port" -gt 64 ]; then
  printGreen "Invalid input. Please enter a number between 11 and 64."
  exit 1
fi

# Calculate new ports based on start_port
rpc_port=$((start_port * 1000 + 657))
p2p_port=$((start_port * 1000 + 656))
proxy_app_port=$((start_port * 1000 + 658))
prometheus_port=$((start_port * 1000 + 660))

# Update config.toml with new port values and moniker
config_path="/root/.story/story/config/config.toml"

# Update ports
sed -i "s|laddr = \"tcp://127.0.0.1:26657\"|laddr = \"tcp://127.0.0.1:$rpc_port\"|g" "$config_path"
sed -i "s|laddr = \"tcp://0.0.0.0:26656\"|laddr = \"tcp://0.0.0.0:$p2p_port\"|g" "$config_path"
sed -i "s|proxy_app = \"tcp://127.0.0.1:26658\"|proxy_app = \"tcp://127.0.0.1:$proxy_app_port\"|g" "$config_path"
sed -i "s|prometheus_listen_addr = \":26660\"|prometheus_listen_addr = \":$prometheus_port\"|g" "$config_path"

# Update moniker
sed -i "s|moniker = \"[^\"]*\"|moniker = \"$moniker\"|g" "$config_path"

printBlue "Configuration updated successfully in config.toml:" && sleep 1

printLine
echo -e "Moniker:        \e[1m\e[32m$moniker\e[0m"
echo -e "RPC Port:         \e[1m\e[32m$rpc_port\e[0m"
echo -e "P2P Port:       \e[1m\e[32m$p2p_port\e[0m"
echo -e "Proxy App Port:  \e[1m\e[32m$proxy_app_port\e[0m"
echo -e "Prometheus Port:  \e[1m\e[32m$prometheus_port\e[0m"
printLine
sleep 1


# Step 11: Update Persistent Peers in config.toml
printGreen "Fetching peers and updating persistent_peers in config.toml..." && sleep 1
URL="https://story-testnet-rpc.itrocket.net/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $CONFIG_PATH

echo "Persistent peers updated in $CONFIG_PATH."


# Step 12: Reload systemd, Enable, and Start Services
printGreen "Reloading systemd, enabling, and starting Story-Geth and Story services..." && sleep 1
sudo systemctl daemon-reload
sudo systemctl enable story-geth story
sudo systemctl start story-geth story

printGreen "Installation and setup complete!" && sleep 1
