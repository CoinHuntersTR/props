#!/bin/bash

# Load and print logo
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)
printLogo

sleep 2

echo -e "\e[1m\e[32m1. Updating dependencies... \e[0m" && sleep 1
sudo apt-get update

echo "=================================================="

echo -e "\e[1m\e[32m2. Installing required dependencies... \e[0m" && sleep 1
sudo apt install jq -y
sudo apt install python3-pip -y
sudo pip install yq

echo "=================================================="

echo -e "\e[1m\e[32m3. Checking if Docker is installed... \e[0m" && sleep 1

if ! command -v docker &> /dev/null
then
    echo -e "\e[1m\e[32m3.1 Installing Docker... \e[0m" && sleep 1
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
fi

echo "=================================================="

echo -e "\e[1m\e[32m4. Checking if Docker Compose is installed ... \e[0m" && sleep 1

if ! command -v docker-compose &> /dev/null
then
    echo -e "\e[1m\e[32m4.1 Installing Docker Compose... \e[0m" && sleep 1
    docker_compose_version=$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name")
    sudo curl -L "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "=================================================="

echo -e "\e[1m\e[32m5. Downloading Node Monitoring config files ... \e[0m" && sleep 1
cd $HOME
rm -rf cosmos_node_monitoring
git clone https://github.com/kj89/cosmos_node_monitoring.git

chmod +x $HOME/cosmos_node_monitoring/add_validator.sh
