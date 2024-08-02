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
echo "export ZETACHAIN_CHAIN_ID="zetachain_7000-1"" >> $HOME/.bash_profile
echo "export ZETACHAIN_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$ZETACHAIN_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$ZETACHAIN_PORT\e[0m"
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
wget https://github.com/zeta-chain/node/releases/download/v18.0.0/zetacored-linux-amd64
chmod +x $HOME/zetacored-linux-amd64
mv $HOME/zetacored-linux-amd64 $HOME/go/bin/zetacored

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
zetacored init $MONIKER --chain-id $ZETACHAIN_CHAIN_ID
wget -O $HOME/.zetacored/config/app.toml  https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/app.toml
wget -O $HOME/.zetacored/config/client.toml https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/client.toml
wget -O $HOME/.zetacored/config/config.toml https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/config.toml
wget -O $HOME/.zetacored/config/genesis.json https://raw.githubusercontent.com/zeta-chain/network-mainnet/main/network_files/config/genesis.json
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.zetacored/config/genesis.json https://server-3.itrocket.net/mainnet/zetachain/genesis.json
wget -O $HOME/.zetacored/config/addrbook.json  https://server-3.itrocket.net/mainnet/zetachain/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="4e668be2d80d3475d2350e313bc75b8f0646884f@zetachain-mainnet-seed.itrocket.net:39656"
PEERS="30b0d6a633017352a6bc33d8f0f2a2f2ca544f64@45.77.249.66:26656,1d888c5985a536b53e528ad276b20294edb93592@208.91.106.110:26656,5e8e37464dcc2d9dd21b04a2c45b9ae1361eaa59@5.9.108.22:26656,377f9f12dcc3400f6e137c072a2b97368adc8832@195.201.11.115:26656,927860d6e888a5dee988cceed734e9dad0b569bc@176.9.137.150:26656,751d69c5b9eecb15f2db667ec34dfe70247011d8@144.217.77.113:26656,e84fd0c95048830b90caf32a6e81138de4146211@64.185.227.218:31850,28bb1ddb796e78168e3a6db71781dc7894e4fe84@147.135.31.22:22556,a8d3eddaf7f91994cec2d75e2bdcada3445b8368@15.235.10.84:26656,4f9a80c64f317248f1d1cb40b8eca20c5cd85d21@35.215.54.98:26656,b015384cceb3d25492c96a882ba84ad644b45402@178.63.249.110:26656,01de75368e56b38fc27a22c07236d50319ed129d@35.87.167.186:26656,d236ece41720ddd225e34369d9f1c96f6045833f@144.76.75.88:31850,aecf912d48a63e2bf0efa36f58997105696135bc@94.130.206.77:22556,e04ee1d6b5cc1aa24f7c1ab55139d1cec9962e39@52.45.59.77:26656,66e949b46a7b828b915be1aab831443e8a6e05a6@3.87.231.128:26656,ac4cbf842e38402e70f8297bcde0821c4d93d233@212.8.252.136:26656,2319b4676036fefc0fc083c0dec0a4ea37d85094@195.14.6.2:26656,f75a16acfd914846c2eee65b03df6e8fd129e225@168.119.10.134:26663,3a78a843dd91d0d21a429e7f47038a99a1d74b16@157.90.33.62:32849,2326ab7d77bfaa301872f88fa8e0c065d3f46218@35.78.61.71:26656,d08220cc2b4a1df243e9ad94d8e3812694375857@198.244.203.87:31497,ee3a1efa596915328ddeae0198306afd94e5e848@95.217.204.58:22556,4a7c6688342b87f5a8f7aa59c6f28642abbfef5b@207.148.19.161:26656,70319dbbaa547bde975df141417f9651f2a846a5@37.27.125.26:26656,12654d64b312688b5ab5682e13a6ff1b6021eac7@46.4.15.110:26656,ddb73255db3a85f10021c8825c1e78643895cc37@144.76.62.93:26556,79ae12cf364c91e3890e57183f0ecf48d2064e84@188.40.71.150:26656,c78f818f1243e676ae0908712284b2e0d2023c17@51.81.166.92:17600,6a529474d63c4f2463b2765be9cafef5deaead52@65.21.229.33:27656,49041b42e5ae5b0ef3560af156856efb8147818a@54.179.7.12:26656,730c0abcca73f74034ab27d6e033121caf021f19@189.1.170.86:26656,fdc9526a2eb11926f4b7a276a609127d6e015273@34.46.33.108:26656,af204f59efdc08efd5c450cab46645e19a9caffe@185.127.231.90:26656,eea4892699aa8d0d54491fd2164720687d7ffc93@141.95.66.226:17600,249f8e3f80acc805c5afb9242fdbff808285256e@54.238.97.193:26656,c37f642698260707c0e25a8895f9d36735318ef3@54.212.38.135:26656,6fdc0f47d80fa2e948744469b21232f5ae64f91e@34.72.214.30:26656,ef2b470f8151625e62a486776b1d57a8563a5730@65.109.112.170:22556,0fbd1020e8da35d96911ec48ace16a963f08af57@142.132.136.138:22556,d105bb46800c46d3c6094b623dbe45077150baca@43.207.255.138:26656,e0b89511a7a31d7867c00cfba748b474f853ac49@148.251.140.252:26656,34cd73db43d6c2852b07a4aa4bd92d404750ec85@135.181.222.33:22556,1d3042c42201b9dbb8457249fd1d8778d6742f18@35.79.228.153:26656,0ae725c03483a17aa5f9b4ebbaf394924e404927@18.184.7.39:26656,6c62121ae687111143552ca69bdb3e130eaf121c@34.89.183.242:26656,7292080395c0216b0a27193335e43f1c40d89b83@3.238.74.31:26656,0a16504807409db30798788b78383022189d19d9@80.85.242.46:22556,437d2d63075f307028ea28413f8fc1d3bc8f9726@15.235.10.83:26656,cc9ed9981f8b8c09e8fd43c5a39ed0e943015d6d@95.217.148.230:26656,9859172af3fbd0769b449a9c766aebf651f74a2e@160.202.128.199:55786,67b2dff23378c7a7db9afc56f227efab565d01cf@79.136.48.218:26656,0f1b077a1110f30e618dfc756a6195fd3d4206ed@208.91.106.108:26656,d32b3e22cfcb72e11050db30a59a59cd05646046@34.225.36.174:26656,68b6cb6af644ace16ad4f4e758d8d6ef77b78e2d@34.170.27.254:26656,d56a65e856443cf97fab922580de21cb234de51f@34.66.19.0:26656,055bdda1a2f92d4d36c57b2c5aef1e5f5b85ffb6@13.229.213.207:26656,d4c884bb26ada8138a1160dcbb739229feb5245f@54.216.66.11:26656,0ddce6317a9153b138532efb5051be585b752b96@34.195.53.91:26656,c088a771008ad9f253c26dd7a517698624a829a4@213.199.62.18:26656,297b475dc08e6de3c7cf4a2ce2fcddcce5f97a0f@84.17.42.200:56556,d6da4409e915b4c64e25e8bdb8afad90f802181e@204.16.242.162:26656,5a54fc83cedcd3cb47f9000aac66dc6a95aa8d1c@54.179.47.120:26656,6554807a10fd2d0e34b8daeed3fee38b8ca048b6@51.91.214.146:26656,3bbc8488c192ecf5d8d68fa0e87a060fa2447fc9@129.226.149.227:26656,233ffd3d2c4c97bb170f5bc6dd5e69d0f4d446e1@18.235.35.236:26656,552d9bde7f6ed6424c9504a804334fc5de4316f7@162.19.138.143:26656,e44ee7bc8eaf83025f3fb4b7a6a300d760b61c86@131.153.207.79:26656,5282a547c8df5b9a852ddf5f499e0319913a5a2e@34.81.39.139:26656,85cac2c77c8201cf048e8b3cb7b799c97fcd6fc1@213.133.99.62:21850,9de0360c8e816cf3b8202e0403674b1c228c3f44@18.182.78.42:26656,db6e01d36286433156e30e4e2006721007d87485@15.204.198.27:26656,637077d431f618181597706810a65c826524fd74@176.9.120.85:22556,d8730c76daaf371900159ab8c6e00bc3950eff79@64.176.39.37:26656,14c9e25d888678d977741fa921e85439b5a04d56@8.211.46.133:26656,a6feed5c5f68127c332e468f87d10fe842e72b33@54.199.153.43:26656,c2987e35cb161b349abad30105b5d2ab4e968fa5@100.27.185.50:26656,87d2423e2b63268eefa0284c687a1405dff55677@65.21.65.254:1530,177e7ddbb835e420395fa2977d8afb43ffaadb40@144.76.102.237:25656,13e67f1345dfacc0b2c81a7a624ff730099754f4@162.19.232.190:56556,f55f191f5036289ce0b7c2aee5aea6a3421e4a1d@51.178.76.16:26656,a5d984f145ea828048a0741a1d349f9fa13a643b@91.210.101.148:26656,7ee01bd3aa90b0c98f2ecb3fa6af292f0438804a@144.76.236.49:61356,0edfd371e5bc03ee5096ad241a2a02e335177285@162.19.97.197:26656,b6f9b4304ea941f1766f86418eb6bbe93d4258f9@145.40.91.189:10656,2a0a983bb9e8e04e8143819f4ca379b3b24aa77f@64.176.44.84:26656,7611af521ff41b8a5aa226ad2ad5db8c5198a587@188.214.130.150:26656,9a346b83bfa243a9c8466156952ed3c161a7813c@43.206.116.67:26656,545d3e5119629da657e202648b33f5fb30a4bf4c@18.156.177.148:26656,6fc8c0229962a581cba920ce7fbb5dcfba82f444@54.247.115.161:26656,d844f4d7b0afae13f055aca5ad822641b8dec04f@142.132.203.115:29656,ebc272824924ea1a27ea3183dd0b9ba713494f83@185.16.39.172:26746,786fd10b8cc97cd74476157e8dc6c8e17f1bd30f@198.244.253.127:30856,269273e7065748ec4aefa595a40156c292861064@13.42.27.62:26656,6d8296e6222eb992ff4814d950ed30630f924253@45.76.180.32:26656,c14b1ded8ada662f88f07dc48df344bf3b0f6dae@142.132.146.201:26656,ec18b4d60665ed05ca9ceca805e09fd29eb501b2@176.9.104.85:26656,1c91403a66fdbeb92078fd324ee70388bc3d5e6c@51.210.223.72:22556,372e9c80f723491daf2b05b3aa368865f6bc3492@65.109.69.119:39656,2bea20ffdc7d21d12cbc21d9d661adb7fdcd079e@8.212.101.240:26656,9f7493381f5dde7570a4e5c0be68a6a0e080d7e1@43.159.51.25:26656,91e8bfc81374c3cb9e507f491b16a7b316aeb9dd@57.180.212.166:26656,c1b2e0c77ccd2125b465d12c017ac060be6afe83@46.137.182.253:26656,7069d3e30752526ab512b43cdd7aca1012d9a142@52.35.128.130:26656,6a6ae6ccfa3e10e8cab52135880e17c0786b71bb@35.79.207.60:26656,c4c9e9fb6182ef115531000dbf7d4ebb19e5460c@216.18.211.154:31850,4d7a52d68af698c296211dec34a26cddefeb0b06@44.236.207.180:26656,4e668be2d80d3475d2350e313bc75b8f0646884f@142.132.253.112:39656,0ec555cdc7b9f49374308e9cfd9de2a3c9bd3381@65.109.18.169:22556,cd7552bb5347b61727714d7d7bcf0bff745f9f72@144.202.9.124:17600,0c1965582691ffc39ea4a67382f8a45039503947@8.217.33.31:26656,f5ea165cd3bc01c6b520e72210425104eb5b00d6@52.4.132.28:26656,372e9c80f723491daf2b05b3aa368865f6bc3492@zetachain-mainnet-peer.itrocket.net:39656,294b6400e352554638d89743a6c9949d4faa57dd@23.239.106.2:31850,cda49d4af5da9a3c5b01be36663b2257d49cc309@15.235.9.141:26656,2a0a983bb9e8e04e8143819f4ca379b3b24aa77f@64.176.44.84:26656,0f1b077a1110f30e618dfc756a6195fd3d4206ed@208.91.106.108:26656,35e621bf11455cee613833243f268a1ba83aabb5@64.176.47.152:26656,177e7ddbb835e420395fa2977d8afb43ffaadb40@144.76.102.237:25656,a5d984f145ea828048a0741a1d349f9fa13a643b@91.210.101.148:26656,1d888c5985a536b53e528ad276b20294edb93592@208.91.106.110:26656,d105bb46800c46d3c6094b623dbe45077150baca@43.207.255.138:26656,f55f191f5036289ce0b7c2aee5aea6a3421e4a1d@51.178.76.16:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.zetacored/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${ZETACHAIN_PORT}317%g;
s%:8080%:${ZETACHAIN_PORT}080%g;
s%:9090%:${ZETACHAIN_PORT}090%g;
s%:9091%:${ZETACHAIN_PORT}091%g;
s%:8545%:${ZETACHAIN_PORT}545%g;
s%:8546%:${ZETACHAIN_PORT}546%g;
s%:6065%:${ZETACHAIN_PORT}065%g" $HOME/.zetacored/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${ZETACHAIN_PORT}658%g;
s%:26657%:${ZETACHAIN_PORT}657%g;
s%:6060%:${ZETACHAIN_PORT}060%g;
s%:26656%:${ZETACHAIN_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ZETACHAIN_PORT}656\"%;
s%:26660%:${ZETACHAIN_PORT}660%g" $HOME/.zetacored/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.zetacored/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.zetacored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.zetacored/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0azeta"|g' $HOME/.zetacored/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.zetacored/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.zetacored/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/zetacored.service > /dev/null <<EOF
[Unit]
Description=zetachain node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.zetacored
ExecStart=$(which zetacored) start --home $HOME/.zetacored
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
zetacored tendermint unsafe-reset-all --home $HOME/.zetacored
if curl -s --head curl https://server-3.itrocket.net/mainnet/zetachain/zetachain_2024-08-02_4210394_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-3.itrocket.net/mainnet/zetachain/zetachain_2024-08-02_4210394_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.zetacored
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable zetacored
sudo systemctl restart zetacored && sudo journalctl -u zetacored -f
