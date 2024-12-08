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
echo "export OSMOSIS_CHAIN_ID="osmosis-1"" >> $HOME/.bash_profile
echo "export OSMOSIS_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$OSMOSIS_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$OSMOSIS_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.21.6"
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
wget -O osmosisd https://github.com/osmosis-labs/osmosis/releases/download/v27.0.1/osmosisd-27.0.1-linux-amd64
chmod +x $HOME/osmosisd
mv $HOME/osmosisd $HOME/go/bin/osmosisd

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
osmosisd init $MONIKER --chain-id $OSMOSIS_CHAIN_ID 
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${OSMOSIS_PORT}657\"|" $HOME/.osmosisd/config/client.toml
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.osmosisd/config/genesis.json https://snapshots.polkachu.com/genesis/osmosis/genesis.json
wget -O $HOME/.osmosisd/config/addrbook.json https://snapshots.polkachu.com/addrbook/osmosis/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:12556"
PEERS="6020da64c7dacc0c50d4b9ca61e56516274d9b6c@167.235.187.14:26656,413f0e9bc38e66fb8733d5339bcd8fe397b8cd22@37.27.23.105:22345,fd7bf933629fdd48aaa476f8c9198ecc5a74dd93@3.64.145.200:26656,9692f9b0ef1c577cefcae06e48e71d2c62ba500e@65.108.141.109:56656,0c583152b5e7df003105be8a2872bbd3b32881e4@135.181.79.7:26656,f77426b7dd4f16f02920da052a5ff9de5aaca0e9@51.81.166.119:14100,cce57cb7c845dde2a4c9afb7822531eb4224b6c8@49.12.12.85:26656,08ceabce6dadc0aa5d33dc2058b9eeeff6186116@142.132.248.253:27656,d73e5bb3cc1198c1f53e3759d87f7e5f36c4508b@144.76.195.215:26656,affdf33799193b0368c9c752c69d6319ac41cd80@167.235.187.10:26656,663f79f1e646ed4a7b27f3f8ad7770323d76f06b@3.71.218.95:26656,aed7f2724726732d1c55b90a2ac5372fd8051b66@49.12.86.237:26656,e2c9ab85c94b30bea0b6205d9131b356bdb037c5@54.36.104.223:12556,0b859e6004143ce8f629d636a5b2e53d681a72ec@88.198.35.12:56656,3753eab2ddd1d269c5552ced7c679211df2f6418@44.230.94.114:26656,ed1faa8d5e4057a06d9cc50a96d1c05f1d928109@95.216.32.205:26656,51b8a16ef21715530fa7fd1e9f84a73f36776b5c@66.165.247.146:26656,14e0863a9f4d63b213371efc4b80672ea60dcfc2@65.108.53.110:26656,19f75a1aea4cdf8ce987b3d4e1ef6617eb3604b3@185.16.38.223:26716,7a31c2e871bca29ffc24fd43e6c0fd9e1df5f220@5.78.100.45:26656,3b7e443348c584065ec9d7fce9ff64b5e422664c@15.235.115.151:14100,25c562d758d7139b22f920317b80e215cf2f0c77@65.21.156.193:26656,44702726b7dcb6a3567303370e9334bf108e2684@158.247.219.236:14100,ec929701754be057fb38c824fc127e26add9c900@136.243.40.12:26666,c521562f7361e385c0478763bb647af4522320b2@51.195.235.83:56656,6628c6d16123cab2014bf97aa9fb5c0ab674183e@51.222.143.109:56656,0c6fd19c1a5de7eb32018e6d360d6f3ec3440cf9@167.235.187.15:56656,f0eae9784c5bcbfc94530ceb548e428470bb162b@54.177.235.99:26656,f6b801e5b830ae176f515f833f1e3da22b42050e@51.195.90.122:36656,9d2a0e58bb99ee650d2a92d76ea35afea3910454@116.202.224.210:56656,7c7558688e3bab9e1bc36da93deb2bfe3a9e48e1@95.217.150.197:26656,1634c775e94f9acf1c0897f78c42790424f69f62@46.4.22.159:26656,0c4524629b6f2554081e2c2b883212a884f90de3@5.78.82.168:26656,f675ea45db21d722812296aaf6dd5a8cae2be12a@5.75.242.239:26656,0968bbd97652ae1c7c0c6ce577230bd5d9f12eee@135.181.137.206:26656,6c66eac532c0fc70b4954deea54cd969beeda719@188.245.34.26:26624,ba8ba2b3bec7c3610e98667cc09dc394e4eba4ac@195.201.217.85:26624,3b3bb0ea476ae05836acebaf23eee1c1a25c509f@5.9.70.133:26656,b42167a4a0c71a5250072affbd436e72d54f21d0@170.64.142.47:26100,db237d8474bc1a7b91eece7687e344f5dc1f3927@37.59.18.132:16190,9e1698b35041778794d4cfa97c623d4239603c82@95.216.185.206:26656,559167a59e5aeb881e5159455aafa2c2f4bb97fb@5.161.216.37:26656,213b6ac4b64375570db88f01d6493c775bfdd1b6@5.78.85.94:26656,6a776a925f2876514ac66bb79c343500f703c358@23.88.96.88:26656,6f1c1ac91c0a0f9322744c6924008c9f34dd3723@135.125.75.198:26656,4917139f4d895c105bff1e42d9d356209d4b3d73@135.125.236.74:56656,89d56cedcebfd6e962278a95238ef1c8abe809b7@51.79.79.68:26656,752f393a2720a27caaebc35b600997491e8f8702@65.21.196.250:36656,140c455023c31ef06ac62969d9e04cdbd10cfb36@135.125.238.99:56656,14518696ba870cdf138aa0c699d9481f110ad0c9@78.46.251.151:26656,1404ccdde6b1d38e07f4ade742367e60a5ecbed4@49.13.82.250:26656,65f51ebf46256d829ae5903e9faf31dae35bdf46@65.109.64.245:10101,cf2f2a6c412c102eb0362ebd1741ad728b7462c0@65.108.235.33:2000,6114998e706a144ef0a8cd5db75433c60bc28a83@51.195.7.4:10101,040cb219046eff64624dfbf39c1ce2bf3e60e18f@35.242.247.204:26656,8df03c283680dd2ed139a6415a61bcbec5349b38@95.217.8.91:26656,13832193ba6d478e53b3887fd0452dca9f494acc@147.182.231.31:26656,27e14df66c9e4cd6b176b0dca6adfa9b6750f911@5.161.72.103:26656,d03e94c7ad1695ddd6145b187d10323991ec02f9@157.90.131.229:26656,6acef796262e3ba7d0a5c94d198f7089a04a4e90@5.75.243.228:26656,8c20d5d59287f2c28692cd39596abedb027aeec4@135.181.92.165:26656,8350d3910f2805fa5bca28f3a597f4781b9b5f0f@65.108.193.249:2000,e63d0dd41a25aee241a8fbbb82fdb349e257bfc6@141.94.248.63:26456,3d2efd13a1d6b7ebd780d5c21b9d2c493f75aa40@142.132.209.151:56656,27af00377d0d65f14ea8bcf7bc26a053f48ec58f@135.181.46.125:26656,8d14fccd836d69e35a0d113eb5fe20edbec30ff7@144.76.102.39:2000,297595aa5710b44e2e964f5b546182a3808fe62b@162.55.170.239:26656,47987080e86e0b5dda26cd9be1c1677f00c46dcd@5.75.149.205:26656,6884013263246c40d8753fd18ce6ae40b0125ef8@51.158.206.48:27103,865df574150c29f108fdc96cad43ddcfe02ed2b5@49.13.62.125:26656,b0d2b883976f4fb8994d100e3adc85b9c4d22749@49.13.59.239:26656,54d84c94180f13dbffa1b6855623c9262b5b9037@78.47.227.245:26656,4bb3629e3dc67e59c2367f6baa1e12e79cbc7ab2@128.140.93.9:26656,bb8235becffec62ef0f8c0a6bd0cbab389cc016e@5.78.111.127:26656,29efaab2b74eb05ed0a1711d05c10fd9cae48e1d@57.129.7.241:26656,1dfdd773315cc3f5ef1f379f5225fa99ed0d9cae@51.38.227.5:26656,26f3f8a059185d8438d68b57c5891d4b7c2db28b@169.150.206.193:26678,488d1bc2f5c22254c146d030faa87b061bc77cf3@65.108.33.49:26656,3040e414423013e271d7091133dfb59adc4f3e29@51.222.12.21:56656,c6a7962068000bdf969cef26db7ab080db46ed71@51.222.138.95:56656,ae2e110ab256c915106546df955830d2e837ac69@164.90.145.230:26656,7d0e0410ee66fc54ea4bd4aa6443ebb66ad77b97@168.119.106.234:26656,311f5a072ddc4b14d1751fc91f43119fd5b1246e@5.78.74.233:26656,3088c54f42f52e0288ad46b0e3c66e475c6c19a8@65.109.33.25:26656,d7a2b907c87c4f506f8da13a97f2d6dfe499952a@95.217.150.196:26656,e511830752503a85814294b005d92ee5385781d2@51.222.142.216:26656,0d901b734acaac6021cc9103c6f1508355c4a4af@5.78.102.16:26656,004ce11e789d437ff74f7e6a6aebf12a7aa3e2b0@65.108.229.244:26656,9a585cfe4f426743a76fe2834d97f32463c464c1@141.94.207.148:56656,c53dfe934aaba87008cd389e56bfc683861d53b1@51.222.143.30:56656,5bd07ba35ae0975399cdaaa57610bfd51648099f@167.235.187.13:26656,4a2d3d1d62552c0edeabcb4aba4d6ff14fd4b6dc@148.251.121.152:10101,4a837e3411b0281f00c07706cfea72d3ebc575f1@176.9.38.49:26656,15dbc59a2b8dc7c3e4d7f969b2a6b54725f91fbf@147.182.194.160:26656,0015ce90a97c79e313f221dd0890cedf4785b20d@65.108.224.166:12556,c4f143a940e651a3d7e45a202dd6565b1e6f4504@74.118.136.132:26656,c94dc2c10168e7797dc47162fdae55f2c5229421@94.130.14.54:12556,d456cf939891e86d4ee9cf019e11b7150a890713@65.21.233.188:12556,67cd3395be999ea46cc76eecb16d069d0c996e30@162.55.237.11:26656,f9bfc7f25f63bd7e392fbe5465126b311465cbce@65.108.78.186:26656,3918d0e114ce819644e966141a5f5229d4248da8@135.181.138.95:2000,feb2e84cba7a283eba10c35ec0f336ce4d004ad4@178.18.251.12:46656,66d6dff0d063281a47a8e0ade43953a2588fd236@54.72.19.29:26656,424135f4eeb1f31f471641f9bbb9f4e099c5341f@65.21.49.55:26656,9665717f0079069e5507aa63c5205f8fdcff87fb@65.109.146.121:26656,c51c7cf2855d3fbbc4319b3b5bc0ac394826a046@18.189.57.228:26656,bc76d3251eaf3c559c531cd0f6a166aedcee6928@164.90.230.180:26100,a5d0842d58c0fdd4ed10a39fd9c897cd168906d2@65.21.195.98:26706,0e4dabd06828145d5748f9bbc22860eafac8321e@65.109.86.210:26656,b95edbc3337a6fdd672cd6af2790c0e9ade2c4dd@65.108.195.213:41656,c61bf85fd330bb702b1f13f58dd3cf83c5363bf2@149.56.26.22:26656,f1fe0a080d561d37a94bea6022cbc0972395a0f4@65.108.121.190:2000,203379f91e937f0c5ddaa11f1c69bfa2993bd7c9@65.108.76.112:12556,e153cc49052d67280dfdd6d660f3d98622905850@209.133.193.74:26656,40edaf7ee5ebbd8acf8eed889867e7adadce5182@162.19.86.219:27103,7ea6835da9e8e8475a9fd89b8cb5a2391df8128e@64.23.130.179:26100,05a0f868ba2f57b06aa69c73d8ccc01082a6daf9@107.22.254.251:26656,beb75519a1993bfc2fbc23fa25213fbc0170f0cc@159.203.79.46:26100,3f59f29c396a9141e4a4da11f2c2dd8e9fc3d647@45.77.64.252:26656,3c27e1a75e3aa279b2f4af8a3e3512cc74ef794d@35.243.64.224:26656,94f18094ff3339d681a24a0a2b29fe71bcf28b65@65.109.145.170:26656,b35f427fb2c793b0ff20dc2d8c832539af542b70@167.235.187.9:26656,0c9946bbe516394a4e17eb61f5b05d0c49e848c6@159.89.109.179:32057,4406eef758493c2be65a96b25c56654ef4a1cb48@65.109.35.90:26656,3d397e3973286359c64f2090db7deb201ffabf7b@65.109.146.25:26656,31d2c86f7957e2db91297e54c3b0456ea06c2250@173.67.177.115:26656,5c5b17f3a61816031cbcacdc65f295dcf53e91f2@74.118.139.213:26656,48d5ca815db9e9139ee9e83a359f0feb4650c3c5@135.125.75.199:26656,c5358545d951ae666c695903036c1e93578951eb@135.181.176.113:26656,92209514b69ffb1a1ce3ee8aaa55350db963f62a@128.140.45.77:26624,07738504cf080ba7ac1038831a79b93156135d2e@167.235.187.12:26656,7f36123a395e902deaecf63bdaf5656bbb209623@15.204.52.75:26656,f4d77fcf8ab177cc3e519a1bfb4c2edb244176c8@206.189.110.113:26100,6fb58d8278c09a247271718e3bbb31b174e916f9@46.4.72.249:26624,baa7572065e18f1796f50b336a01dcaa85eccd01@65.108.101.214:26656,dc39ce57810e157cbbd581cd56e22391f7a6aeda@167.235.187.11:26656,7bb62afdc4adb147205e6888406aa66924ddc4df@95.217.150.236:26656,8d62dfa437917bff46c18b650fab3cb7091554db@141.94.73.39:38656,76303284b76e5a644f89f5b1a86e8eb1167206a4@65.109.27.253:36008,424135f4eeb1f31f471641f9bbb9f4e099c5341f@65.21.49.55:26656,c62b1634231295346e886ec41b090716d975f9e8@65.21.37.194:10101,bc84be852de5a8a6f64ca818f5941b4b15409b91@173.69.131.145:36656,413f0e9bc38e66fb8733d5339bcd8fe397b8cd22@37.27.23.105:22345,47987080e86e0b5dda26cd9be1c1677f00c46dcd@5.75.149.205:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.osmosisd/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${OSMOSIS_PORT}317%g;
s%:8080%:${OSMOSIS_PORT}080%g;
s%:9090%:${OSMOSIS_PORT}090%g;
s%:9091%:${OSMOSIS_PORT}091%g;
s%:8545%:${OSMOSIS_PORT}545%g;
s%:8546%:${OSMOSIS_PORT}546%g;
s%:6065%:${OSMOSIS_PORT}065%g" $HOME/.osmosisd/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${OSMOSIS_PORT}658%g;
s%:26657%:${OSMOSIS_PORT}657%g;
s%:6060%:${OSMOSIS_PORT}060%g;
s%:26656%:${OSMOSIS_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${OSMOSIS_PORT}656\"%;
s%:26660%:${OSMOSIS_PORT}660%g" $HOME/.osmosisd/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.osmosisd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.osmosisd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.osmosisd/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0025uosmo"|g' $HOME/.osmosisd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.osmosisd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.osmosisd/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/osmosis.service > /dev/null <<EOF
[Unit]
Description=osmosis node
After=network-online.target

[Service]
User=root
WorkingDirectory=/root/.osmosisd
ExecStart=/root/go/bin/osmosisd start --home /root/.osmosisd
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
if curl -s --head curl https://snapshots.polkachu.com/snapshots/osmosis/osmosis_25308122.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://snapshots.polkachu.com/snapshots/osmosis/osmosis_25308122.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.osmosisd
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable osmosis.service
sudo systemctl restart osmosis.service && sudo journalctl -u osmosis.service -f
