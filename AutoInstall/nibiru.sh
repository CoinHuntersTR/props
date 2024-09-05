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
echo "export NIBIRU_CHAIN_ID="cataclysm-1"" >> $HOME/.bash_profile
echo "export NIBIRU_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$NIBIRU_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$NIBIRU_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.21.11"
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
wget -O nibid_1.5.0-post.2_linux_amd64.tar.gz https://github.com/NibiruChain/nibiru/releases/download/v1.5.0-post.2/nibid_1.5.0-post.2_linux_amd64.tar.gz
tar -xzf nibid_1.5.0-post.2_linux_amd64.tar.gz
rm /root/nibid_1.5.0-post.2_linux_amd64.tar.gz
chmod +x nibid
sudo mv $HOME/nibid $HOME/go/bin/nibid

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
nibid init $MONIKER --chain-id $NIBIRU_CHAIN_ID

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.nibid/config/genesis.json https://snapshots.polkachu.com/genesis/nibiru/genesis.json
wget -O $HOME/.nibid/config/addrbook.json https://snapshots.polkachu.com/addrbook/nibiru/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:19856"
PEERS="b7262df35a7e1d1fb4027464efe9d9d6218ca4c7@35.233.111.89:26656,a36af139a487ffe939302b909ad7f502f2f11907@23.106.238.179:26656,b4d347b39b442571d9eb6a1a82bfebbb5fdf399b@95.214.55.138:24656,ba572c6156aefd0b0ac500bd5477ff2372d7ea28@141.94.195.151:19856,89757803f40da51678451735445ad40d5b15e059@164.152.161.5:26656,d1f31c6968712b2da1079cf0387153560d2f1cf7@95.217.204.58:19856,e7af24b15365bff9537e2776c2a5fdf01b933dc5@34.76.178.49:26656,d3c7f343d7ed815b73eef34d7d37948f10a1deab@34.76.80.206:26656,151acb0de556f4a059f9bd40d46190ee91f06422@34.38.151.176:26656,4f659d7db311a4fa2433ad372fa8c17850ec3bd7@185.218.124.63:26656,659e85aaf0bd4cbbfbe381eebc6b582f71d6993b@65.21.65.254:1510,637077d431f618181597706810a65c826524fd74@176.9.120.85:19856,05106550b6e738d8ce50cb857520124bbcce318f@34.140.34.185:26656,07faf6678cbcee9909348b6d705260f9ba6ca1ff@65.108.232.104:19856,0f3f1804f685c3d14f50324e5ff3d9ed2a058ec9@65.109.26.123:26656,dca62b1537a2a52a365328b5503b0ab9239f8bd3@95.216.74.45:13956,b4d347b39b442571d9eb6a1a82bfebbb5fdf399b@95.214.55.138:24656,200d3c6eec510a3bb5a4224d9be188df37032946@148.251.13.186:19856,29a570869025964973394b36f313169ca894ae49@49.12.36.72:18856,17de11d7867323b42e88191cd04cc46497c8d528@49.13.137.99:26656,6f893316be0168405c4abf45840eaf260d6e4145@89.58.14.189:26656,89757803f40da51678451735445ad40d5b15e059@164.152.161.5:26656,6d83a02cb6c37b6f4f3d3b6cd09c34a10f890a5c@51.210.223.84:19856,89d6003fa2e8f30cc57a4c73ee19b5450205297c@34.79.208.162:26656,e7af24b15365bff9537e2776c2a5fdf01b933dc5@34.76.178.49:26656,e5f0c47baa29c7c7806af5444beb60423d9cc56d@130.211.91.146:26656,b7262df35a7e1d1fb4027464efe9d9d6218ca4c7@35.233.111.89:26656,e80986ccc5306d237a30dfabe4aad3d9607a6d36@146.59.118.20:26656,d9ed6ced7f3730c2143195ff8c25764aeb1cadb9@213.199.43.133:13956,05106550b6e738d8ce50cb857520124bbcce318f@35.189.236.126:26656,c2af064e5c0d9fafde4a978d564a3cea447367ba@54.39.131.55:26656,7d8267a98d2d9d697a66b54e46f3897ba4336d52@150.136.9.100:26656,151acb0de556f4a059f9bd40d46190ee91f06422@34.38.151.176:26656,e726816f42831689eab9378d5d577f1d06d25716@134.65.194.77:26656,793924cae855dd98190288fe9cf817568c43b3b6@65.109.99.157:16606,36ac688b97e157b80328214ed5c1419d1d130819@195.179.229.249:26656,1f808c8d3b8dbc83a90df086810dbc06327705ec@49.12.46.96:26656,d1d70929925f2207abc54575ea0cb738f337989c@95.216.245.140:26656,efa09cacd33a8c0183c767ce52eb886b9519e246@116.203.209.229:26664,650d0b726e1f1de45e4d23d44f0709aeab2b5757@31.132.165.22:13956,5cc9267158950e8c02dc186846488a308f3125a7@65.21.29.115:19856,f81e315ca46436934f8191229da2b66ad727b74a@49.13.171.180:26664,0c1ea7a68f8f2a9ea31f715d78b1fde21fa6ee63@65.108.227.114:26656,6604179787139eab744b8a1159fee9b03fcc3714@51.81.49.176:19856,5ba763db9fc0d19447a821a97a57159dbf1b1eee@51.77.57.29:26656,58246b8334a7ea2db0458167a26082644a0d5d9c@65.109.122.105:36656,2cb76d06899e6f35dc525fccb42fb707b47ac772@37.59.23.17:55356,4f659d7db311a4fa2433ad372fa8c17850ec3bd7@185.218.124.63:26656,c416d67c3dbb2d30b803611469e6d2634099292d@135.181.210.171:11036,8b564f4ddd3e2eb24b1f321d7dacc03080c9c824@65.21.227.177:10026,a3c1da61f6e323ab7e6c8b2930e30eaea7105e0d@65.109.120.211:25656,8266479c2bb3a6b7163f7197736c9e79c4dcecf7@125.253.92.159:26656,07faf6678cbcee9909348b6d705260f9ba6ca1ff@65.108.232.104:19856,4e1c2471efb89239fb04a4b75f9f87177fd91d00@134.65.194.216:26656,8af7e835f928a8c5a77ca32812232c98a641c7d0@34.222.98.111:26656,e60265ed137e0880ae1335e1aaffa7f360c3b2f4@156.67.111.234:19856,5c0468c2d1ec9a75cd267a9875a6bdb970d470b7@150.136.8.210:26656,46fc3dab0ff7e3be021646464e1c603992cd361b@168.119.114.206:26656,74f2e690e1be83c189bf227c4c61b266267795c8@94.130.138.48:35656,3774f19a6e0765334ee2e9bee136d26050e6149f@95.217.122.104:15606,81b9c09ae1c76a3e7f36db91b98d1fbf1e31233c@185.248.24.16:13956,75d2372f7feecb7bf66a5c57302bea172c62a3d3@142.132.199.236:20656,05a7ef13f828589d3756ad3c05ffdedf2bcc48a9@141.95.35.228:26656,b032150972f3a9add47a0df33c6a69bbca4df59e@173.212.231.88:26656,c4c93509cff43c07876d4ddfe8db4ab23d63fc47@37.27.71.199:10656,d9bfa29e0cf9c4ce0cc9c26d98e5d97228f93b0b@65.108.233.103:13956,05c36c3e579d3fc5b0efaa44f5a197f7a96c09ce@65.109.104.118:56656,4098f0862f6d454f28a912e6987277889e8d23c1@144.76.40.53:19856,d3c7f343d7ed815b73eef34d7d37948f10a1deab@34.76.80.206:26656,f0ccacd7cd19f7c30c203ca4c9cbee62d4f8f773@34.159.29.250:26656,8d8324141897243927359345bb4b1bb78a1e1df1@65.109.56.235:26656,5802a8a4464998db345e76bb60931906cd4fb0f0@116.96.46.227:26656,405889c24b4de25ba618293a640a2396e202617e@213.239.220.52:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.nibid/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${NIBIRU_PORT}317%g;
s%:8080%:${NIBIRU_PORT}080%g;
s%:9090%:${NIBIRU_PORT}090%g;
s%:9091%:${NIBIRU_PORT}091%g;
s%:8545%:${NIBIRU_PORT}545%g;
s%:8546%:${NIBIRU_PORT}546%g;
s%:6065%:${NIBIRU_PORT}065%g" $HOME/.nibid/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${NIBIRU_PORT}658%g;
s%:26657%:${NIBIRU_PORT}657%g;
s%:6060%:${NIBIRU_PORT}060%g;
s%:26656%:${NIBIRU_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${NIBIRU_PORT}656\"%;
s%:26660%:${NIBIRU_PORT}660%g" $HOME/.nibid/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.nibid/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.025unibi"|g' $HOME/.nibid/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.nibid/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.nibid/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/nibid.service > /dev/null <<EOF
[Unit]
Description=nibid node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.nibid
ExecStart=$(which nibid) start --home $HOME/.nibid
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
nibid tendermint unsafe-reset-all --home $HOME/.nibid
if curl -s --head curl https://snapshots.polkachu.com/snapshots/nibiru/nibiru_11070258.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/snapshots/nibiru/nibiru_11070258.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.nibid
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable nibid
sudo systemctl restart nibid && sudo journalctl -u nibid -f
