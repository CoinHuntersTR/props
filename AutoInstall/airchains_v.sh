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
echo "export AIRCHAIN_CHAIN_ID="varanasi-1"" >> $HOME/.bash_profile
echo "export AIRCHAIN_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$AIRCHAIN_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$AIRCHAIN_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.21.6"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/refs/heads/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
wget -O junctiond https://github.com/airchains-network/junction/releases/download/v0.3.1/junctiond-linux-amd64
chmod +x junctiond
mv junctiond $HOME/go/bin/

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
junctiond init $MONIKER --chain-id $AIRCHAIN_CHAIN_ID 
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${AIRCHAIN_PORT}657\"|" $HOME/.junctiond/config/client.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.junctiond/config/genesis.json https://server-7.itrocket.net/testnet/airchains_v/genesis.json
wget -O $HOME/.junctiond/config/addrbook.json  https://server-7.itrocket.net/testnet/airchains_v/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="97cadd453fa35cee05f72611fdb15a49112575cb@airchains_v-testnet-seed.itrocket.net:19656"
PEERS="79f26210777e84efb600bf776c32615a72675d9f@airchains_v-testnet-peer.itrocket.net:19656,859485b13c2d8ab3888ffc11d1c506d78f681317@5.9.116.21:26756,8c229309660496e71b8a9d1edee46a18693b8e70@65.109.111.234:19656,db686fcfdf0b4676d601d5beb11faee5ad96bff1@37.27.71.199:28656,0b4e78189c9148dda5b1b98c6e46b764337558a3@91.227.33.18:19656,4eff6ecc2323811d18c7e06319b2d8bbf58590d1@65.108.233.73:19656,b43f7c96bb780d9ac535d3c1f78092cf8c455e85@104.36.23.246:26656,b107bf75ca12c4f5fa544390e27f8104b13c7f1b@[2001:41d0:1004:1596::1]:13756,3650f3737940af2d6cc8d17244706505648ff639@212.56.32.148:14156,847ffe6f885e4dd3ea97e5d558ee1bca1cc3fe9d@213.136.91.3:19656,43c265128fd9be02721df03e8ba4bcf8c982a062@1.53.252.54:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.junctiond/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${AIRCHAIN_PORT}317%g;
s%:8080%:${AIRCHAIN_PORT}080%g;
s%:9090%:${AIRCHAIN_PORT}090%g;
s%:9091%:${AIRCHAIN_PORT}091%g;
s%:8545%:${AIRCHAIN_PORT}545%g;
s%:8546%:${AIRCHAIN_PORT}546%g;
s%:6065%:${AIRCHAIN_PORT}065%g" $HOME/.junctiond/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${AIRCHAIN_PORT}658%g;
s%:26657%:${AIRCHAIN_PORT}657%g;
s%:6060%:${AIRCHAIN_PORT}060%g;
s%:26656%:${AIRCHAIN_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${AIRCHAIN_PORT}656\"%;
s%:26660%:${AIRCHAIN_PORT}660%g" $HOME/.junctiond/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.junctiond/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.junctiond/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.junctiond/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.001uamf"|g' $HOME/.junctiond/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.junctiond/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.junctiond/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/junctiond.service > /dev/null <<EOF
[Unit]
Description=airchains_v node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.junctiond
ExecStart=$(which junctiond) start --home $HOME/.junctiond
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
junctiond tendermint unsafe-reset-all --home $HOME/.junctiond
if curl -s --head curl https://snapshots.coinhunterstr.com/testnet/airchains/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.coinhunterstr.com/testnet/airchains/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.junctiond
    else
  echo "no snapshot found"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable junctiond
sudo systemctl restart junctiond && sudo journalctl -u junctiond -f --no-hostname -o cat
