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
echo "export ALLORA_CHAIN_ID="allora-testnet-1"" >> $HOME/.bash_profile
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
wget -O allorad https://github.com/allora-network/allora-chain/releases/download/v0.3.0/allorad_linux_amd64
chmod +x $HOME/allorad
mv $HOME/allorad $HOME/go/bin/allorad

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
PEERS="ad3a6b49bf0c3e082be5ab2b116e622b795b1f1e@188.40.66.173:26756,ed0e6f02831ccdc09dfb4e4e9f703d373486bc82@43.157.20.64:26656,80d99208d70da18f8a587bda1023acea96343921@195.189.96.111:57456,b8834ef44bc2eeb4074a14140d060b80bcab8836@65.109.30.35:51656,54e77ab7453edf9d8fd4287299a6db2a3359eb81@147.135.140.50:26656,ecdc0dd7eb691a5fbecb8c135b26a81093587914@37.60.225.68:26656,d6433023d050106e5701d04976298e389f429e44@185.211.4.159:26656,6bd00668f433787d8418f9d9a477ed1f311d494d@15.204.101.36:26656,b6c61a01c7ae734040196d1af0444f2793f41d4d@5.180.149.123:26656,5824e6b74b403316b5775ce78c0713c3c4cb56cf@45.159.228.165:26666,8e81ed8901ea006ea77b9145cca62b73dc0463e9@5.189.146.38:26666,d0e12a195ac8acf6c76eb941c91fb373a2d526d5@160.202.130.101:32120,168c7323b0b7ac9a59726ebc811f22a4e137d8a4@195.201.245.178:56286,e18c50dc9a3e0b6641f87b5f3cd1c2576cfebf75@158.220.127.34:26656,0f6b64fcd38872d18a78d89e090a5e6928883d52@8.209.116.116:26656,11413d234e449ff3fefbad2df285a9b2b2601e0d@160.202.130.73:32120,0bf7e1489140434d9052782a54e87badfddf4bfa@40.160.12.223:26656,a525da291a42a22cd0a49a90bdb68809ab224224@95.217.107.21:26656,504a015fca790f94ee1498979248ce9718185c36@185.144.99.11:46656,2339ddf13f6d8ae2c78a0d0bce8001a19ea2f38c@15.204.101.34:26656,0106da2efccb6f3a15742b4e17faef782c37af52@192.145.46.179:26656,2aa399f7e07bec1668db56be94acc051cd1f7d24@45.149.207.19:26656,870d2d7c6235b1bb3603dfd6069e90a8204318f3@95.217.196.224:26656,c13dcf555ef6f71a8982bc38be0762d6d41e6e00@108.209.102.187:26643,d3c79122924ff477e941ec0ca1ed775cfb01ca20@66.35.84.140:26656,f6181ceff0ad0d99ed709e805785c6f54a3c67b0@149.50.102.86:51656,8e027355eb7fba531f9fdc5cfe5829c70644b2f4@15.204.101.31:26656,a63107a2244cdd2e5a1328e6edff130abaaee1d4@15.204.101.28:26656,e158a85ca8fbcef5813736f8ef73e308a0ad2b3a@15.204.101.35:26656,a07f51deedbd15bec9fa2fc6aff0001511292446@185.237.252.118:26656,bb94a8d60f24e4f1ba34d99eb434f7b486f4e432@34.69.129.28:26656,e40801e60d93cda37ca5e163d036231cde0fe924@88.198.52.46:26756,f7b402b0969bf7328405e40a57d650f1ac20795b@108.209.99.65:26670,e0f529d43ab666fa6fedc755b447a0e6bd3a5348@202.61.203.5:26656,21f44f233527edc5a7e1785a57e7ff27e2f586cf@198.7.119.28:26666,b77f7722b89b5c672a7333c5f0c05d3e04e7eb89@15.204.101.32:26656,6add5071ec8460fb3fd10f7872ca5f66946798f5@185.234.71.196:26666,e963d6e9740b890bc21fe4957067598f574f52b4@35.228.254.77:26656,2565f8b80bee76b4e26c61b8c5df70d33783bbd0@52.27.124.13:26500,6f98707b7cf8e03ceff83ed5343a0aec74b57aed@37.27.53.176:26756,a1fc36c042ceb9c4a40210bb09e306c3058eb55d@103.19.29.228:26656,4764a306e1dee4290ca7f0b82b4545d742f6c6c3@202.61.239.113:26656,1e130e11095ed43d65bc9158bbcb6df9ec937f90@160.202.130.77:32124,c05cf6a8a99e2aef91134f4d580052c634f97380@198.7.119.10:26666,89ec173c61da9b32c7344aacfe72cc62e0b743a0@103.88.232.90:32121,cf71bbf831ac23f9348f6c3274a330d769229faf@5.182.17.72:26666,f4ddbf4f053141d600279ddb45e3c67ae8f5b777@160.202.130.23:32125,637077d431f618181597706810a65c826524fd74@176.9.120.85:26756,838a81ce3b3b8f05c30347142317809926e014c2@89.58.26.89:26656,6ab4b2324edc03805c91a3684bd7d86d6bc5e158@80.64.208.205:26656,e4f87c7fd5fac03a4bbea9e334a7d14079d764f0@62.171.168.129:26666,3b34414c3cfdc2fe0eaa468d5409c1515bad3bc6@185.216.178.115:26656,6c2304c75fa845077f2896a2dec7e1dbecf6abd2@160.202.130.93:32123,a13507afc590bd2db1094db1bb152c3d48493e05@37.60.230.101:26656,338cbb34b97db64c4e6b1e54951a0f63f563d883@89.58.29.166:26656,d91f20e86fd247944f7346b199dbd861cf26cf6d@89.58.46.152:26656,88cdf4101019e8da271c944e4bde49d96f93072a@46.38.236.213:26656,b892fae8b6c39740353cf941d591e1414ffd9928@84.46.246.74:26656,6bbc4888c720760ebac79c8492411d8c1be1c07a@144.76.201.45:26656,3d4294c16a9d058fab571e82e9e52fe80736b259@202.61.229.11:26656,66ea64ffa2628643124905de9a38f3091f57a975@94.16.111.200:26656,5f0ee08078930c50d876a43e88215850a149684e@161.156.170.197:26656"
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
if curl -s --head curl https://snapshots.polkachu.com/testnet-snapshots/allora/allora_788676.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/testnet-snapshots/allora/allora_788676.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.allorad
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable allora.service
sudo systemctl restart allora.service && sudo journalctl -u allora.service -f
