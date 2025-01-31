#!/bin/bash

echo "Story Protocol Snapshot Installation Tool"
echo "---------------------------------------"

# Paths
HOME_DIR=$HOME
STORY_PATH="$HOME_DIR/.story/story"
GETH_PATH="$HOME_DIR/.story/geth/story/geth"

# URLs
STORY_URL="https://snapshots.coinhunterstr.com/mainnet/story-dev/story/story_snapshot_latest.tar.lz4"
GETH_URL="https://snapshots.coinhunterstr.com/mainnet/story-dev/story-geth/story_geth_snapshot_latest.tar.lz4"

echo "1. Stopping services..."
sudo systemctl stop story story-geth

echo "2. Backing up validator state..."
cp "$STORY_PATH/data/priv_validator_state.json" "$STORY_PATH/priv_validator_state.json.backup"

echo "3. Removing old data and downloading Story snapshot..."
rm -rf "$STORY_PATH/data"
curl -L "$STORY_URL" | lz4 -dc - | tar -xf - -C "$STORY_PATH"

echo "4. Restoring validator state..."
mv "$STORY_PATH/priv_validator_state.json.backup" "$STORY_PATH/data/priv_validator_state.json"

echo "5. Removing old Geth data and downloading Geth snapshot..."
rm -rf "$GETH_PATH/chaindata"
curl -L "$GETH_URL" | lz4 -dc - | tar -xf - -C "$GETH_PATH"

echo "6. Starting services..."
sudo systemctl restart story story-geth

echo "7. Installation completed!"
echo "Checking service status..."
sleep 5
sudo systemctl status story story-geth

echo "You can check logs with:"
echo "sudo journalctl -u story -u story-geth -f"
