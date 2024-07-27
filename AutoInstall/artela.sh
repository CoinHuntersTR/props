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
echo "export ARTELA_CHAIN_ID="artela_11822-1"" >> $HOME/.bash_profile
echo "export ARTELA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$ARTELA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ARTELA_PORT\e[0m"
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
wget -O artelad.tar.gz https://github.com/artela-network/artela/releases/download/v0.4.8-rc8/artelad_0.4.8_rc8_Linux_amd64.tar.gz
tar -xzf artelad.tar.gz
chmod +x $HOME/artelad
mv $HOME/artelad $HOME/go/bin/artelad

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
artelad config node tcp://localhost:${ARTELA_PORT}657
artelad config keyring-backend os
artelad config chain-id artela_11822-1
artelad init $MONIKER --chain-id artela_11822-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.artelad/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/Artela/genesis.json
wget -O $HOME/.artelad/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/Artela/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="8d0c626443a970034dc12df960ae1b1012ccd96a@artela-testnet-seed.itrocket.net:30656"
PEERS="5c9b1bc492aad27a0197a6d3ea3ec9296504e6fd@artela-testnet-peer.itrocket.net:30656,a84cd3e3d401f7b853135a4ca786057c7a0b913a@38.242.157.138:26656,aa2e2400ead278c81b0a04b703eb51b604f4ddbe@185.255.131.50:3456,bd6564af6edf4693c0a0da976bc75559a83e48bd@173.249.19.35:25656,0fd485c04a08619558cae33e30c194f99abb8058@65.109.86.216:3456,3aa6155b72dc7d636d3f34e6f392f40c545bb78b@152.53.34.225:3456,065b81852b240c922e2a34ddd49a4a6059a9c80e@178.128.228.250:3456,6d1bc3d051c2e8eb2fe7df284cd505ab97eefcfe@75.119.131.252:3456,cf1df633664e847b0276c597c40724e0ef6a2338@109.199.108.52:3456,562da3a711b52a6464f621ef1286fccea0efb182@161.97.166.199:3456,6a93e8e3c1f7c7ab0cfa8cab42bd7a5ecbb1efe4@62.84.115.114:26656,09de87861c0d883be3fa8301936022f1285d7507@185.234.69.165:3456,33e7f2a3a82ca7bd6dc941be95cec2f9a128de61@148.251.82.6:3456,68398059b8be375fe760c5a45c0e6b9f46ee701c@109.199.114.153:3456,58514c1280eb7b0cc57881fa09f0a4d39a39e886@195.7.4.16:11856,87d7660909447800d61ec37863da377ac66de53e@116.203.49.2:26656,80ec96e0189ff4e18038ed63d6dc62da02be5791@37.60.234.91:3456,b83526e280f1180ffd2a7e648263680ce3d81103@109.199.101.247:3456"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.artelad/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${ARTELA_PORT}317%g;
s%:8080%:${ARTELA_PORT}080%g;
s%:9090%:${ARTELA_PORT}090%g;
s%:9091%:${ARTELA_PORT}091%g;
s%:8545%:${ARTELA_PORT}545%g;
s%:8546%:${ARTELA_PORT}546%g;
s%:6065%:${ARTELA_PORT}065%g" $HOME/.artelad/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${ARTELA_PORT}658%g;
s%:26657%:${ARTELA_PORT}657%g;
s%:6060%:${ARTELA_PORT}060%g;
s%:26656%:${ARTELA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ARTELA_PORT}656\"%;
s%:26660%:${ARTELA_PORT}660%g" $HOME/.artelad/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.artelad/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.025art"|g' $HOME/.artelad/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.artelad/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.artelad/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/artelad.service > /dev/null <<EOF
[Unit]
Description=artela node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.artelad
ExecStart=$(which artelad) start --home $HOME/.artelad
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
artelad tendermint unsafe-reset-all --home $HOME/.artelad
if curl -s --head curl https://server-4.itrocket.net/testnet/artela/artela_2024-07-27_10641053_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-4.itrocket.net/testnet/artela/artela_2024-07-27_10641053_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable artelad
sudo systemctl restart artelad && sudo journalctl -u artelad -f
