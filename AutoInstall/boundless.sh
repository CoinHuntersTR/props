#!/bin/bash
echo -e "\033[0;37m"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";
echo " #####   ####        ####        ####  ####    ######    ##########  ####    ####  ###########   ####  ####";
echo " ######  ####       ######       #### ####    ########   ##########  ####    ####  ####   ####   #### ####";
echo " ####### ####      ###  ###      ########    ####  ####     ####     ####    ####  ####   ####   ########";   
echo " #### #######     ##########     ########   ####    ####    ####     ####    ####  ###########   ########";
echo " ####  ######    ############    #### ####   ####  ####     ####     ####    ####  ####  ####    #### ####";  
echo " ####   #####   ####      ####   ####  ####   ########      ####     ############  ####   ####   ####  ####";
echo " ####    ####  ####        ####  ####   ####    ####        ####     ############  ####    ####  ####   ####";
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";
echo -e '\e[36mTwitter :\e[39m' https://twitter.com/NakoTurk
echo -e '\e[36mGithub  :\e[39m' https://github.com/okannako
echo -e '\e[36mYoutube :\e[39m' https://www.youtube.com/@CryptoChainNakoTurk
echo -e "\e[0m"
sleep 5

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

echo -e "\e[1m\e[32m Gerekli Atamaları Yapalım.. \e[0m"  && sleep 2

read -p "Alchemy Rpc Girin: " ALCHEMYRPC
export ALCHEMYRPC
echo "export ALCHEMYRPC=\"$ALCHEMYRPC\"" >> ~/.bashrc

# ETH_RPC_URL değişkenini ALCHEMYRPC ile eşitle
export ETH_RPC_URL="$ALCHEMYRPC"
echo "export ETH_RPC_URL=\"$ETH_RPC_URL\"" >> ~/.bashrc

while true; do
  read -s -p "Cüzdan Private Key Girin: " PRIVKEY
  echo
  if [[ -z "$PRIVKEY" ]]; then
    echo -e "\e[1m\e[31mHata: Private key boş olamaz. Lütfen tekrar girin.\e[0m"
  else
    export PRIVKEY
    echo "export PRIVATE_KEY=\"$PRIVKEY\"" >> ~/.bashrc
    break
  fi
done

echo -e "\e[1m\e[32m Güncellemeler ve Bütün Gereksinimler Yükleniyor. Bitene kadar Bekleyin.. \e[0m"  && sleep 2

sudo apt update && sudo apt install -y make gcc pkg-config libssl-dev ocl-icd-opencl-dev nano tmux ocl-icd-libopencl1 libleveldb-dev protobuf-compiler libopencl-clang-dev libgomp1 curl git tar wget build-essential jq

cd /root || { echo "Root dizinine girilemedi!"; exit 1; }
echo "Root dizininde, şu an: $(pwd)"

if [ ! -d "boundless" ]; then
  echo "Boundless klasörü yok, klonlanıyor..."
  git clone https://github.com/boundless-xyz/boundless || { echo "Klonlama başarısız oldu"; exit 1; }
else
  echo "Boundless var, güncelleniyor..."
  pushd boundless || { echo "boundless klasörüne girilemedi"; exit 1; }
  git pull || { echo "Güncelleme başarısız"; popd; exit 1; }
  popd
fi

pushd boundless || { echo "boundless klasörüne girilemedi"; exit 1; }

# Alt kabukta çalıştırıyoruz ki dizin değişmesin
(
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && sleep 2
  source $HOME/.cargo/env && sleep 1

  curl -L https://risczero.com/install | bash && sleep 2
  source ~/.bashrc
  export PATH="$HOME/.risc0/bin:$PATH"
  rzup install

  cargo install --git https://github.com/risc0/risc0 bento-client --bin bento_cli && sleep 2
  export PATH="$HOME/.cargo/bin:$PATH"
  echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  cargo install --locked boundless-cli && sleep 1

  # PATH değişkenini kesin ayarla
  export PATH="$HOME/.cargo/bin:$PATH"
)

echo "Alt kabuk işlemleri sonrası dizin: $(pwd)"  # Burada hala boundless dizinindeyiz

echo -e "\e[1m\e[32m Env Dosyası Oluşturuluyor. \e[0m"  && sleep 2

cat <<EOF > .env.base
# Base contract addresses
export VERIFIER_ADDRESS=0x0b144e07a0826182b6b59788c34b32bfa86fb711
export BOUNDLESS_MARKET_ADDRESS=0x26759dbB201aFbA361Bec78E097Aa3942B0b4AB8
export SET_VERIFIER_ADDRESS=0x8C5a8b5cC272Fe2b74D18843CF9C3aCBc952a760

# Public order stream URL
export ORDER_STREAM_URL="https://base-mainnet.beboundless.xyz"
export ETH_RPC_URL="$ETH_RPC_URL"
export PRIVATE_KEY="$PRIVKEY"
EOF

source .env.base
echo "Script sonundaki dizin: $(pwd)"

popd  # boundless dizininden çıkıldı

echo -e "\e[1m\e[32m Yükleme işlemleri tamamlandı. Kılavuz üzerindeki diğer adımlara geçebilirsiniz. \e[0m"  && sleep 2
