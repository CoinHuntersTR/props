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
echo "export NILLION_CHAIN_ID="nillion-chain-testnet-1"" >> $HOME/.bash_profile
echo "export NILLION_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$NILLION_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$NILLION_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.4"
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
wget -O nilchaind https://snapshots.coinhunterstr.com/nillion/nilchaind
chmod +x nilchaind
mv nilchaind $HOME/go/bin/

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
nilchaind init $MONIKER --chain-id nillion-chain-testnet-1 --home=$HOME/.nillionapp

sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
curl -Ls https://raw.githubusercontent.com/CoinHuntersTR/props/main/nillion/genesis.json > $HOME/.nillionapp/config/genesis.json
curl -Ls https://raw.githubusercontent.com/CoinHuntersTR/props/main/nillion/addrbook.json > $HOME/.nillionapp/config/addrbook.json

sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="3f472746f46493309650e5a033076689996c8881@nillion-testnet.rpc.kjnodes.com:18059"
PEERS="a82a9f70707da1def94f26f423c30b18f2a87dd7@65.109.59.22:28156,ce05aec98558f9a8289f983b083badf9d37e4d44@141.95.35.110:56316,25d9320d62fd1987c10f6536924e0ddddbbd7cf4@141.94.143.203:56316,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@213.239.207.162:18056,8a0c1c5a32759a228e786c959c2a87c63c7e9805@88.99.137.42:53656,037a1924a31253c82451108ea7e565e42c503a78@78.46.76.145:32656,1f0910e8021748d24c943359b4f89c91800597e0@185.180.222.76:26656,e4855d41f3e66d961215d48ac8eabe309cfd4437@135.125.67.241:26616,716d70d81c2a9d62a32d6cc99f41fc1b488cf72c@65.109.228.73:26656,c59dff7e20c675fe4f76162e9886dcca9b5104ce@135.181.238.38:28156"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.nillionapp/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${NILLION_PORT}317%g;
s%:8080%:${NILLION_PORT}080%g;
s%:9090%:${NILLION_PORT}090%g;
s%:9091%:${NILLION_PORT}091%g;
s%:8545%:${NILLION_PORT}545%g;
s%:8546%:${NILLION_PORT}546%g;
s%:6065%:${NILLION_PORT}065%g" $HOME/.nillionapp/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${NILLION_PORT}658%g;
s%:26657%:${NILLION_PORT}657%g;
s%:6060%:${NILLION_PORT}060%g;
s%:26656%:${NILLION_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${NILLION_PORT}656\"%;
s%:26660%:${NILLION_PORT}660%g" $HOME/.nillionapp/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.nillionapp/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.nillionapp/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.nillionapp/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0unil"|g' $HOME/.nillionapp/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.nillionapp/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.nillionapp/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/nillion.service > /dev/null <<EOF
[Unit]
Description=nillion node service
After=network-online.target
[Service]
User=deneme
WorkingDirectory=/root/.nillionapp/
ExecStart=/root/go/bin/nilchaind start --home /root/.nillionapp/
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
nilchaind tendermint unsafe-reset-all --home $HOME/.nillionapp --home $HOME/.nillionapp
if curl -s --head curl https://snapshots.coinhunterstr.com/nillion/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.coinhunterstr.com/nillion/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.nillionapp
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable nillion.service
sudo systemctl restart nillion.service && sudo journalctl -u nillion.service -f
