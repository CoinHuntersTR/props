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
VER="1.22.5"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/dependencies_install.sh)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
wget -O nilchaind https://snapshots.kjnodes.com/nillion-testnet/nilchaind-v0.2.1-linux-amd64
chmod +x nilchaind
mv nilchaind $HOME/go/bin/

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
nilchaind --home $HOME/.nillionapp init $MONIKER --chain-id nillion-chain-testnet-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.nillionapp/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/nillion/genesis.json
wget -O $HOME/.nillionapp/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/nillion/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="3f472746f46493309650e5a033076689996c8881@nillion-testnet.rpc.kjnodes.com:18059"
PEERS="db7e7686053ab63cc99a4c5c41cf1c474aca4126@65.109.112.144:3000,c969177cd973dc7d55a605e21188303aa17298ac@65.21.22.123:26636,6a665f4a2cafa099eb3badd5ab79b4c5e5201d1c@65.109.58.189:28156,47b3c3962ec15aafea56f5d6203e66933df5ca34@167.235.115.23:28156,041d4c62350582775b5c47a61ef3432b07648e12@113.171.173.47:35656,2e18885c52363f1413e15b89278caa72f66654b8@216.18.205.178:26656,cee6c082868d790ee693cde486df865457b3459a@109.199.109.147:18056,716d70d81c2a9d62a32d6cc99f41fc1b488cf72c@65.109.228.73:26656,f3775e73d5e9b30d777caefeb9b7b69ed0b1bfe2@65.109.93.124:28556,c59dff7e20c675fe4f76162e9886dcca9b5104ce@135.181.238.38:28156,881376f895c194035109bf92245081729a0ac06c@65.108.233.73:51656,5f3f0e1cc9cbe14fa1a3c8d33b19a7d60efe7b8e@65.109.99.35:3000,5a5986767f0b752a3e40098950df2378cbe1a2bf@65.109.28.157:28156,e4855d41f3e66d961215d48ac8eabe309cfd4437@135.125.67.241:26616,a82a9f70707da1def94f26f423c30b18f2a87dd7@65.109.59.22:28156,89fa5b3cc6abdd096acbdf4d4c75d6d0e4406ed4@198.55.59.65:32600,ee3a6bb0f6645bd067db6e913a312ce84919d5e4@135.125.180.235:26656,ce05aec98558f9a8289f983b083badf9d37e4d44@141.95.35.110:56316,25d9320d62fd1987c10f6536924e0ddddbbd7cf4@141.94.143.203:56316,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@213.239.207.162:18056,c0715da9d20a37416570a3f9ae7da903e86dcca0@148.251.86.17:28156,98c9bdaccc45cf9e74163ea876b2c967e9345800@188.40.85.207:13556,2d229cf3f683426499dbf473991d822ceef0fba7@95.217.5.38:26656,ff7403e51b9dd4403af666d7ae096c870442aba0@176.9.155.156:32656,cbdb3fbdfea960907ebf7b030d4cfaec8d80ab0e@65.21.134.219:18056,41b8534d86df5e24a2b3b191d82be70d8663ec46@37.27.69.160:59656,a98484ac9cb8235bd6a65cdf7648107e3d14dab4@95.217.74.22:18056,5d756d42d59783bb8f35a4cc84a070db013c6605@5.9.102.58:26656,4c8ae0be3d5c42dbb79bfd85c3baaf0fab3760ae@66.42.32.152:58100,ad15097cd5cf91c7ed468f7f10b8c3c487df314b@157.90.33.254:44656,7c45187b46054403a03669b6f979c2e6f5dde1e2@63.251.106.84:47110,452c39b003d8417be8ac9012d2dcbdb674391abe@65.109.83.40:28556,7e6f4d7c9c75536a96f3dea3c8976b201073522a@167.235.1.51:28156,1f0910e8021748d24c943359b4f89c91800597e0@185.180.222.76:26656,044cc7bb60220b0bfde7f7bcbb40ad8a49a9f994@178.23.126.8:26656,7a4ec48f67a4ec089d8f67c4c7a220daa287b4bb@37.252.186.116:3000,03e0f620083e23cba8234ea30ae6d373ec7245df@62.195.206.235:26656,37b858e3dc887298e0baf2099f2248a339f070bc@37.252.186.218:26656,7931ad0fd25a71940f2004bfb2162b5a0a1e5ae5@178.23.126.73:31321,32558d10482b3b0afc5aecebd18c2f30f9f4847b@129.213.101.84:26656,4e6b935cc676921a6b214ff059c3ccb55a61baa6@65.109.112.148:13136,2f6b8e45dad8b4064c8cb7d5aaa6c8029aa2f478@138.201.227.119:18056,6d26bd11f391003dca9ab869bab202befcb6f1ac@51.89.42.98:26615,4d564a393bdd244642a624e9057cdd9c9b525ab4@88.198.7.204:54656,9acb87b68bc6cd6c8e0a40a26c225d5ad3acaa91@65.109.61.219:18056,bbf8ef70a32c3248a30ab10b2bff399e73c6e03c@65.21.198.100:24756,09f6c007dc3cd7d98dd9b80518580af0f1ace143@62.112.10.13:26756,7a0ef76a094be5278968462c8d665ade07fc070f@185.144.99.46:16656,35b7a71826bc5113c622d8d56a2b461325e0a89a@152.53.45.224:28656,17f439005782e23adabd7bacd6b1343b34218254@65.21.239.41:39656,6b56d478bb1c9ad8786884c72d85b1e28e1c9093@65.108.131.104:28156,2e8a1ae098407730904b46182f4958e392a9d340@65.21.205.217:23656,1e7dad6e9bdf3c468e171995fe320fbe14a8ed96@144.76.32.69:35656,1f0e5149298506e9d7b0f3e3e9bc6038bea1b96f@65.21.202.101:15656"
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
sudo tee /etc/systemd/system/nillion-testnet.service > /dev/null <<EOF
[Unit]
Description=nillion-testnet.service node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.nillionapp
ExecStart=$(which nilchaind) start --home $HOME/.nillionapp
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
nilchaind tendermint unsafe-reset-all --home $HOME/.nillionapp --home $HOME/.nillionapp
if curl -s --head curl https://snapshots.kjnodes.com/nillion-testnet/snapshot_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.kjnodes.com/nillion-testnet/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.nillionapp
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable nillion-testnet.service
sudo systemctl restart nillion-testnet.service && sudo journalctl -u nillion-testnet.service -f
