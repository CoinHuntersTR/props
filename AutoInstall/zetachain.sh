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
echo "export ZETACHAIN_CHAIN_ID="zetachain_7000-1"" >> $HOME/.bash_profile
echo "export ZETACHAIN_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$ZETACHAIN_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ZETACHAIN_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.20.3"
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
wget https://github.com/zeta-chain/node/releases/download/v14.0.1/zetacored-linux-amd64
chmod +x $HOME/zetacored-linux-amd64
mv $HOME/zetacored-linux-amd64 $HOME/go/bin/zetacored

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
zetacored init $MONIKER --chain-id zetachain_7000-1
wget -O $HOME/.zetacored/config/app.toml  https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/app.toml
wget -O $HOME/.zetacored/config/client.toml https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/client.toml
wget -O $HOME/.zetacored/config/config.toml https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/config.toml
wget -O $HOME/.zetacored/config/genesis.json https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/genesis.json
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.zetacored/config/genesis.json https://undefined/mainnet/zetachain/genesis.json
wget -O $HOME/.zetacored/config/addrbook.json  https://undefined/mainnet/zetachain/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="4e668be2d80d3475d2350e313bc75b8f0646884f@zetachain-mainnet-seed.itrocket.net:39656"
PEERS="372e9c80f723491daf2b05b3aa368865f6bc3492@zetachain-mainnet-peer.itrocket.net:39656,294b6400e352554638d89743a6c9949d4faa57dd@23.239.106.2:31850,cda49d4af5da9a3c5b01be36663b2257d49cc309@15.235.9.141:26656,2a0a983bb9e8e04e8143819f4ca379b3b24aa77f@64.176.44.84:26656,0f1b077a1110f30e618dfc756a6195fd3d4206ed@208.91.106.108:26656,35e621bf11455cee613833243f268a1ba83aabb5@64.176.47.152:26656,177e7ddbb835e420395fa2977d8afb43ffaadb40@144.76.102.237:25656,a5d984f145ea828048a0741a1d349f9fa13a643b@91.210.101.148:26656,1d888c5985a536b53e528ad276b20294edb93592@208.91.106.110:26656,d105bb46800c46d3c6094b623dbe45077150baca@43.207.255.138:26656,f55f191f5036289ce0b7c2aee5aea6a3421e4a1d@51.178.76.16:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.zetacored/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${ZETACHAIN_PORT}317%g;
s%:8080%:${ZETACHAIN_PORT}080%g;
s%:9090%:${ZETACHAIN_PORT}090%g;
s%:9091%:${ZETACHAIN_PORT}091%g;
s%:8545%:${ZETACHAIN_PORT}545%g;
s%:8546%:${ZETACHAIN_PORT}546%g;
s%:6065%:${ZETACHAIN_PORT}065%g" $HOME/.zetacored/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${ZETACHAIN_PORT}658%g;
s%:26657%:${ZETACHAIN_PORT}657%g;
s%:6060%:${ZETACHAIN_PORT}060%g;
s%:26656%:${ZETACHAIN_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ZETACHAIN_PORT}656\"%;
s%:26660%:${ZETACHAIN_PORT}660%g" $HOME/.zetacored/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.zetacored/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.zetacored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.zetacored/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0azeta"|g' $HOME/.zetacored/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.zetacored/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.zetacored/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/zetacored.service > /dev/null <<EOF
[Unit]
Description=zetachain node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.zetacored
ExecStart=$(which zetacored) start --home $HOME/.zetacored
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
zetacored tendermint unsafe-reset-all --home $HOME/.zetacored
if curl -s --head curl https://snapshots.nodejumper.io/zetachain/zetachain_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.nodejumper.io/zetachain/zetachain_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.zetacored
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable zetacored
sudo systemctl restart zetacored && sudo journalctl -u zetacored -f
