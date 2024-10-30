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
echo "export PELL_CHAIN_ID="athens_186-1"" >> $HOME/.bash_profile
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
cd $HOME
wget https://snapshots.coinhunterstr.com/pellnetwork/pellcored
chmod +x $HOME/pellcored
mv $HOME/pellcored $HOME/go/bin/pellcored

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
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
SEEDS="e3abea7feb928a0470dfb06962213a2fb48bbbed@57.180.60.57:26656"
PEERS="e3abea7feb928a0470dfb06962213a2fb48bbbed@57.180.60.57:26656,3f5e2e7b2e5acb20bd9248875121ee5828f1b8d3@185.252.235.216:26656,5a95d9f89d3484c439a357bc7c276dd88f19ebbf@37.252.186.230:26656,8283c7a961c40223c6b8b152c3d7b93987336dbe@147.135.78.73:26656,eb58c53b359bfcace5898e4dd1a00c1c9d2175f4@34.44.209.45:26656,c5670c134030edf72493aad1591284aaa0ebc97c@171.226.129.85:26656,f4f97e7620c6bfa22574c538785a106053a25640@65.109.53.24:26656,8533ff42e9858caa386f3956433e0194278a3240@188.40.85.207:26656,0e176a983bad2d6c2ae216bc46b4315f9da35054@94.130.204.227:26656,2718def8e804cfef7ee5df4d83eba23f1fb9793e@194.163.133.231:26656,a6c7a522537b2bb2a9b946c1e6bc7f6a78731192@103.164.81.233:26656,15f92c0b31adf02d46de02610221ff3ddecfb80e@167.235.21.165:56656,d12f3b1680d1179322bbf5096d395ee3db496e33@195.14.6.169:26656,c7be87435d823439fe2261eab0e053bafc7a7459@74.50.91.170:26656,3599ca9ec1432d2e5386c12cd442648ff7b2e543@62.171.130.196:26656,1f365d37e0de430823a12b2d0558f938e7ee7151@65.21.28.38:26656,b7c36c14c1a1971ead5436e696902b6e869dbcd0@43.153.154.247:26656"
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
