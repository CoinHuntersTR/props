#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

# Flag for autosnap
from_autoinstall=true

upgrade_height=1751934608
STORY_CHAIN_ID=story
VER=1.22.3
SEEDS="c1d973eea1b2c637777ab32783b3d37f2b52ba36@b1.storyrpc.io:26656,78db197dbbffb97a5c851b87b1df4cc51e99d4f9@b2.storyrpc.io:26656"

# Function to install Story-Geth
install_geth() {
cd $HOME
wget https://github.com/piplabs/story-geth/releases/download/v1.1.0/geth-linux-arm64
sudo mv ./geth-linux-arm64 story-geth
sudo chmod +x story-geth
sudo mv ./story-geth $HOME/go/bin/story-geth
source $HOME/.bashrc
[ ! -d "$HOME/.story/story" ] && mkdir -p "$HOME/.story/story"
[ ! -d "$HOME/.story/geth" ] && mkdir -p "$HOME/.story/geth"
}

# Function to install Story
install_story() {
cd $HOME
wget https://github.com/piplabs/story/releases/download/v1.2.1/story-linux-arm64
sudo mv story-linux-arm64 story
sudo chmod +x story
sudo mv ./story $HOME/go/bin/story
source $HOME/.bashrc
}

# Function to automatically upgrade story
autoupgrade() {
cd $HOME && \
rm -rf story && \
git clone https://github.com/piplabs/story && \
cd story && \
git checkout v1.2.1 && \
go build -o story ./client  && \
sudo systemctl stop story-geth && \
wget -O $(which geth)  https://github.com/piplabs/story-geth/releases/download/v1.1.0/geth-linux-arm64 && \
chmod +x $(which geth) && \
sudo systemctl start story-geth && \
old_bin_path=$(which story) && \
home_path=$HOME && \
rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.story/story/config/config.toml" | cut -d ':' -f 3) && \
[[ -z "$rpc_port" ]] && rpc_port=$(grep -oP 'node = "tcp://[^:]+:\K\d+' "$HOME/.story/story/config/client.toml") ; \
tmux new -s story-upgrade "sudo bash -c 'curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/refs/heads/main/autoupgrade/upgrade.sh | bash -s -- -u \"1751934608\" -b story -n \"$HOME/story/story\" -o \"$old_bin_path\" -h \"$home_path\" -p \"undefined\" -r \"$rpc_port\"'"
}

# Function to prompt user to continue or exit
ask_to_continue() {
  read -p "$(printYellow 'Do you want to continue anyway? (y/n): ')" choice
  if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    break
  fi
}


# Function to check node sync status
check_sync_status() {
rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.story/story/config/config.toml" | cut -d ':' -f 3)
while true; do
  local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.latest_block_height')
  network_height=$(curl -s https://story-dev-rpc.coinhunterstr.com/status | jq -r '.result.sync_info.latest_block_height')

  if ! [[ "$local_height" =~ ^[0-9]+$ ]] || ! [[ "$network_height" =~ ^[0-9]+$ ]]; then
    echo -e "\033[1;31mError: Invalid block height data. Retrying...\033[0m"
    sleep 5
    continue
  fi

  blocks_left=$((network_height - local_height))
  if [ "$blocks_left" -lt 0 ]; then
    blocks_left=0
  fi

  echo -e "\033[1;33mYour Node Height:\033[1;34m $local_height\033[0m \033[1;33m| Network Height:\033[1;36m $network_height\033[0m \033[1;33m| Blocks Left:\033[1;31m $blocks_left\033[0m"

  sleep 5
  if [[ "$blocks_left" -eq 0 ]]; then
    printBlue "Your node is synced"
    break
  fi
done
}

# Function to define service file name
define_service_name() {
  service_name=$1
  print_name=$2
  systemctl status $service_name > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code -eq 4 ]]; then
    read -rp "Enter your $print_name service file name: " service_name
  fi
  echo $service_name
}

# Function to display the logs and trap CTRL+C
view_logs() {
  if [[ -z "$story_name" ]]; then
    story_name=$(define_service_name "story" "Story")
  fi
  if [[ -z "$geth_name" ]]; then
    geth_name=$(define_service_name "story-geth" "Story-geth")
  fi

  trap "return" SIGINT
  journalctl -u $story_name -u $geth_name -f
  trap - SIGINT
}

# Function to install node
install_node() {
  read -p "Enter your MONIKER: " MONIKER
  echo 'export MONIKER='$MONIKER
  read -p "Enter your PORT (for example 17, default port=26): " PORT
  echo 'export PORT='$PORT
  
  # set vars
  echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
  echo "export STORY_CHAIN_ID="$STORY_CHAIN_ID"" >> $HOME/.bash_profile
  echo "export STORY_PORT="$PORT"" >> $HOME/.bash_profile
  source $HOME/.bash_profile
  
  printLine
  echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
  echo -e "Chain id:       \e[1m\e[32m$STORY_CHAIN_ID\e[0m"
  echo -e "Node custom port:  \e[1m\e[32m$STORY_PORT\e[0m"
  printLine
  sleep 2
  
  printGreen "1. Installing go..." && sleep 1
  # install go, if needed
  cd $HOME
  wget "https://golang.org/dl/go$VER.linux-arm64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-arm64.tar.gz"
  rm "go$VER.linux-arm64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source $HOME/.bash_profile
  [ ! -d ~/go/bin ] && mkdir -p ~/go/bin
  
  echo $(go version) && sleep 1

  printLine
  printGreen "2. Updating packages..." && sleep 1
  sudo apt update && sudo apt upgrade -y
  sleep 1
  
  printLine
  printGreen "3. Installing dependencies..." && sleep 1
  sudo apt install -y aria2 bsdmainutils build-essential chrony clang curl gcc gh git htop jq libssl-dev liblz4-tool lz4 make ncdu pkg-config tar tmux unzip wget
  sleep 1
  
  printLine
  printGreen "4. Installing Story-geth..." && sleep 1
  install_geth
  sleep 1
  
  printLine
  printGreen "5. Installing Story..." && sleep 1
  install_story
  sleep 1
  
  printLine
  printGreen "6. Initializing Story app..." && sleep 1
  story init --network story --moniker $MONIKER
  sleep 1

  printLine
  printGreen "7. Downloading genesis and addrbook..." && sleep 1
  # download genesis and addrbook
  wget -O $HOME/.story/story/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/story/genesis.json
  wget -O $HOME/.story/story/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/story/addrbook.json
  sleep 1

  printLine
  printGreen "8. Adding seeds and peers, configuring custom ports..." && sleep 1
  # set seeds and peers
  sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
         -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
         $HOME/.story/story/config/config.toml
  
  # set custom ports in story.toml file
  sed -i.bak -e "s%localhost:1317%localhost:${STORY_PORT}317%g;
  s%localhost:8551%localhost:${STORY_PORT}551%g;
  s%:8551%:${STORY_PORT}551%g" $HOME/.story/story/config/story.toml
  
  # set custom ports in config.toml file
  sed -i.bak -e "s%:26658%:${STORY_PORT}658%g;
  s%:26657%:${STORY_PORT}657%g;
  s%:26656%:${STORY_PORT}656%g;
  s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${STORY_PORT}656\"%;
  s%:26660%:${STORY_PORT}660%g" $HOME/.story/story/config/config.toml
  
  # enable prometheus and disable indexing
  sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.story/story/config/config.toml
  sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.story/story/config/config.toml
  
  printBlue "done" && sleep 1
  echo ""

  printLine
  printGreen "9. Creating Story-geth and Story service files..." && sleep 1
# create geth servie file
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=$USER
Environment="STORY_PORT=$STORY_PORT"
ExecStart=/root/go/bin/story-geth --story --syncmode full --http.port \${STORY_PORT}551 --authrpc.port \${STORY_PORT}551
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# create story service file
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Node
After=network.target

[Service]
Type=simple
User=$USER
Environment="STORY_PORT=$STORY_PORT"
ExecStart=$(which story) run
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
  
  printBlue "done" && sleep 1
  echo ""

  printLine
  printGreen "10. Activating Story and Story-geth services..." && sleep 1
  sudo systemctl daemon-reload
  sudo systemctl enable story story-geth
  sudo systemctl start story-geth

  printBlue "done" && sleep 1
  echo ""
  
  printLine
  printGreen "11. Downloading snapshot..." && sleep 1
  echo ""
  printLine
  installation=true
  mkdir -p $HOME/.story/geth/odyssey/geth
  source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/AutoInstall/autosnap.sh)
}

state_sync() {
  cd $HOME
  printGreen "1. Stopping Story and Story-geth..." && sleep 1
  if [[ -z "$story_name" ]]; then
    story_name=$(define_service_name "story" "Story")
  fi
  if [[ -z "$geth_name" ]]; then
    geth_name=$(define_service_name "story-geth" "Story-geth")
  fi
  
  if sudo systemctl stop $story_name $geth_name; then
      printBlue "Story and Story-geth stopped" && sleep 1
      echo ""
    else
      printRed "Failed to stop services" && sleep 1
      ask_to_continue
    fi

  printGreen "2. Configuring state sync for Story..." && sleep 1
  cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
  rm -rf $HOME/.story/story/data
  mkdir $HOME/.story/story/data
  mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

  SNAP_RPC="https://story-dev-rpc.coinhunterstr.com:443"

  sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
  $HOME/.story/story/config/config.toml

  LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height);
  BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000));
  TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

  echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH && sleep 2

  sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ;
  s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ;
  s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ;
  s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ;
  s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.story/story/config/config.toml

  printBlue "done"
  echo ""

  printGreen "3. Restarting Story and Story-geth..." && sleep 1
  if sudo systemctl restart $story_name $geth_name; then
    printBlue "Story and Story-geth restarted" && sleep 1
    echo ""
    printGreen "State Sync configured. Please check logs to make sure the node is running smoothly."
  else
    printRed "Failed to restart services"
  fi
}

# Main
action=0
printLogo
echo "Story Installation Automation Tool"
while [[ $action -ne 10 ]]; do
echo ""
printLine
printLine
printGreen "Which action would you like to perform?"
options=(
  "Install Story node"
  "Manually upgrade Story & Story-geth to the latest version"
  "Auto upgrade"
  "Download snapshot"
  "Configure state sync for Story"
  "Check sync status"
  "Check logs"
  "Enable p2p ports"
  "Delete Story & Story-geth"
  "Exit"
)
for i in "${!options[@]}"; do
  printf "%s. %s\n" "$((i + 1))" "${options[$i]}"
done
read -rp "Your answer: " action
echo ""
printLine

if [[ $action -eq 1 ]]; then
  printLine
  install_node
  printGreen "Autoinstallation complete!" && sleep 2
  printLine

elif [[ $action -eq 2 ]]; then
  printLine
  printGreen "1. Installing Story-geth..." && sleep 1
  install_geth
  
  printLine
  printGreen "2. Installing Story..." && sleep 1
  install_story
  
  printLine
  printGreen "3. Restarting Story and Story-geth..." && sleep 1
  if [[ -z "$story_name" ]]; then
    story_name=$(define_service_name "story" "Story")
  fi
  if [[ -z "$geth_name" ]]; then
    geth_name=$(define_service_name "story-geth" "Story-geth")
  fi
  
  if sudo systemctl restart $story_name $geth_name; then
    printBlue "Story and Story-geth restarted" && sleep 1
    echo ""
    printGreen "Story and Story-geth upgraded to the latest version." && sleep 2
  else
    printRed "Failed to restart services"
    ask_to_continue
  fi

elif [[ $action -eq 3 ]]; then
  rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.story/story/config/config.toml" | cut -d ':' -f 3)
  local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.latest_block_height')
  if [[ -z $local_height || $local_height -gt $upgrade_height ]]; then
    printRed "There are no planned updates yet. Please use manual upgrade if you want to update binaries to the latest version." && sleep 2
    printLine
  else
    autoupgrade
  fi

elif [[ $action -eq 4 ]]; then
  installation=false
  source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/AutoInstall/autosnap.sh)
  
elif [[ $action -eq 5 ]]; then
  printLine
  state_sync

elif [[ $action -eq 6 ]]; then
  printLine
  printGreen "Displaying node sync status..." && sleep 1
  check_sync_status
  
elif [[ $action -eq 7 ]]; then
  printLine
  printGreen "Displaying logs... Use CTRL+C to stop logs and get back to the menu." && sleep 3
  view_logs
  

elif [[ $action -eq 8 ]]; then
  printLine
  if [[ -z "${STORY_PORT}" ]]; then
    if sudo ufw allow 30303/tcp comment geth_p2p_port && sudo ufw allow 26656/tcp comment story_p2p_port; then
      printGreen "p2p ports enabled" && sleep 2
    else
      printRed "Error enabling p2p ports" && sleep 1
    fi
  else
    if sudo ufw allow ${STORY_PORT}303/tcp comment geth_p2p_port && sudo ufw allow ${STORY_PORT}656/tcp comment story_p2p_port; then
      printGreen "Firewall rules updated, p2p ports enabled" && sleep 2
      sleep 1
    else
      printRed "Error enabling p2p ports" && sleep 1
      sleep 1
    fi
  fi

elif [[ $action -eq 9 ]]; then
  printLine
  read -p "$(printRed 'Are you sure that you want to delete your node? (y/n): ')" delete_confirmation
  if [[ "$delete_confirmation" == "y" || "$delete_confirmation" == "Y" ]]; then
    printGreen "1. Backing up priv_validator_state.json and priv_validator_key.json..."
    if cp "$HOME/.story/story/data/priv_validator_state.json" "$HOME/priv_validator_state.json.backup"; then
      printBlue "priv_validator_state.json backup done"
    else
      printRed "Failed to backup priv_validator_state.json"
      ask_to_continue
    fi
    if cp "$HOME/.story/story/config/priv_validator_key.json" "$HOME/priv_validator_key.json.backup"; then
      printBlue "priv_validator_key.json backup done"
    else
      printRed "Failed to backup priv_validator_key.json"
      ask_to_continue
    fi

    printGreen "2. Deleting Story and Story-geth..."
    if [[ -z "$story_name" ]]; then
      story_name=$(define_service_name "story" "Story")
    fi
    if [[ -z "$geth_name" ]]; then
      geth_name=$(define_service_name "story-geth" "Story-geth")
    fi
    if sudo systemctl stop $story_name $geth_name; then
      printBlue "Story and Story-geth stopped" && sleep 1
    else
      printRed "Failed to stop services" && sleep 1
      ask_to_continue
    fi
    rm -rf $HOME/.story
    if sudo rm /etc/systemd/system/$story_name.service /etc/systemd/system/$geth_name.service; then
      printBlue "Story and Story-geth service files removed" && sleep 1
      echo ""
      printGreen "Story and Story-geth deleted" && sleep 2
    else
      printRed "Failed to remove service files" && sleep 1
    fi
    sudo systemctl daemon-reload
  fi

elif [[ $action -eq 10 ]]; then
  printRed "Exiting the script..." && sleep 1
  printLine

elif [[ $action -ne 10 ]]; then
  printRed "Invalid choice. Try again." && sleep 1

fi
done
from_autoinstall=false
