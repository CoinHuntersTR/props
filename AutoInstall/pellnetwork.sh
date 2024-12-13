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
echo "export PELL_CHAIN_ID="ignite_186-1"" >> $HOME/.bash_profile
echo "export PELL_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$PELL_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$PELL_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.6"
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
WASMVM_VERSION=v2.1.2
export LD_LIBRARY_PATH=~/.pellcored/lib
mkdir -p $LD_LIBRARY_PATH
wget "https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so" -O "$LD_LIBRARY_PATH/libwasmvm.$(uname -m).so"
echo "export LD_LIBRARY_PATH=$HOME/.pellcored/lib:$LD_LIBRARY_PATH" >> $HOME/.bash_profile
source ~/.bash_profile

cd $HOME
wget -O pellcored https://github.com/0xPellNetwork/network-config/releases/download/v1.0.20-ignite/pellcored-v1.0.20-linux-amd64
chmod +x $HOME/pellcored
mv $HOME/pellcored $HOME/go/bin/pellcored

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
pellcored config node tcp://localhost:${PELL_PORT}657
pellcored config keyring-backend os
pellcored config chain-id ignite_186-1
pellcored init $MONIKER --chain-id $PELL_CHAIN_ID
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.pellcored/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/pellnetwork/genesis.json
wget -O $HOME/.pellcored/config/addrbook.json  https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/pellnetwork/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="d52c32a6a8510bdf0d33909008041b96d95c8408@34.87.39.12:26656,9b955d07f05b02b3d622f9cb7a0e6cfecd719985@34.87.47.193:26656"
PEERS="d52c32a6a8510bdf0d33909008041b96d95c8408@34.87.39.12:26656,9b955d07f05b02b3d622f9cb7a0e6cfecd719985@34.87.47.193:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.pellcored/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${PELL_PORT}317%g;
s%:8080%:${PELL_PORT}080%g;
s%:9090%:${PELL_PORT}090%g;
s%:9091%:${PELL_PORT}091%g;
s%:8545%:${PELL_PORT}545%g;
s%:8546%:${PELL_PORT}546%g;
s%:6065%:${PELL_PORT}065%g" $HOME/.pellcored/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${PELL_PORT}658%g;
s%:26657%:${PELL_PORT}657%g;
s%:6060%:${PELL_PORT}060%g;
s%:26656%:${PELL_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${PELL_PORT}656\"%;
s%:26660%:${PELL_PORT}660%g" $HOME/.pellcored/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME.pellcored/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.pellcored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.pellcored/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0apell"|g' $HOME/.pellcored/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.pellcored/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.pellcored/config/config.toml
sleep 1
echo done

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
pellcored tendermint unsafe-reset-all --home $HOME/.pellcored
if curl -s --head curl https://server-5.itrocket.net/testnet/pell/pell_2024-12-13_110682_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-5.itrocket.net/testnet/pell/pell_2024-12-13_110682_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.pellcored
    else
  echo "no snapshot found"
fi

# create service file
sudo tee /etc/systemd/system/pellcored.service > /dev/null <<EOF
[Unit]
Description=pellnetwork node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.pellcored
ExecStart=$(which pellcored) start --home $HOME/.pellcored
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF


# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable pellcored
sudo systemctl restart pellcored && sudo journalctl -u pellcored -f
