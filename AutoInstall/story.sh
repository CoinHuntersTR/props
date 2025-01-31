#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

printLogo

read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT

# set vars
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export STORY_CHAIN_ID="story"" >> $HOME/.bash_profile
echo "export STORY_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Chain id:       \e[1m\e[32m$STORY_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$STORY_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.3"
wget "https://golang.org/dl/go$VER.linux-arm64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-arm64.tar.gz"
rm "go$VER.linux-arm64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/dependencies_install.sh)

printGreen "4. Installing binaries..." && sleep 1
# download story-geth
cd $HOME
wget https://github.com/piplabs/story-geth/releases/download/v1.0.1/geth-linux-arm64
sudo mv ./geth-linux-arm64 story-geth
sudo chmod +x story-geth
sudo mv ./story-geth $HOME/go/bin/story-geth
source $HOME/.bashrc

echo $(story-geth version) && sleep 2

# download story
cd $HOME
wget https://github.com/piplabs/story/releases/download/v1.0.0/story-linux-arm64
sudo mv story-linux-arm64 story
sudo chmod +x story
sudo mv ./story $HOME/go/bin/story
source $HOME/.bashrc

echo $(story version) && sleep 2

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
story init --network $STORY_CHAIN_ID --moniker $MONIKER
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.story/story/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/story/genesis.json
wget -O $HOME/.story/story/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/story/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="c1d973eea1b2c637777ab32783b3d37f2b52ba36@b1.storyrpc.io:26656,78db197dbbffb97a5c851b87b1df4cc51e99d4f9@b2.storyrpc.io:26656"
PEERS="4761ef729f12b80b3652edd26bd45734b5ff4515@51.15.15.160:26656,b1eb613c9026d8643cca4630e4935559bf303d7d@35.211.121.91:26656,c5f37a1293c2baf12e36a0d0f34d1371b1bb576a@35.207.10.148:26656,f8e84fb3fc3dfa3ce8aba3a347773d8ba43587ac@35.211.179.10:26656,155bcba7d521ced31042bd99100841c6cf057f36@35.207.25.245:26656,55f2ea5e1fc7a17000ce7d5adf8ddf7f4c61e4d4@35.207.42.225:26656,68c5b1eae074c5b556bf9d32668a9b152ce12b09@35.211.203.203:26656,b860ab1670f622ad209c31012a7934c254712c19@35.211.19.204:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.story/story/config/config.toml

# set custom ports in story.toml file
sed -i.bak -e "s%:1317%:${STORY_PORT}317%g;
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
echo done

# create geth servie file
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=$USER
ExecStart=/root/go/bin/story-geth --story --syncmode full
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
ExecStart=$(which story) run
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

printGreen "starting node..." && sleep 1
# enable and start geth, story
sudo systemctl daemon-reload
sudo systemctl enable story story-geth
sudo systemctl restart story-geth && sleep 5 && sudo systemctl restart story
sudo journalctl -u story-geth -u story -f
