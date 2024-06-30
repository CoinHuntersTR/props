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
echo "export AXELAR_CHAIN_ID="axelar-dojo-1"" >> $HOME/.bash_profile
echo "export AXELAR_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$AXELAR_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$AXELAR_PORT\e[0m"
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
rm -rf axelar-core
git clone https://github.com/axelarnetwork/axelar-core.git
cd axelar-core
git checkout v0.35.5
make build

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
axelard init $MONIKER --chain-id $AXELAR_CHAIN_ID 
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${AXELAR_PORT}657\"|" $HOME/.axelar/config/client.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.axelar/config/genesis.json https://snapshots.polkachu.com/genesis/axelar/genesis.json
wget -O $HOME/.axelar/config/addrbook.json https://snapshots.polkachu.com/addrbook/axelar/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:15156"
PEERS="133586120b9f5cf1c8608e843723897cdadbc422@18.217.111.172:26656,ede1009f5dc170ea1a22a0ffac2b3861e49b685f@135.181.5.106:46656,54e0c474ba49b1e78b09c9eff1a39ca3214c65a8@185.163.64.143:26656,9d5e55b2361fedeb2f724339a710d31f048f6ad2@3.142.113.84:26656,d7109b1154fc27b3fe93b96c7ea240e51e04edf9@141.95.99.154:26656,d80d8b31cb6ce5fcace42284fa6bbcab446670f7@195.201.175.156:15156,e726816f42831689eab9378d5d577f1d06d25716@169.155.47.127:26656,dceb5f821f280e4b31e6417a11321fc626e818c3@65.108.234.28:30056,3ae54d00de3678562ad7cbeba117ecc7adc84a82@37.27.56.238:26656,113a7518fd62c6574b9cefd04958362f6a8010a2@44.195.76.177:26656,07b6b1689fb5cc38a80c2e82623f66ab8ddc3f78@65.109.23.53:30056,97e4468ac589eac505a800411c635b14511a61bb@169.155.46.231:26656,99ed04bcbbbef0b668b99a722a47716e2b3625e6@142.132.248.38:26656,401b7bff144f0abbaec81f9d03fcdc8f2cd64a72@185.248.24.39:26661,2f3277dcf83378a0454b802cbf8b93d777154b72@135.181.138.95:12010,ffb4ed18e8d83a9c1e64904847d43f893c4b79f3@15.235.115.149:10200,f7061dc29a0ac18567848c1654e01b6a7a263051@51.158.156.171:36656,d80a505b12a5f492a349a87f348e8ddd311ca2ba@34.75.115.166:26656,d1d9761737f3008bfa6e48f356ea4f40073ef4da@84.244.95.227:26656,b5ff6dd26012bae1cf3a2d886b250d5970b3b921@35.215.17.194:26656,8b01374e8acc86762f5dbe24722db22e88d495bf@3.142.113.84:26656,41a950fe30bb90c57729c02ea1272779691b4233@65.108.230.188:15156,4c1ba47004df3d21a83cf8fcae5b5573dc3b9159@167.172.170.239:31816,2f8308f82bf9cd9592361f0fc35676bd1b258557@15.235.87.236:26656,fddf82006ad3a53c92ed8014a8424e7f8d071ed3@18.217.111.172:26656,b8281c06d822a73b8058f7f041209304fb26bd15@88.99.69.61:26656,85f9e85278088809a5f07fa70ff42f9738280f84@212.8.243.151:26656,0045e015ce55fac76c15c3bfc2bab5390dc85da9@147.182.154.5:26656,aebda30588d534b7637404a05dfa29078f5e5b0d@65.109.19.235:30056,82bd25371c9b90c2b778533b6d18c1092642af4d@65.21.138.124:26656,61960073f49e5e9050d92055630347fd8035decb@162.55.99.91:17356,6ce40e504e2c16b2260bd04a95e692ed86dfe73f@35.212.254.227:26656,6af94a2db0ef3693558bb9c37dcae3ae1a18a1c6@65.108.71.188:30056,612490f6f358ee83ec7993bed95dba7f7e037a42@136.243.55.115:20604,e665c8ab1f44902bb584a587838b483e1ed47e3d@13.59.129.55:26656,590a6723091c9f7049227b043bcbe84bdbcf3b57@198.244.165.175:15656,4fff1cbb8ea9ffc6d9989b3f447c00b64d22c027@13.59.129.55:26656,8fa3beed40bd434a5bdaff54dc1453f820f1da22@162.19.170.178:26656,cd1513651734f2a88efda2b7461822508384786d@95.216.98.97:30056,fa368ce87ffefdda9c423c781f35f995845b76ac@158.247.226.255:10200,a68c2dac704a81cc34f47f70ce8f8c2c9563361e@148.251.9.235:46656,e0aa35bdef2c00fca45e6dea19cfe05defd3119f@176.9.157.48:30056,4de49e3121d94640b92b072b45a4febe55e7c0b3@159.69.72.220:17556,94525f8447cd1c72f3e5456e5abd91ee6320e8df@13.59.129.55:26656,ca4c3e4d732149ec18b2da3b26030860fbf0615a@5.9.142.147:26656,d1a7fe36f5e3566b9c0be4b208309cd18e8d46f4@13.59.129.55:26656,0e7401a8c1517e9cb564e779e2387f5b447709ec@65.108.236.147:30056,c17c764f93d320b0db0afd8e44d92f5e8ae41513@176.9.45.137:26756,aa9ef97f821e322fd9f1829a545f5091252110bd@88.99.61.100:17356,8ca1bd7bdb23f6f6bc120e67a99927f5606c63fe@46.4.81.53:30056"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.axelar/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${AXELAR_PORT}317%g;
s%:8080%:${AXELAR_PORT}080%g;
s%:9090%:${AXELAR_PORT}090%g;
s%:9091%:${AXELAR_PORT}091%g;
s%:8545%:${AXELAR_PORT}545%g;
s%:8546%:${AXELAR_PORT}546%g;
s%:6065%:${AXELAR_PORT}065%g" $HOME/.axelar/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${AXELAR_PORT}658%g;
s%:26657%:${AXELAR_PORT}657%g;
s%:6060%:${AXELAR_PORT}060%g;
s%:26656%:${AXELAR_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${AXELAR_PORT}656\"%;
s%:26660%:${AXELAR_PORT}660%g" $HOME/.axelar/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.axelar/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.axelar/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.axelar/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0uaxl"|g' $HOME/.axelar/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.axelar/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.axelar/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/axelar.service > /dev/null <<EOF
[Unit]
Description=axelar node
After=network-online.target

[Service]
User=root
WorkingDirectory=/root/.axelar
ExecStart=/root/go/bin/axelar start --home /root/.axelar
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
if curl -s --head curl https://snapshots.polkachu.com/snapshots/axelar/axelar_13362214.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/snapshots/axelar/axelar_13362214.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.axelar
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable axelar.service
sudo systemctl restart axelar.service && sudo journalctl -u axelar.service -f
