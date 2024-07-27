#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

printLogo

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export LAVA_CHAIN_ID="lava-testnet-2"" >> $HOME/.bash_profile
echo "export LAVA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$LAVA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$LAVA_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.20.5"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
wget -O lavad https://github.com/lavanet/lava/releases/download/v2.1.3/lavad-v2.1.3-linux-amd64
chmod +x $HOME/lavad
mv $HOME/lavad $HOME/go/bin/lavad

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
lavad init $MONIKER --chain-id $LAVA_CHAIN_ID
sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  $HOME/.lava/config/config.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.lava/config/genesis.json https://snapshots.kjnodes.com/lava-testnet/genesis.json
wget -O $HOME/.lava/config/addrbook.json  https://snapshots.kjnodes.com/lava-testnet/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="eb7832932626c1c636d16e0beb49e0e4498fbd5e@lava-testnet-seed.itrocket.net:20656"
PEERS="47d2809dd4b372e9c7864a3ac26c61a424abe392@162.55.99.76:19956,d1730b774b7c1d52dd9f6ae874a56de958aa147e@139.45.205.60:23656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:14456,6034aff8652ee9151edc75d8d9769df3cd126657@113.172.192.42:17656,5c2a752c9b1952dbed075c56c600c3a79b58c395@195.3.220.21:27066,f23540653fbc0612f5f0b4603dbcfeb3465304ed@167.235.14.83:656,0a528da95ca8025ef4043b6e73f1e789f4102940@176.103.222.22:26656,b7241a2120a1e5c607c1ec65a98a156b4fb043fe@49.12.168.50:26656,3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@34.75.214.127:26656,dae571b14dcb4e55566071cb0083a937edd0cfe8@109.199.116.71:19956,adee08ddadd5c366725e5277f68394dc3d1c27a7@171.247.159.227:23656,eb7832932626c1c636d16e0beb49e0e4498fbd5e@65.108.231.124:20656,99327e5cf0f31ac3bb1ca8e39cc9f17c823b7ec1@65.109.25.104:26656,7ee8434b107b32f764f42bcc82b6fbfc25011d8f@65.108.75.107:28656,af35315017a810e541f6e3cb0a08e2dfa773853b@95.216.98.97:20256,e28b8ad6e20fda1e647c977fb256208b91b74893@116.202.80.186:14456,97b3648ef143d537e6aee3b11f054a0e6b6be691@57.128.81.5:26656,eed45ce3c41d4c34af4c7e7bff2a956dcc39ca23@49.12.168.49:26656,f6a2359abadba6b22544658a3492aed84b4e26b4@143.110.185.169:26656,9408220cc93a84e11ba04eb19109f27b00fb4a92@65.109.19.235:20256,b42779b2e6017e68169c63bc33b5317b6c2a33ed@185.248.24.33:26656,0e0e01f932a124c45f7f8600e38dba445b5f5dc4@65.108.226.183:19956,e49bd2f4ebe95ccf198cc997151a9389a7482411@167.235.115.119:36656,db5beaf0ce501fad15a1f51281899b845c7fbbc9@46.4.81.53:20256,8c71c05fd08c15ed98b6e20c197eeb9e9a42fd38@65.108.236.147:20256,149f9f017344ce9cebb637baa7cab57a28f3a8c3@86.111.48.159:26656,068439250e4d636bde4fe71b00bc204f9e32ce9c@158.220.97.137:31656,564014d72e7c41a03d14771a0f71abd143020861@195.14.6.179:26656,20c13bd0d972acba5588493fb528b558a0317013@38.242.133.203:26656,3693ea5a8a9c0590440a7d6c9a98a022ce3b2455@lava-testnet-peer.itrocket.net:20656,1f7e104872a3f4259343b8123f333b5b24869b02@159.89.111.21:26656,6c398d8133a0a38c85001d2a3f01db51d064d7aa@31.220.90.180:24656,c40a7bc3c7aee0428273c0bfa75fcb14bf0f44c4@65.109.90.171:30656,ed295c3ece2ded17ea4007a680154db83abeca13@95.217.114.220:13656,17a580accb1050271e1c377958c70e1286a0ba8f@65.109.115.104:46656,0e0e01f932a124c45f7f8600e38dba445b5f5dc4@65.108.226.183:19956,0314d53cc790860fb51f36ac656a19789800ce5c@176.103.222.20:26656,70f7f5a56b40dbb88e423e675546da702d82751b@207.180.207.53:33956,897d44b1cb6633539cf51261f6629a9d5664eb9b@159.69.72.247:11656,f1bb78a30c9381bed392fda141a5c1f6fa4d25e6@144.76.114.49:36656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.lava/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${LAVA_PORT}317%g;
s%:8080%:${LAVA_PORT}080%g;
s%:9090%:${LAVA_PORT}090%g;
s%:9091%:${LAVA_PORT}091%g;
s%:8545%:${LAVA_PORT}545%g;
s%:8546%:${LAVA_PORT}546%g;
s%:6065%:${LAVA_PORT}065%g" $HOME/.lava/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${LAVA_PORT}658%g;
s%:26657%:${LAVA_PORT}657%g;
s%:6060%:${LAVA_PORT}060%g;
s%:26656%:${LAVA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${LAVA_PORT}656\"%;
s%:26660%:${LAVA_PORT}660%g" $HOME/.lava/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.lava/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0ulava"|g' $HOME/.lava/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.lava/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.lava/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/lavad.service > /dev/null <<EOF
[Unit]
Description=lava node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.lava
ExecStart=$(which lavad) start --home $HOME/.lava
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
lavad tendermint unsafe-reset-all --home $HOME/.lava
if curl -s --head curl https://snapshots.kjnodes.com/lava-testnet/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.kjnodes.com/lava-testnet/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava
    else
  echo "no snapshot founded"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable lavad
sudo systemctl restart lavad && sudo journalctl -u lavad -f
