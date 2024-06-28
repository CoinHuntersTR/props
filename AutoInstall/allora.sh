#!/bin/bash
set -eu

# Kullanıcıdan Moniker ismini al
read -p "Lütfen Moniker ismini girin: " MONIKER

# Temel güncelleme ve paket kurulumları
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

# Go dilinin kurulumu
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile

# Allora-chain'in indirilmesi ve kurulumu
cd $HOME
rm -rf allora-chain
git clone https://github.com/allora-network/allora-chain.git
cd allora-chain
git checkout v0.38.6
make install

# Node'un başlatılması ve konfigürasyonu
NETWORK="${NETWORK:-edgenet}"
GENESIS_URL="https://raw.githubusercontent.com/allora-network/networks/main/${NETWORK}/genesis.json"
SEEDS_URL="https://raw.githubusercontent.com/allora-network/networks/main/${NETWORK}/seeds.txt"

export APP_HOME="${APP_HOME:-./data}"
INIT_FLAG="${APP_HOME}/.initialized"
KEYRING_BACKEND=test
GENESIS_FILE="${APP_HOME}/config/genesis.json"
DENOM="uallo"

echo "To re-initiate the node, remove the file: ${INIT_FLAG}"
if [ ! -f $INIT_FLAG ]; then
    rm -rf ${APP_HOME}/config

    #* Node'u init et
    allorad --home=${APP_HOME} init ${MONIKER} --chain-id=${NETWORK} --default-denom $DENOM

    #* Genesis dosyasını indir
    rm -f $GENESIS_FILE
    curl -Lo $GENESIS_FILE $GENESIS_URL

    #* Yeni allorad hesabı oluştur
    allorad --home $APP_HOME keys add ${MONIKER} --keyring-backend $KEYRING_BACKEND > $APP_HOME/${MONIKER}.account_info 2>&1

    #* Konfigürasyonları ayarla
    #* Prometheus metriklerini etkinleştir
    # dasel put -t bool -v true 'instrumentation.prometheus' -f ${APP_HOME}/config/config.toml

    #* Allorad client'ı ayarla
    allorad --home=${APP_HOME} config set client chain-id ${NETWORK}
    allorad --home=${APP_HOME} config set client keyring-backend $KEYRING_BACKEND

    #* Allorad config için symlink oluştur
    ln -sf . ${APP_HOME}/.allorad

    touch $INIT_FLAG
fi
echo "Node is initialized"

SEEDS=$(curl -s ${SEEDS_URL})

echo "Starting validator node"
allorad \
    --home=${APP_HOME} \
    start \
    --moniker=${MONIKER} \
    --minimum-gas-prices=0${DENOM} \
    --rpc.laddr=tcp://0.0.0.0:26657 \
    --p2p.seeds=$SEEDS \
    --log_level "*:error,state:info,server:info,rewards:debug,inference_synthesis:debug,topic_handler:debug"
