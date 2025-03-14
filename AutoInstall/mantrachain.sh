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
echo "export MANTRA_CHAIN_ID="mantra-dukong-1"" >> $HOME/.bash_profile
echo "export MANTRA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$MANTRA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$MANTRA_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.23.2"
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
wget -O mantrachaind-1.0.2-linux-amd64.tar.gz https://github.com/MANTRA-Chain/mantrachain/releases/download/v1.0.2/mantrachaind-1.0.2-linux-amd64.tar.gz
tar -xzf mantrachaind-1.0.2-linux-amd64.tar.gz
rm $HOME/mantrachaind-1.0.2-linux-amd64.tar.gz
chmod +x $HOME/mantrachaind
sudo mv $HOME/mantrachaind $HOME/go/bin/mantrachaind

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
mantrachaind config node tcp://localhost:${MANTRA_PORT}657
mantrachaind config keyring-backend os
mantrachaind config chain-id mantra-dukong-1
mantrachaind init $MONIKER --chain-id mantra-dukong-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.mantrachain/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/mantra/dukong/genesis.json
wget -O $HOME/.mantrachain/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/mantra/dukong/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
URL="https://mantra-dukong-rpc.chainad.org/net_info"
response=$(curl -s $URL)
PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
echo "PEERS=\"$PEERS\""

# Update the persistent_peers in the config.toml file
sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|; s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.mantrachain/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${MANTRA_PORT}317%g;
s%:8080%:${MANTRA_PORT}080%g;
s%:9090%:${MANTRA_PORT}090%g;
s%:9091%:${MANTRA_PORT}091%g;
s%:8545%:${MANTRA_PORT}545%g;
s%:8546%:${MANTRA_PORT}546%g;
s%:6065%:${MANTRA_PORT}065%g" $HOME/.mantrachain/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${MANTRA_PORT}658%g;
s%:26657%:${MANTRA_PORT}657%g;
s%:6060%:${MANTRA_PORT}060%g;
s%:26656%:${MANTRA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${MANTRA_PORT}656\"%;
s%:26660%:${MANTRA_PORT}660%g" $HOME/.mantrachain/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.mantrachain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.mantrachain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.mantrachain/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0002uom"|g' $HOME/.mantrachain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.mantrachain/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.mantrachain/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/mantrachaind.service > /dev/null <<EOF
[Unit]
Description=mantra node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.mantrachain
ExecStart=$(which mantrachaind) start --home $HOME/.mantrachain
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# Reset the blockchain data
mantrachaind tendermint unsafe-reset-all --home $HOME/.mantrachain

# Check if the new snapshot URL is accessible
if curl -s --head https://snapshots.coinhunterstr.com/testnet/mantrachain/snap_mantra.tar.zst | head -n 1 | grep "200" > /dev/null; then
  # Download and extract the snapshot using zstd
  curl https://snapshots.coinhunterstr.com/testnet/mantrachain/snap_mantra.tar.zst | zstd -dc - | tar -xf - -C $HOME/.mantrachain
  echo "No snapshot available"
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable mantrachaind
sudo systemctl restart mantrachaind && sudo journalctl -u mantrachaind -f
