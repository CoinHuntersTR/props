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
echo "export ELYS_CHAIN_ID="elystestnet-1"" >> $HOME/.bash_profile
echo "export ELYS_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$ELYS_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ELYS_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.21.3"
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
rm -rf elys
git clone https://github.com/elys-network/elys.git
cd elys
git checkout main
git pull origin main
git tag -f v0.37.0
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
elysd config node tcp://localhost:${ELYS_PORT}657
elysd config keyring-backend os
elysd config chain-id elystestnet-1
elysd init $MONIKER --chain-id elystestnet-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.elys/config/genesis.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/elys/genesis.json
wget -O $HOME/.elys/config/addrbook.json https://raw.githubusercontent.com/CoinHuntersTR/props/main/elys/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ae7191b2b922c6a59456588c3a262df518b0d130@elys-testnet-seed.itrocket.net:54656"
PEERS="61d39d5e8d4bd313b6caf39af9e4a4714faab15a@31.220.84.185:46656,0f6914c83ae7eae97ec045ce518f11c567c8a2a0@167.235.13.19:27656,ae29d8da169214e201c03789858b4228b56a004a@148.251.177.108:22056,257b31358c31bf77d1cd49b8772486a14000fd43@148.113.6.190:27656,4f6b3bf5b8a08aa6538cccae42ec2b139071d821@135.181.246.250:3330,6012544a6bbdcab033abf731418fcc3351c37cff@49.12.150.42:26676,49c30f1628ee8c88eef2eefde5905a5e820662e4@157.90.207.182:38656,cf22dec11ff8aa44e117f6cb8832538d597c9c68@23.88.5.169:28656,43ab1d154b8bbc2fd7753f6f362a295e8921aeff@195.201.9.32:16656,0b06ebe3437af5443ab8a4cf6881380fb29a35bb@142.132.194.124:11004,40ec65e34f5800854c577bc9386ce82ed3fb4740@144.76.97.251:44656,3a69f577b14bb5e3829489881cc80841b785e092@116.203.129.0:26656,61284a4d71cd3a33771640b42f40b2afda389a1e@37.187.154.66:26656,c90ec2d8e3094eede3fb0fb9f59e101269ae28b4@149.56.240.152:26656,38bd0be88352b8bc63c06b34541e7b10b2937f10@109.199.106.37:22056,463805d557e309c599e25a1284c421919decec42@5.161.206.6:22056,3842927adc58f51710c07aad1a60fcf6835eae36@213.246.45.16:51656,cc9c11f2c95ce2163d35b6cf9471ac9d61b7b9ac@65.108.131.146:26676,bbf8ef70a32c3248a30ab10b2bff399e73c6e03c@65.21.198.100:21256,609c64cc50fb4ebbe7cae3347545d3950ea2c018@65.108.195.29:23656,57c605fa2f7796dd2371ab9ca412bcf9a57d3f71@65.108.106.168:10126,b9af9c74a03ed709a727f199437cb0e766497ed1@135.181.57.50:26656,8c971e7fed202339dc557c2170a5be125153436a@65.108.124.43:38656,60939e5760138c1db7cd3c587780ab6a643638e1@65.109.104.111:56102,0977dd5475e303c99b66eaacab53c8cc28e49b05@65.108.193.254:38656,cdf9ae8529aa00e6e6703b28f3dcfdd37e07b27c@147.135.9.107:26656,1caa4cf8b5f8b4de7b7ea452e185b2a05a2fe5b0@54.39.133.70:26656,c660d68197bd6a8e7e79e49cc0173bab87215510@51.79.82.227:1656,ae22b82b1dc34fa0b1a64854168692310f562136@147.135.104.10:26656,d44714649b79bbac0d6c7ab4845dd319642229b3@65.108.104.178:46656,9d8a37e005fa5075b7470635ff9d143dd01f9aa2@142.132.203.60:26656,1cd3163afca4ad48949afdf6f18133fd3181e303@65.109.82.230:64656,f7d68da9e8736c32b0803fa450800a6f6fe5b0c0@185.11.248.92:32656,dd6d1a91ac5b594637059cba8d9f497a02113924@65.21.221.109:35656,98143b5dca162ba726536d07a6af6500d3e6fe1e@65.108.200.40:38656,ba32dca92f614ec2df20ea4e7a10ce4fa85edc46@51.79.18.14:26656,349941e88921a69af2131a7586741436d9b45b2c@75.144.232.219:26656,8848e14fb6010db5b3756f1523ba28d0d2ca81be@65.109.36.231:38656,bd211d0423cfea1b85007acbc8f98398369e32e8@195.154.91.84:56656,f3230e2103911d7712d4a43e3d21b00e1ff264fb@37.252.186.197:26656,abe62275d5558e84a6d01ed93e074cfce5d08545@152.228.227.105:22056,32a86c315244b0be07ed3ddb58504945ada3fe3f@154.53.57.227:26656,16c750650e247bb6d5ac40fbf196ed2485ca24b0@116.202.85.10:32656,9b1ddb68995037c3560c055da540756695d289df@141.95.106.99:26656,a5aab91db94ee20ca6f4cf5b80cc4d39b7cf237a@65.108.13.154:38656,eb0d0e8fe3010b86c09c5b94debd8c4719677422@167.235.12.38:07656,637077d431f618181597706810a65c826524fd74@192.99.201.123:22056,ba67891c552eb816fb37d27a12f5fbda6e05b68a@195.201.164.37:22056,785b08b7ca043258a22cce6c9f04a2a6e2316157@46.166.138.194:26656,ff0666aad4e881e502674e1a3e042f517d5a45e8@65.109.21.230:26656,75b5de35ce3d7ed34798ef48730d3e65f6fb9ec3@89.39.106.38:22056,4b1b36179e6d7117e657310eeb9cdcee9b426286@57.128.22.76:60056,b06c8ad5bb82d577acd0060242e225980db88377@65.108.225.70:26656,f6c5c2fa7981cae2a5deb73398b39e2cdbc8177a@88.198.46.55:38656,e8b4a9303c77d1c96ba2ecca28919619f9fa308e@162.55.135.119:26656,40eb6a89b6fb0e3a0282e9d93cc0ebd3fa65fedf@148.251.91.158:22056,0f3ff74800579700d492b3835a3ef66081882eb9@159.69.74.237:22356,86987eeff225699e67a6543de3622b8a986cce28@91.183.62.162:26656,5c2a752c9b1952dbed075c56c600c3a79b58c395@195.3.221.9:27296,5ad39c5d8fdefcc6eb740b9df62417991316d109@95.217.113.104:36656,bfcb384007647e50e02ab6a756deec9359c631dc@136.38.14.166:26636,501767323c5223bfe138d916189cb5427f7e3931@104.193.254.42:27656,206b757cacdee9515c8969906225f5bfa94220ad@195.201.195.61:33656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.elys/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${ELYS_PORT}317%g;
s%:8080%:${ELYS_PORT}080%g;
s%:9090%:${ELYS_PORT}090%g;
s%:9091%:${ELYS_PORT}091%g;
s%:8545%:${ELYS_PORT}545%g;
s%:8546%:${ELYS_PORT}546%g;
s%:6065%:${ELYS_PORT}065%g" $HOME/.elys/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${ELYS_PORT}658%g;
s%:26657%:${ELYS_PORT}657%g;
s%:6060%:${ELYS_PORT}060%g;
s%:26656%:${ELYS_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ELYS_PORT}656\"%;
s%:26660%:${ELYS_PORT}660%g" $HOME/.elys/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.elys/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.elys/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.elys/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0018ibc/2180E84E20F5679FCC760D8C165B60F42065DEF7F46A72B447CFF1B7DC6C0A65,0.00025ibc/E2D2F6ADCC68AA3384B2F5DFACCA437923D137C14E86FB8A10207CF3BED0C8D4,0.00025uelys"|g' $HOME/.elys/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.elys/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.elys/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/elysd.service > /dev/null <<EOF
[Unit]
Description=elys node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.elys
ExecStart=$(which elysd) start --minimum-gas-prices="0.0018ibc/2180E84E20F5679FCC760D8C165B60F42065DEF7F46A72B447CFF1B7DC6C0A65,0.00025ibc/E2D2F6ADCC68AA3384B2F5DFACCA437923D137C14E86FB8A10207CF3BED0C8D4,0.00025uelys" --home $HOME/.elys
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
elysd tendermint unsafe-reset-all --home $HOME/.elys
if curl -s --head curl https://testnet-files.itrocket.net/elys/snap_elys.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/elys/snap_elys.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.elys
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable elysd
sudo systemctl restart elysd && sudo journalctl -u elysd -f
