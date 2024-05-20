#!/bin/bash

exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/logo.sh | bash && sleep 1

# Moniker al
read -p "Lütfen Moniker'ınızı girin: " MONIKER

echo -e "\e[1m\e[32m1. Update && Upgrade... \e[0m"
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m1. Paketleri yükleniyor... \e[0m"
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make lz4 unzip ncdu -y

echo -e "\e[1m\e[32m1. GO'yu yükleniyor... \e[0m"
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

echo -e "\e[1m\e[32m1. Download and build binaries... \e[0m"
cd $HOME
rm -rf initia
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.15
make build
mkdir -p $HOME/.initia/cosmovisor/genesis/bin
mv build/initiad $HOME/.initia/cosmovisor/genesis/bin/
rm -rf build

echo -e "\e[1m\e[32m1. Create application symlinks... \e[0m"
sudo ln -s $HOME/.initia/cosmovisor/genesis $HOME/.initia/cosmovisor/current -f
sudo ln -s $HOME/.initia/cosmovisor/current/bin/initiad /usr/local/bin/initiad -f

echo -e "\e[1m\e[32m1. Install Cosmovisor and create a service... \e[0m"
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

sudo tee /etc/systemd/system/initia.service > /dev/null << EOF
[Unit]
Description=initia node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.initia"
Environment="DAEMON_NAME=initiad"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.initia/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable initia.service

echo -e "\e[1m\e[32m1. Initialize the node... \e[0m"
initiad config set client chain-id initiation-1
initiad config set client keyring-backend test
initiad config set client node tcp://localhost:17957
initiad init $MONIKER --chain-id initiation-1
curl -Ls https://raw.githubusercontent.com/CoinHuntersTR/props/main/initia/genesis.json > $HOME/.initia/config/genesis.json
curl -Ls https://raw.githubusercontent.com/CoinHuntersTR/props/main/initia/addrbook.json > $HOME/.initia/config/addrbook.json
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@initia-testnet.rpc.kjnodes.com:17959\"|" $HOME/.initia/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" $HOME/.initia/config/app.toml
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.initia/config/app.toml
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:17958\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:17957\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:17960\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:17956\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":17966\"%" $HOME/.initia/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:17917\"%; s%^address = \":8080\"%address = \":17980\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:17990\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:17991\"%; s%:8545%:17945%; s%:8546%:17946%; s%:6065%:17965%" $HOME/.initia/config/app.toml

echo -e "\e[1m\e[32m1. Download latest chain snapshot... \e[0m"
screen -dmS snapshot bash -c "curl -L https://snapshots.kjnodes.com/initia-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.initia && [[ -f $HOME/.initia/data/upgrade-info.json ]] && cp $HOME/.initia/data/upgrade-info.json $HOME/.initia/cosmovisor/genesis/upgrade-info.json"

echo -e "\e[1m\e[32m1. Start service and check the logs... \e[0m"
sudo systemctl start initia.service && sudo journalctl -u initia.service -f --no-hostname -o cat
