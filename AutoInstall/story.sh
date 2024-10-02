#!/bin/bash

# Define a function to print text in green
print_green() {
  echo -e "\033[0;32m\$1\033[0m"
}

# Load and print logo
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)
printLogo 

# Step 1: Update and Upgrade VPS
print_green "Updating and upgrading VPS..." && sleep 1
sudo apt update && sudo apt upgrade -y

# Step 2: Install Required Packages
print_green "Installing required packages..." && sleep 1
sudo apt install -y wget curl lz4 jq

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
ver="1.22.0"
wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

# Step 4: Download and Install Story-Geth Binary
print_green "Downloading and installing Story-Geth binary..." && sleep 1
wget -q https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz -O /tmp/geth-linux-amd64-0.9.3-b224fdf.tar.gz
tar -xzf /tmp/geth-linux-amd64-0.9.3-b224fdf.tar.gz -C /tmp
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
sudo cp /tmp/geth-linux-amd64-0.9.3-b224fdf/geth $HOME/go/bin/story-geth

# Step 5: Download and Install Story Binary
print_green "Downloading and installing Story binary..." && sleep 1
wget -q https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.10.1-57567e5.tar.gz -O /tmp/story-linux-amd64-0.10.1-57567e5.tar.gz
tar -xzf /tmp/story-linux-amd64-0.10.1-57567e5.tar.gz -C /tmp
sudo cp /tmp/story-linux-amd64-0.10.1-57567e5/story $HOME/go/bin/story

# Step 6: Initialize the Iliad Network Node
print_green "Initializing Iliad network node..." && sleep 1
$HOME/go/bin/story init --network iliad

# Step 7: Create and Configure systemd Service for Story-Geth
print_green "Creating systemd service for Story-Geth..." && sleep 1
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=$HOME/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Step 8: Create and Configure systemd Service for Story
print_green "Creating systemd service for Story..." && sleep 1
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
print_green "Please enter the moniker for your node (e.g., your node's name):" && sleep 1
read -r moniker

# Step 10: Update Ports in config.toml Based on User Input
print_green "Please enter the starting port number (between 11 and 64). Default is 26:" && sleep 1
read -r start_port

# Default value check for port
if [ -z "$start_port" ]; then
  start_port=26
elif ! [[ "$start_port" =~ ^[0-9]+$ ]] || [ "$start_port" -lt 11 ] || [ "$start_port" -gt 64 ]; then
  echo "Invalid input. Please enter a number between 11 and 64."
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

print_green "Configuration updated successfully in config.toml:"
print_green "Moniker: $moniker"
print_green "RPC Port: $rpc_port"
print_green "P2P Port: $p2p_port"
print_green "Proxy App Port: $proxy_app_port"
print_green "Prometheus Port: $prometheus_port"

# Step 11: Update Persistent Peers in config.toml
print_green "Fetching peers and updating persistent_peers in config.toml..." && sleep 1
URL="https://story-testnet-rpc.itrocket.net/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $CONFIG_PATH

print_green "Persistent peers updated in $CONFIG_PATH."

# Step 12: Reload systemd, Enable, and Start Services
print_green "Reloading systemd, enabling, and starting Story-Geth and Story services..." && sleep 1
sudo systemctl daemon-reload
sudo systemctl enable story-geth story
sudo systemctl start story-geth story
