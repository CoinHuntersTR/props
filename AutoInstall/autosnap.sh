#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

if [[ "$from_autoinstall" != "true" ]]; then
  printLogo
fi

echo "Story Snapshot Installation Tool"
sleep 1

# Defining variables
storyPath=$HOME/.story/story
gethPath=$HOME/.story/geth/story/geth

# Snapshot URLs
STORY_SNAPSHOT_URL="https://snapshots.coinhunterstr.com/mainnet/story-dev/story/story_snapshot_latest.tar.lz4"
GETH_SNAPSHOT_URL="https://snapshots.coinhunterstr.com/mainnet/story-dev/story-geth/story_geth_snapshot_latest.tar.lz4"

function printLogo {
  bash <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/logo.sh)
}

# Function to define service name
define_service_name() {
  service_name=\$1
  print_name=\$2
  systemctl status $service_name > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code -eq 4 ]]; then
    read -rp "Enter your $print_name service file name: " service_name
  fi
  echo $service_name
}

# Function to prompt user to continue or exit
ask_to_continue() {
  read -p "$(printYellow 'Do you want to continue anyway? (y/n): ')" choice
  if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    printRed "Exiting script."
    exit 1
  fi
}

printLine
print_step "Installing dependencies..." true
if [[ "$from_autoinstall" != "true" || "$installation" == "false" ]]; then
  sudo apt update && sudo apt upgrade -y
  sudo apt install curl wget lz4 jq -y
fi

printLine
print_step "Stopping story and story-geth services..." true
if [[ "$from_autoinstall" != "true" || "$installation" == "false"  ]]; then
  if [[ -z "$story_name" ]]; then
    story_name=$(define_service_name "story" "Story")
  fi
  if [[ -z "$geth_name" ]]; then
    geth_name=$(define_service_name "story-geth" "Story-geth")
  fi
  if sudo systemctl stop $story_name $geth_name; then
    printBlue "Services stopped successfully"
    echo ""
  else
    printRed "Failed to stop services"
    ask_to_continue
  fi
fi

printLine
print_step "Backing up priv_validator_state.json..."
if cp "$storyPath/data/priv_validator_state.json" "$storyPath/priv_validator_state.json.backup"; then
  printBlue "Backup created successfully"
  echo ""
else
  printRed "Failed to backup priv_validator_state.json"
  ask_to_continue
fi

printLine
print_step "Removing old data and downloading Story snapshot..."
if rm -rf "$storyPath/data"; then
  printBlue "Old data removed"
  echo ""
  if curl -L "$STORY_SNAPSHOT_URL" | lz4 -dc - | tar -xf - -C "$storyPath"; then
    printBlue "Story snapshot downloaded and extracted"
    echo ""
  else
    printRed "Failed to download or extract Story snapshot"
    ask_to_continue
  fi
else
  printRed "Failed to remove old data"
  ask_to_continue
fi

printLine
print_step "Restoring priv_validator_state.json..."
if mv "$storyPath/priv_validator_state.json.backup" "$storyPath/data/priv_validator_state.json"; then
  printBlue "Restored successfully"
  echo ""
else
  printRed "Failed to restore priv_validator_state.json"
  ask_to_continue
fi

printLine
print_step "Removing old Geth data and downloading Geth snapshot..."
if rm -rf "$gethPath/chaindata"; then
  printBlue "Old Geth data removed"
  echo ""
  if curl -L "$GETH_SNAPSHOT_URL" | lz4 -dc - | tar -xf - -C "$gethPath"; then
    printBlue "Geth snapshot downloaded and extracted"
    echo ""
  else
    printRed "Failed to download or extract Geth snapshot"
    ask_to_continue
  fi
else
  printRed "Failed to remove Geth data"
  ask_to_continue
fi

printLine
print_step "Starting Story and Geth services..."
if sudo systemctl restart $story_name $geth_name; then
  printBlue "Services started successfully"
  echo ""
else
  printRed "Failed to start services"
  ask_to_continue
fi

printLine
printGreen "Snapshot installation completed!"
printGreen "Please wait a few minutes for the node to start syncing..."
printLine

echo "You can check the logs with:"
echo "sudo journalctl -u $story_name -u $geth_name -f"
