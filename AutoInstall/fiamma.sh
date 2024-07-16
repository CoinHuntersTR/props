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
echo "export ALLORA_CHAIN_ID="testnet"" >> $HOME/.bash_profile
echo "export ALLORA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$ALLORA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ALLORA_PORT\e[0m"
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
rm -rf allora-chain
git clone https://github.com/allora-network/allora-chain.git
cd allora-chain
git checkout v0.0.10
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
allorad init $MONIKER --chain-id $ALLORA_CHAIN_ID

echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.allorad/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/allora/genesis.json
wget -O $HOME/.allorad/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/allora/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:26756"
PEERS="6ab26fac6411f8ec1079b80a19528ac3efeece8e@198.7.122.94:26666,929d2da8d945b2484d96d417e18e29a04585e8ca@188.40.15.86:26666,ff17e450e66ad9ba87d6c4c5cd78517cd66b3f1c@77.90.8.214:26666,0ee249a1521b1f114b45282ac87667e4da38cc47@46.250.238.197:26666,3584b56ad639bb46c20ec9e5d05f39b630c19c4b@35.153.182.229:32001,331abda77b26e70d358ab950f885edec3962e497@77.90.19.39:26666,cc1a0a2c70d610f45767aba510e78ac17ec17223@188.239.191.4:26666,85994a7ce8ca829f134a9fb474d09ebb9a347935@185.226.92.178:26666,9170769553648d4f53ba183475a699e70b0e4f17@116.202.76.203:26666,806e25d14bae04f605a1742ca6433bc8a67ec359@38.242.137.155:26666,ba271589eb1348d4f33b39b6c9ba925df3c11311@77.90.19.175:26666,99c10c7c5ccad59090e34d0fd181dc9b779f1fc5@3.235.8.174:32002,ae8692ee139838a410b452ad14bb468517ff3150@77.90.13.236:26666,7e57e810cf9da7251e10b30526bd2237f60d5281@213.133.110.42:26666,24969dffb2957dcef20f526e6721f57e811c6121@158.220.104.129:26666,4c62a28542aa8d2464d08c964b99459cadb5015d@116.202.76.206:26666,d5d0275285fa8033682d10cb7ab7500995d1c7e2@77.90.19.63:26666,56eb84f8235afe1ce0b21d2203d13b0b12853702@65.109.216.102:26666,374d338d5ddcbc4feb002c030abb9b8b1afcc87e@146.148.97.44:26666,ec52e29da4ba41fe01f7c1b095c5cdd8bac216f7@116.202.76.204:26666,11d79afdeeb09e3a3d96fc502809fe5233c97e68@77.90.19.41:26666,a2919076678b89c955477d8460c9c932bd9786e7@54.173.141.33:32010,de58e6e21f4780553c38daaf5c9486f6d9769856@116.202.8.20:26666,9d4af65dc51663706047ea2ba29ff20912d9b248@45.61.161.109:26666,8fee10649fa1a8d5af97340bd1dd0db3365bcc06@45.144.29.114:26666,2d1cee3d7b94935e099fda4c06fa68dd0259f642@188.40.15.85:26666,b006f212defdc389505e72e22a80fe9af459b2e5@5.9.173.20:26666,9a9f1eb12d575c9642f5ed525370f8234237e048@188.40.197.63:26666,d42629dfc1ba7733f782f9e6534c293b1c8114f7@149.28.152.142:26656,14fa5f19a654a57ac4c169055e915528a6317896@65.109.192.157:26666,919d7a3696ae7819db5733f5a927d44df2d96498@91.107.166.56:26666,1119ec09857cabd05061e038f5c3ae1124bc308e@157.90.41.253:26666,738cc77127f636480cd88d41dd6daecf3a5dbdd4@95.164.68.32:26666,cb6639365a849f402752d15151856457235effe9@77.90.19.193:26666,fce5934750d7c8602b76b50ec644a2e85fda9277@77.90.8.118:26666,bb8db894415c7616a12a6d8be879a514b76e379e@77.90.19.234:26666,f76bdd6440347daec98b905653616992eaed554d@45.87.41.22:26666,727f223ae1687dd5a30c782c6a8e5834fd1cf1de@194.116.216.99:26666,ce696067caa9057cfb69b3983e2ac8be76c524ef@188.40.66.173:26756,d7413d93711e08bdbe08261c1b64b64e7f73e10a@136.243.112.203:26666,b05bc141212b970d14ed6bb28576f409adfb9226@91.107.135.101:26666,bbb90f7c0d63e8591b979d6a9f01121f4aecf52a@5.9.195.53:26666,d0c1003a937019954af82141f090640b1630e10d@65.109.178.96:26666,07661f0f7ab2ba6329384cae5688349ee676cf2b@203.113.174.228:26656,df5a8aedb655d8ad41c964b38c3b13712570d0f2@65.109.195.214:26666,4ae32d3a5b48f679c46ed48ca5210ba56e712d55@49.13.240.190:26666,47cd15bbb0a1402a2d10762cf5ac4191c5b9b427@178.63.211.126:26666,d3148e3f121c3feba8cece11af8daf8ae4ae79a9@148.251.111.61:26666,a79b67cd9757639c7c1b9c14607f7220031f5a64@116.202.76.247:26666,0ac1afbaac7cd2b63b7651c71c6f70ae1ce4b519@116.202.76.248:26666,ae575e77dc4d73208c9ac2d7a5099b880a40f98a@162.55.74.183:26666,4e9773120c1272100201453f6fec44c4335dffb9@77.90.19.176:26666,1389b4cea21af0c044fa690f424755fa050083a0@144.76.26.62:26666,47e3f1e157e59f408c4edcc569719ce6170ceac4@185.222.241.175:26666,f9b1011e18c35ebc3c2e4e6bebcc5a8c818e05ce@77.90.19.195:26666,6639b472e30ccb3b0df88ca1c4be27e154b16b86@116.202.76.202:26666,b4cae2257a03ace6568c491eaa03a15191575a0b@34.32.212.52:26666,d62534abe9216501f1c10a496cf55eac0a500061@95.217.127.216:26666,6891f097f6e7e2510b423d64f61290f54c4b4113@49.12.60.232:26666,60c6b5b603b39c94f57311e921412e65c7afc744@45.92.11.111:26666,5d0e1d9e71c33b3a636e495b30af38b0019d0b7e@77.90.8.216:26666,3f55cf69ae985a7fee6c551a09ed17bb1a351eff@89.163.152.91:26666,4ac5a73ecf753856bf39946dd42905e3d37527a7@185.226.92.167:26666,c6a9472263b3bf96ee62c4b4e32135f35451fa78@100.42.184.145:26666,cc741eb8b6665bfdec94e0150ae4441c08482fa6@89.117.54.17:26666,edba530de897443848925293b33e9eb08730b025@45.92.9.160:26666,22702682e0ecf54f3038b03335f02c646f8b67b0@49.13.143.81:26666,a5522faf44b11b6115c27dbc5fa6d9d04ec1a999@144.76.201.45:26656,9d0e6bf898e067b99e616e2f61053146b214097e@109.205.182.250:26666,d86f95543c8dd7d80c5af15e25bf3f1799e6d608@116.202.76.250:26666,3ab9dc16dffbd3009ece285ae0809614cc6a907b@156.67.25.102:26666,80a60a9e31784fef7f1763960059c017299255be@77.90.13.142:26666,a17ba6b7f5da3c6850230d1b68b60cefab11fc7e@77.90.19.180:26666,19b4a49451c1b63d792f13dde5cfdd95ba7cd82a@5.9.173.17:26666,63533a806c50418beef5b427cb6781ab3aaeac65@45.136.16.194:26656,d415e7bc8889e3d2e9e176c87d3543c121f46653@77.90.19.181:26666,391f4c0e8c8992b1e4a3809215d8c1300a818fa2@188.40.15.81:26666,ebcfdb0f40190024d56acc6485554e4dcf1241c3@116.202.76.201:26666,3a423e2bfa833c02464172e5b5a8bfc4a325c079@77.90.8.132:26666,89edaf29fc603d43dc1cfc34ff52d91161d9e5ca@195.179.226.9:26666,38a6f16d1c36af1bc9ebd78b0238637eaee86ce3@77.90.2.179:26666,3f241d9a9c964155e6780c6dbf868cd5e13c8ffb@178.63.118.246:26666,650c00e4b256186efda4b6d35d34803ba4baa3f4@77.90.19.212:26666,3ab7c1e1461cbaaed7abc8059737897cd0fe7aad@194.163.191.230:26666,21aafe085a58f11fb4620421acdbdcb58ec9613d@91.107.170.199:26666,216debf675ad4a621741f2745bb7bd11f6562086@157.90.41.254:26666,ae63dc5d5144ce97b15b42742f3c15f59f110d46@95.164.113.181:26666,7deb1d2e78c2c1b04172b51343d052f06e7b92bb@147.78.130.130:26666"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.allorad/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${ALLORA_PORT}317%g;
s%:8080%:${ALLORA_PORT}080%g;
s%:9090%:${ALLORA_PORT}090%g;
s%:9091%:${ALLORA_PORT}091%g;
s%:8545%:${ALLORA_PORT}545%g;
s%:8546%:${ALLORA_PORT}546%g;
s%:6065%:${ALLORA_PORT}065%g" $HOME/.allorad/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${LAVA_PORT}658%g;
s%:26657%:${ALLORA_PORT}657%g;
s%:6060%:${ALLORA_PORT}060%g;
s%:26656%:${ALLORA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ALLORA_PORT}656\"%;
s%:26660%:${ALLORA_PORT}660%g" $HOME/.allorad/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.allorad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.allorad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.allorad/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0uallo"|g' $HOME/.allorad/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.allorad/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.allorad/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/allora.service > /dev/null <<EOF
[Unit]
Description=allora node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.allorad
ExecStart=$(which allorad) start --home $HOME/.allorad
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
allorad tendermint unsafe-reset-all --home $HOME/.allorad
if curl -s --head curl https://snapshots.polkachu.com/testnet-snapshots/allora/allora_2130038.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/testnet-snapshots/allora/allora_2130038.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.allorad
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable allora.service
sudo systemctl restart allora.service && sudo journalctl -u allora.service -f
