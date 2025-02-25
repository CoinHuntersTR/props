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
echo "export WALLET=\"$WALLET\"" >> $HOME/.bash_profile
echo "export MONIKER=\"$MONIKER\"" >> $HOME/.bash_profile
echo "export UNION_CHAIN_ID=\"union-testnet-9\"" >> $HOME/.bash_profile
echo "export UNION_PORT=\"$PORT\"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$UNION_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$UNION_PORT\e[0m"
printLine
sleep 1

printGreen "1. Updating system and installing dependencies..." && sleep 1
# Update system and install build tools
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

printGreen "2. Installing Go..." && sleep 1
# Install Go
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.5.linux-arm64.tar.gz | sudo tar -xzf - -C /usr/local
echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/dependencies_install.sh)

printGreen "3. Installing binary..." && sleep 1
# Download and install binary for ARM64
mkdir -p $HOME/.union/cosmovisor/genesis/bin
wget -O uniond.tar.gz https://github.com/unionlabs/union/releases/download/uniond%2Fv0.25.0/uniond.aarch64-linux.tar.gz
tar -xzf uniond.tar.gz
chmod +x uniond
mv uniond $HOME/.union/cosmovisor/genesis/bin/
rm uniond.tar.gz

# Create application symlinks
ln -s $HOME/.union/cosmovisor/genesis $HOME/.union/cosmovisor/current -f
sudo ln -s $HOME/.union/cosmovisor/current/bin/uniond /usr/local/bin/uniond -f

printGreen "4. Installing Cosmovisor..." && sleep 1
# Download and install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.6.0

printGreen "5. Configuring and initializing node..." && sleep 1
# Workaround mandatory home argument
alias uniond='uniond --home=$HOME/.union/'

# Initialize the node
uniond init $MONIKER --chain-id union-testnet-9 --home=$HOME/.union

# Set node configuration
uniond config set client chain-id union-testnet-9
uniond config set client keyring-backend test
uniond config set client node tcp://localhost:${UNION_PORT}657
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# Download genesis and addrbook
curl -Ls https://snapshots.kjnodes.com/union-testnet/genesis.json > $HOME/.union/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/union-testnet/addrbook.json > $HOME/.union/config/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# Set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:24656,3f472746f46493309650e5a033076689996c8881@union-testnet.rpc.kjnodes.com:17159"
PEERS="ea80b3d17264ddd25f0fe7b5b72b06a785be0be7@167.235.1.51:24656,3aee03b96615e601cd9814427e8bf61ffe85f916@109.123.247.139:26676,4d174c7e7b65f0c2794e70128e3c82845be74b91@185.239.209.46:26676,f10f294f12d30cdd2f7547a8b5f527fe02645ae7@62.84.189.221:26676,b876cdb1e88e3ee5051a57171b651ce2d4edf90e@195.201.110.148:26676,2e44e20b8c183d66ab7d3891a5cec2e4352bc26b@81.17.99.121:26676,91725d5dd47c84ab1b710b90945d511e0db29a4f@38.242.239.89:26676,06de8a52cd5fcf6144d534129e3bc5b8ca2966b7@65.108.105.48:24656,39b18c2be0a3d3e286c1a0ec050bc3ec2c513da9@159.69.107.234:26656,1caf96832c13260a3c4cf51854b001f95a2f05e5@77.237.245.144:26676,e32580e23c56acecd91c474f17abb62ab2ded2b7@81.17.99.138:26676,8286a9df6b3d9466f5a1f22283ddb574c28988b6@23.88.101.17:26656,651b3698131a9c32f46556846017ce013c5c2980@167.235.115.23:24656,0dcca130568caa282646f8be453fb024fabf0888@94.130.54.216:24656,57d817a99049c963e1adaed7735cbd1ce388e912@16.62.79.119:26656,224d5e36f4bb6e47ff1633d09c3c122dfe64d256@158.220.111.164:26676,4eedbf8e9d31b933e7aee23b917c100d986fbe83@185.225.232.58:26676,aa65aaa93e2821e20cf4a98d0db91f7f95b0894c@62.84.189.205:26676,88b8722e2553d86f558511ccf1341a235e97ace1@212.132.127.92:17156,0af46a138c052681ec5207eafd12ef6d1a4fe923@116.203.244.7:443,fc298834ad65b495cd8162e0ec97c3adf0a14739@62.84.189.199:26676,c51bbe61ee15320533837b37268c16393d8d8b54@94.130.105.107:26656,4b81ca0a131659f316cfb8f7c755b2ada3e276ea@157.90.170.177:26656,fa8ea2656c30daf4f8cb6061de48858658abe955@109.199.98.235:26676,472cbc6f3c3106f3af83f1725253f435ac12f4ec@62.84.189.204:26676,7d689e93d212768ed97861562bedb08233efc182@45.84.138.63:26676,bc3219af3428306fac33fa1ad12367834ef175ab@77.237.245.131:26676"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.union/config/config.toml

# Set custom ports in app.toml
sed -i.bak -e "s%:1317%:${UNION_PORT}317%g;
s%:8080%:${UNION_PORT}080%g;
s%:9090%:${UNION_PORT}090%g;
s%:9091%:${UNION_PORT}091%g;
s%:8545%:${UNION_PORT}545%g;
s%:8546%:${UNION_PORT}546%g;
s%:6065%:${UNION_PORT}065%g" $HOME/.union/config/app.toml

# Set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${UNION_PORT}658%g;
s%:26657%:${UNION_PORT}657%g;
s%:6060%:${UNION_PORT}060%g;
s%:26656%:${UNION_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${UNION_PORT}656\"%;
s%:26660%:${UNION_PORT}660%g" $HOME/.union/config/config.toml

# Config pruning
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.union/config/app.toml
sed -i 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|g' $HOME/.union/config/app.toml
sed -i 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|g' $HOME/.union/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "19"|g' $HOME/.union/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.union/config/app.toml

# Set minimum gas price, enable prometheus and disable indexing
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0muno\"|" $HOME/.union/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.union/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.union/config/config.toml
sleep 1
echo done

printGreen "8. Creating service file..." && sleep 1
# Create service file
sudo tee /etc/systemd/system/union-testnet.service > /dev/null << EOF
[Unit]
Description=union node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --home=$HOME/.union
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.union"
Environment="DAEMON_NAME=uniond"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.union/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF

printGreen "9. Downloading snapshot and starting node..." && sleep 1
# Reset node
uniond tendermint unsafe-reset-all --home $HOME/.union

# Download snapshot
if curl -s --head https://snapshots.kjnodes.com/union-testnet/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
    echo "Snapshot indiriliyor..."
    curl -L https://snapshots.kjnodes.com/union-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.union
    [[ -f $HOME/.union/data/upgrade-info.json ]] && cp $HOME/.union/data/upgrade-info.json $HOME/.union/cosmovisor/genesis/upgrade-info.json
else
    echo "Snapshot bulunamadı!"
fi

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable union-testnet.service
sudo systemctl restart union-testnet.service

printGreen "10. Node başlatıldı. Logları kontrol etmek için:" && sleep 1
echo "sudo journalctl -fu union-testnet.service -o cat"
