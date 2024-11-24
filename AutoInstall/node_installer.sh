#!/bin/bash

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Terminal temizleme
clear

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║${GREEN}                 Node Kurulum Scripti                      ${BLUE}║${NC}"
echo -e "${BLUE}║${YELLOW}                    by CoinHuntersTR                      ${BLUE}║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Ana menü fonksiyonu
show_menu() {
  echo -e "\n${GREEN}Lütfen kurmak istediğiniz ağ türünü ve numarasını seçin:${NC}"
  echo -e "${YELLOW}Örnek kullanım: 'Mainnet 1' veya 'Testnet 2'${NC}\n"

  echo -e "${BLUE}Mainnet:${NC}"
  echo "1) Dymension"
  echo "2) Lava Network"
  echo "3) Zetachain"

  echo -e "\n${BLUE}Testnet:${NC}"
  echo "1) Story Protocol"
  echo "2) MantraChain"
  echo "3) Warden"

  echo -e "\n${YELLOW}Çıkış için 'exit' yazın${NC}"
}

# Script çalıştırma fonksiyonu
execute_script() {
  local network=\$1
  local choice=\$2

  case "${network,,}" in
      "mainnet")
          case $choice in
              1) bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/AutoInstall/dymension.sh);;
              2) bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/lava.sh);;
              3) bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/zetachain.sh);;
              *) echo -e "${RED}Geçersiz seçim!${NC}";;
          esac
          ;;
      "testnet")
          case $choice in
              1) bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/story.sh);;
              2) bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/mantra.sh);;
              3) bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/warden.sh);;
              *) echo -e "${RED}Geçersiz seçim!${NC}";;
          esac
          ;;
      *)
          echo -e "${RED}Geçersiz ağ seçimi!${NC}"
          ;;
  esac
}

# Ana döngü
while true; do
  show_menu
  echo -e "\n${GREEN}Seçiminizi yapın:${NC}"
  read -r input

  # Çıkış kontrolü
  if [ "${input,,}" = "exit" ]; then
      echo -e "${YELLOW}Programdan çıkılıyor...${NC}"
      break
  fi

  # Kullanıcı girdisini ayırma
  network=$(echo $input | cut -d' ' -f1)
  choice=$(echo $input | cut -d' ' -f2)

  # Seçim kontrolü ve script çalıştırma
  if [ -n "$network" ] && [ -n "$choice" ]; then
      execute_script $network $choice
  else
      echo -e "${RED}Geçersiz giriş formatı! Örnek: 'Mainnet 1' veya 'Testnet 2'${NC}"
  fi
done
