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
VER="1.22.11"
wget "https://golang.org/dl/go$VER.linux-arm64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-arm64.tar.gz"
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
git checkout v1.0.2
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
git checkout v1.1.0
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
SEEDS="944e8889ecd7c13623ef1081aae4555d6f525041@b1-b.odyssey-devnet.storyrpc.io:26656"
PEERS="3b1aaa03f996d619cb2f4230ebace45686ab3b8a@34.140.167.127:26656,36ca8b119bf5851cd1e37060af914cb07dec24f9@34.79.40.193:26656,2a28bd1a6ecb0a1d8ceade599b311d202447d635@193.122.141.78:26656,b540a4a88399bee252207ab9cf783c14fcefd4dc@65.108.30.59:26656,b21b772ca2e4067844f881e8a79a7447dc435217@65.108.141.109:29456,6c89fb9e0791ffa67468b9f9923891a2bfcad80f@141.94.143.203:56356,1ff566a5ac0bd3605e8af09e92cacc43927aed7f@161.35.70.64:26656,2e00c3e558f382e48fe7511f50c069fde44a6468@150.136.128.196:26656,20a1a828469c42047601529a50f527ecf9301251@35.211.53.224:26656,b965eed902107d29df3669b2ff9a93859db236a3@49.12.92.82:56356,817a54d7ed4f3b618d37ea80448c135b20fc34e1@34.143.143.252:26656,0eda723784a874798b173df8f17545f9984b86e6@35.211.230.141:26656,155bcba7d521ced31042bd99100841c6cf057f36@35.211.9.151:26656,7e311e22cff1a0d39c3758e342fa4c2ee1aea461@188.166.224.194:28656,59201fade719c1e4ded98b2304e555377d2b4cef@116.202.217.20:28656,9d34ab3819aa8baa75589f99138318acfa0045f5@95.217.119.251:30900,45938d3dfe2877e1eb45cbce10f2d02c676f50a0@198.244.176.117:33656,580be4f3e5f505ed0ea15510997aeeb74e35408e@35.211.167.181:26656,944e8889ecd7c13623ef1081aae4555d6f525041@35.211.57.203:26656"
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
