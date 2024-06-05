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
rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.7-rc6
make install

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
PEERS="5c9b1bc492aad27a0197a6d3ea3ec9296504e6fd@artela-testnet-peer.itrocket.net:30656,c3a0fba453eaf36a5c0d947b1a0dd9a947021781@31.220.87.218:26656,51f9fbb10f25dc50d7d2889ca822c927f7285b30@38.242.134.178:3456,8b7197aef087a286bdb16ea576f193958dc60f6c@173.212.240.21:45656,77240cdc1ca4d2f1443d353db09feff32a05f5fc@109.199.101.235:3456,2d05a43b48a3b0a83d098e40550e6d3c7b54f2e3@89.23.121.197:26656,196bc7b37309b3cf07a7b6f38cfafa43a81836c8@86.48.24.249:3456,a17c20532ade4da93bf79584e09966c0435e77ed@223.16.180.226:3456,8f85b1daa2b07001b2697829d3a86d056ec507f5@85.190.243.182:3456,8d5fd4e7f9a6c6ec7ee3bd05f0dbccf0bb4e7545@185.216.177.253:3456,1328a4b6bab05f261666aa9dd050d37dd5e42e71@38.242.201.217:45656,e0c08d7623b2a0dc5d37e01e201055c00fff6b9d@5.189.162.179:45656,722349c6f2be613fa6d74cdea7676db84da1f4db@202.61.201.254:3456,9bf0f78376f849e4c463232831d9f90864dc5e9c@109.199.105.150:25656,7fe7f73d4282f23136381ba9e8c5c606d6142174@202.61.229.11:3456,f8d09c28488760222ccfd2b0573278cf07090f2c@38.242.198.48:26656,34eb2e37fc33916c660d5a33a083fe7ddad77c34@89.58.55.104:3456,7893e0c798777d7fed32c0e516142cd25a2d79bc@173.249.36.218:25656,64fb37ba44085f78623b8c13f0aa12a479abce15@89.58.4.216:3456,1a64252bf8fa13a579fde10dfc0a07983340b64f@109.199.98.252:3456,7b3ec6b973718197393e59c59457bf8a43d69ba7@207.180.201.34:25656,ded3523e5482756e9ad1af15e8e77441758d84b7@152.53.46.83:3456,032df070c8abbc3c932d1c45bc0229cee42f1aae@143.198.120.40:3456,485d190a26ab77a0033b260b906a635185dd6f29@81.0.218.145:3456,9a3b4090f04393e9bed38caa03e791bf9b626733@207.180.222.233:25656,314c19013e9163880464074d3bce641b29bbbf45@185.216.178.115:3456,abbdd49907e2712cb0e97411c7af6b175e3df193@46.38.233.14:3456,e75731bea99f66e70bc6e5500edd7c32b67d744a@46.38.234.173:3456,40731967db351a536411c2ba63674bd0f986178d@210.209.241.155:3456,cb819317d418b587cf6cdf64dbcab8fd17747317@94.72.101.228:3456,d4ed29b7305acebbd4d9b09b8c0a1b282c40eeee@207.180.239.208:25656,3bdefb4715e78ef0df908cab3686137a8bbee830@173.249.15.201:25656,16fb76df7d89c95ea034d8c3b3a4adae7275ca95@195.26.249.61:3456,760f8de528fefccb62e742f253820fc91593b221@95.217.7.7:30656,bd6564af6edf4693c0a0da976bc75559a83e48bd@173.249.19.35:25656,31582a1e8ee7276e9a669dcfb609e2d4f47b029b@193.164.4.110:45656,2d68fc025d76d2312f7dd0e8a81a9c18ddf35d98@49.12.60.232:26656,1a46d742677398b82c94bca437895994f42ec73c@37.60.251.211:27656,c6c019048cfb3e0605d6fdc095593f3d7118476e@202.61.226.0:3456,9ace11332adb580c5e9c2374f67912257e06b132@109.199.105.143:25656,f896f3bc44d93276cd2567f71bde22d95dc31f8f@38.242.142.199:23456,2301d24d2fc3d24e5ffc738cd566b91645285b4d@202.61.251.119:3456,e558fe31993005a10cc31bd03832cab654b7e91f@45.157.177.49:3456,f17c630441f8391089c2b8db3c55ab7d10ddef42@37.221.195.187:3456,776ed7e579e7418b95cb3c1fd0ac32622e08abf0@202.61.193.234:3456,0adf028e6f05562f16a11ceab6190837ef08658c@37.221.195.234:3456,16408ed57fc59c99d8489934e95970fb28a8f3e1@5.189.186.227:25656,38bf2c55c20cd81eba599f3a7f9e57cc87606e96@89.58.42.84:3456,6a3558d74fa964e0431d289b0d94a67561f72de2@85.10.211.120:3456,1c299d3261c5b66383d454c51228ef3c7b62e575@109.199.125.5:26656,55f27297790beba8c0c2a72b412c111ac6dedde1@173.249.29.163:25656,0cb0662c62066ac78473f37673b53fd0bd8c0552@185.233.107.30:3456,d565aa328e3517d73b012e85975c98e44583fd47@193.24.211.121:3456,421a759bd6aaf700ace2c6e85157d0254226ac58@46.38.235.183:3456,32d32a7aa44191cb290dc2983513ff78ce1607f0@209.145.62.79:3456,b77f0acba0d7ae302ad4745fede92115cd47973c@202.61.203.86:3456,57fb3a944263b2bcc3e11b4272afd716c68930f7@94.16.110.148:3456,6f282810194578f46b76ea72dfa684f049bd9c89@45.83.105.135:3456,2961de689034c890e744c5fcffc69e37f63fd233@202.61.237.88:3456,0cabe01a4dfcef4f3105a575a5bea58b0310d7d2@185.252.234.24:3456,d1d43cc7c7aef715957289fd96a114ecaa7ba756@65.21.198.100:23410,4fb0ae560b9db184fa2fd4baef9bce3d2fe405d0@159.203.41.68:3456,698b6b26a926b518e898d61f364ab02a7ba34c0c@152.53.22.117:3456,6bbde25b5a6596895e1e0b8b9d64087c47151ebb@84.21.171.36:3456,d93e20a018655c24433df3336e9b0a31b14dace1@185.163.116.147:3456,ac017a948dbceaa6d32c22bb66526db9ca32aa02@109.199.105.121:25656,f354b9109233b28c893c1e021e4ce3146567af74@194.13.80.26:3456,cb049bd978e3ff0b06afe484892a8e365cb3d341@202.61.227.203:3456,5b77a3513fe0c64d71481465ea18584ee87492e4@173.212.220.218:25656,c0bd8c98fe87619eb13a63ddf2bb15e7da64c80c@66.94.112.163:3456,a543d4bea035cdd94ac359e57ec3b946a02d6ae5@173.212.198.7:3456,97f783daa39cbc9e872a184e9fbbec1a224434f4@202.61.239.113:3456,e5cd9d07b636f94a7d6f0c93b1233ea695e0e750@46.38.238.119:3456,8effff8800a65594d1459e2f49fb6e6544bb0b46@152.53.23.168:3456,bbb7d2c565e8c7c2c2aa460a26b0dfb03e17e5d3@104.32.197.159:3456,b444df551c77f202311bd065744be0a134e6875a@43.153.109.9:3456,0a69a8fa221ca6fa535af468176c165a10de6365@170.64.170.231:3456,e0e8bb86b595283ef87bfb4c0e518572064cf0e3@173.249.40.47:25656,6406e7f15cab6fbcdb47f0a99155ef61fdef6cad@207.180.240.170:25656,7879372819887d27f9c66c9db4769c7f03bb9a18@94.16.115.193:3456,a62f3c76b1c566f13adde27ae010b29f7941537d@173.249.30.136:25656,058fda1a93e2373c547bb43f7cd8f02a398ae491@170.64.173.237:3456,98cf95ceb6fa6b4c895829550b02dfed22142739@123.202.71.232:3456,a9f2fe2606873e3fade9bcdcbbf86e6452fdc2d1@8.219.52.182:26656,4dd77ccc0a3e1109538fb6cca405b06fa1c6f3e8@146.190.246.24:3456,6463b1f377557f2f55db3ae5c6cbe59ea36353f0@202.61.228.221:3456,0b65429c41841108c9bc0738dd585c3d26696687@89.58.58.237:3456,1ca786ddb9535fd51d877374a38a5826b8bf093c@152.53.21.184:3456,dd1753485f6e46cd8ce1bd780e2fbe0bbf5c60c9@37.221.199.185:3456,02b64f78e2a83a1bd9db0589479ca6e74ae827f9@202.61.251.214:3456,cfc5a5834ae85ade9b2ced1735927af89249ab45@161.97.122.190:3456,4fb7c57db112d45aebae0967a7e3698822b725f9@158.220.91.106:3456"
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
if curl -s --head curl https://snapshots.coinhunterstr.com/artela/artela_7964034.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.coinhunterstr.com/artela/artela_7964034.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable artelad
sudo systemctl restart artelad && sudo journalctl -u artelad -f
