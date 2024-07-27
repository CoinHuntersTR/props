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
echo "export FIAMMA_CHAIN_ID="fiamma-testnet-1"" >> $HOME/.bash_profile
echo "export FIAMMA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$FIAMMA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$FIAMMA_PORT\e[0m"
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
rm -rf fiamma
git clone https://github.com/fiamma-chain/fiamma.git
cd fiamma
git checkout v0.1.3
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
fiammad init $MONIKER --chain-id $FIAMMA_CHAIN_ID

echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.fiamma/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/fiamma/genesis.json
wget -O $HOME/.fiamma/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/fiamma/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="7f3988dc1f6254e664119d24b52982031e34327b@35.73.202.182:26656,40449ad696760c0d1b675c2741e846b5d08235a3@18.182.20.173:26656"
PEERS="5d6828849a45cf027e035593d8790bc62aca9cef@18.182.20.173:26656,526d13f3ce3e0b56fa3ac26a48f231e559d4d60c@35.73.202.182:26656,cedc2b0f16422718c320d17fc44935ad1c39e62d@172.31.26.39:26656,74cee55ba0696fcd75d637d0de637b7dfecb67bf@65.109.50.163:12656,21a5cae23e835f99735798024eef39fa0875bc62@65.109.30.110:17456,1833b283cbd1240e5a78c394f2d0955794e7732b@146.19.24.175:26856,4d56ef9164999825b886d67c95d9efbc12b455e9@65.109.49.47:29656,534bbf0712baf6665c2f3793131f7f53aa2806a6@193.70.47.69:26656,47c87d8ac9709669f7e9e9d9c8f5b76118763a13@94.130.216.221:26656,4ccfdc1ae7a8b87a83c0a675932960b750ea0e24@144.76.92.22:11656,4839dd83edd6d7cbb50974d4b1d748104ac56e58@65.109.112.148:40056,f1e941fa754357115f491dd1e138ac70610ab4a4@5.9.87.231:56656,9c87bf6872f2ca15c5f0b73348e6315be512aaa8@65.108.10.239:60956,781ff5ecf63b74c8b3934274ae3d4827ea5c4f74@65.109.57.212:29656,37e2b149db5558436bd507ecca2f62fe605f92fe@88.198.27.51:60556,67fffd28af7cc2a928c52fae6a09fe2812a6638d@217.66.20.45:26656,e00ecc7687e29f09f694dd4dd4a21988ce6a43f9@178.205.102.224:26656,a12e8531f345ccff39f47847aabf12e73e216ee3@144.76.97.251:26796,e2b57b310a6f3c4c0f85fc3dc3447d7e9696cd65@95.165.89.222:26706"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.fiamma/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${FIAMMA_PORT}317%g;
s%:8080%:${FIAMMA_PORT}080%g;
s%:9090%:${FIAMMA_PORT}090%g;
s%:9091%:${FIAMMA_PORT}091%g;
s%:8545%:${FIAMMA_PORT}545%g;
s%:8546%:${FIAMMA_PORT}546%g;
s%:6065%:${FIAMMA_PORT}065%g" $HOME/.fiamma/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${FIAMMA_PORT}658%g;
s%:26657%:${FIAMMA_PORT}657%g;
s%:6060%:${FIAMMA_PORT}060%g;
s%:26656%:${FIAMMA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${FIAMMA_PORT}656\"%;
s%:26660%:${FIAMMA_PORT}660%g" $HOME/.fiamma/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.fiamma/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.fiamma/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.fiamma/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.00001ufia"|g' $HOME/.fiamma/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.fiamma/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.fiamma/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/fiamma.service > /dev/null <<EOF
[Unit]
Description=fiamma node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.fiamma
ExecStart=$(which fiammad) start --home $HOME/.fiamma
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable fiamma.service
sudo systemctl restart fiamma.service && sudo journalctl -u fiamma.service -f
