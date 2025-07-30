#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

printLogo

read -p "Enter your MONIKER :" STORY_MONIKER
echo 'export STORY_MONIKER='$STORY_MONIKER
read -p "Enter your PORT (for example 62, default port=26, must be 2 digits):" STORY_PORT
echo 'export STORY_PORT='$STORY_PORT

# set vars
echo "export STORY_MONIKER=\"$STORY_MONIKER\"" >> $HOME/.bash_profile
echo "export STORY_PORT=\"$STORY_PORT\"" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo "Installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

echo "Installing Go..."
cd $HOME
VER="1.22.5"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo "Installing story-geth..."
cd $HOME
rm -rf story-geth
git clone https://github.com/piplabs/story-geth.git
cd story-geth
git checkout v1.1.0
go build -v ./cmd/geth
mv ./geth $HOME/go/bin/story-geth
cd $HOME
[ ! -d "$HOME/.story/story" ] && mkdir -p "$HOME/.story/story"
[ ! -d "$HOME/.story/geth" ] && mkdir -p "$HOME/.story/geth"

echo "Installing story client..."
cd $HOME
rm -rf story
git clone https://github.com/piplabs/story
cd story
git checkout v1.3.0
go build -o story ./client 
mv ./story $HOME/go/bin/story
cd $HOME

echo "Initializing the node..."
story init --moniker $STORY_MONIKER --network aeneid

echo "Configuring ports..."
sed -i.bak -e "s%:1317%:${STORY_PORT}317%g;
s%:8551%:${STORY_PORT}551%g" $HOME/.story/story/config/story.toml

sed -i.bak -e "s%:26658%:${STORY_PORT}658%g;
s%:26657%:${STORY_PORT}657%g;
s%:26656%:${STORY_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${STORY_PORT}656\"%;
s%:26660%:${STORY_PORT}660%g" $HOME/.story/story/config/config.toml

echo "Configuring indexer & prometheus..."
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.story/story/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.story/story/config/config.toml

echo "Setting seeds & peers..."
SEEDS="944e8889ecd7c13623ef1081aae4555d6f525041@b1-b.odyssey-devnet.storyrpc.io:26656,46b7995b0b77515380000b7601e6fc21f783e16f@story-testnet-seed.itrocket.net:52656"
PEERS="d0bd5c23b0a707104b0b7e4411f539573039fe22@144.91.107.167:656,dfb96be7e47cd76762c1dd45a5f76e536be47faa@65.108.45.34:32655,b1b89c9edb7ae45a19cac9c08d86c329bb146e4f@152.53.163.158:26656,7160dec63da82b56e1ce59a93c057c05e361cf85@135.181.117.37:64656,9308260b6cb4ca1faa9f3025bac0bc2636c4b020@185.232.68.94:26656,01f8a2148a94f0267af919d2eab78452c90d9864@story-testnet-rpc.itrocket.net:52656,01f8a2148a94f0267af919d2eab78452c90d9864@207.120.52.220:52656,85e39bd2820f16f023289ff7f2a3e57b60d03dcb@198.244.176.206:22136,fbf163ec501eb2acdfe90317dd06c3bad7acaf26@65.21.192.60:62656,e97c0185a7b609736138ed9275d9071a798c420b@148.72.141.31:26686,dd4a2150198b059baf511f4058c60b14a62617d9@15.235.112.107:22136"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.story/story/config/config.toml

echo "Downloading genesis & addrbook..."
wget -O $HOME/.story/story/config/genesis.json https://files.mictonode.com/story/genesis/genesis.json
wget -O $HOME/.story/story/config/addrbook.json  https://files.mictonode.com/story/addrbook/addrbook.json

echo "Creating services..."
# story-geth service
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/story-geth --aeneid --syncmode full --port ${STORY_PORT}303 --http --http.api eth,net,web3,engine --http.vhosts '*' --http.addr 0.0.0.0 --http.port ${STORY_PORT}545 --authrpc.addr 127.0.0.1 --authrpc.port ${STORY_PORT}551 --authrpc.vhosts=* --ws --ws.api eth,web3,net,txpool --ws.addr 0.0.0.0 --ws.port ${STORY_PORT}546 --ws.origins '*'
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# story service
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.story/story
ExecStart=$(which story) run

Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

echo "Downloading snapshot..."
echo "STORY Snapshot Height: $(curl -s https://files.mictonode.com/story/snapshot/block-height.txt)"

cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup 2>/dev/null || true
rm -rf $HOME/.story/story/data
rm -rf $HOME/.story/geth/aeneid/geth/chaindata
mkdir -p $HOME/.story/geth/aeneid/geth

SNAPSHOT_URL="https://files.mictonode.com/story/snapshot/"
LATEST_COSMOS=$(curl -s $SNAPSHOT_URL | grep -oP 'story_\d{8}-\d{4}_\d+_cosmos\.tar\.lz4' | sort | tail -n 1)
LATEST_GETH=$(curl -s $SNAPSHOT_URL | grep -oP 'story_\d{8}-\d{4}_\d+_geth\.tar\.lz4' | sort | tail -n 1)

if [ -n "$LATEST_COSMOS" ] && [ -n "$LATEST_GETH" ]; then
  COSMOS_URL="${SNAPSHOT_URL}${LATEST_COSMOS}"
  GETH_URL="${SNAPSHOT_URL}${LATEST_GETH}"

  echo "Downloading Cosmos snapshot: $LATEST_COSMOS"
  curl "$COSMOS_URL" | lz4 -dc - | tar -xf - -C $HOME/.story/story

  echo "Downloading Geth snapshot: $LATEST_GETH"
  curl "$GETH_URL" | lz4 -dc - | tar -xf - -C $HOME/.story/geth/aeneid/geth

  if [ -f "$HOME/.story/story/priv_validator_state.json.backup" ]; then
    mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json
  fi
else
  echo "Snapshot not found."
fi

echo "Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable story story-geth
sudo systemctl start story-geth && sleep 5 && sudo systemctl start story

echo "Check logs with: journalctl -u story -u story-geth -f"
