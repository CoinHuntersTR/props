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
echo -e "${BLUE}║${GREEN}                 Node Kurulum Scripti        ${BLUE}║${NC}"
echo -e "${BLUE}║${YELLOW}                    by CoinHuntersTR        ${BLUE}║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

while true; do
  echo -e "\n${GREEN}Lütfen ağ türünü seçin:${NC}"
  echo -e "1) Mainnet Chain Kurulumu"
  echo -e "2) Testnet Chain Kurulumu"
  echo -e "3) Çıkış"

  read -p "Seçiminiz (1-3): " network_choice

  case $network_choice in
      1)
          echo -e "\n${BLUE}Mainnet Projeleri:${NC}"
          echo "1) Dymension"
          echo "2) Lava Network"
          echo "3) Mantra Chain"
          echo "4) Nibiru Chain"          
          echo "5) Zeta Chain"
          echo "6) CrossFi" 
          echo "7) Axelar"
          echo "8) Osmosis"           
          echo "9) Geri"

          read -p "Proje seçin (1-9): " mainnet_choice

          case $mainnet_choice in
              1)
                  echo "Dymension kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/AutoInstall/dymension.sh)
                  ;;
              2)
                  echo "Lava Network kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/lava.sh)
                  ;;
              3)
                  echo "Mantra Chain kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/MantraMainnet.sh)
                  ;;
              4)
                  echo "Nibiru Chain kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/nibiru.sh)
                  ;;    
              5)
                  echo "Zeta Chain kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/zetachain.sh)
                  ;;
              6)
                  echo "CrossFi kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/AutoInstall/crossfi.sh)
                  ;;
              7)
                  echo "Axelar kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/AutoInstall/axelar.sh)
                  ;;
               8)
                  echo "Osmosis kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/refs/heads/main/AutoInstall/osmosis.sh)
                  ;;                 
              9)
                  continue
                  ;;
              *)
                  echo -e "${RED}Geçersiz seçim!${NC}"
                  ;;
          esac
          ;;

      2)
          echo -e "\n${BLUE}Testnet Projeleri:${NC}"
          echo "1) Story Protocol"
          echo "2) Mantra Chain"
          echo "3) Warden Protocol"
          echo "4) Airchains"
          echo "5) Side Protocol"
          echo "6) Sunrise"
          echo "7) Union"
          echo "8) Empeiria"
          echo "9) Axone"      
          echo "10) Geri"

          read -p "Proje seçin (1-10): " testnet_choice

          case $testnet_choice in
              1)
                  echo "Story Protocol kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/story.sh)
                  ;;
              2)
                  echo "Mantra Chain kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/mantrachain.sh)
                  ;;
              3)
                  echo "Warden Protocol kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/warden.sh)
                  ;;
              4)
                  echo "Airchains kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/Airchains.sh)
                  ;;
              5)
                  echo "Side Protocol kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/side.sh)
                  ;;
              6)
                  echo "Sunrise kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/sunrise.sh)
                  ;;
              7)
                  echo "Union kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/union.sh)
                  ;;
              8)
                  echo "Empeiria kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/empeiria.sh)
                  ;;
              9)
                  echo "Axone kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/axone.sh)
                  ;;                  
              10)
                  continue
                  ;;
              *)
                  echo -e "${RED}Geçersiz seçim!${NC}"
                  ;;
          esac
          ;;

      3)
          echo -e "${YELLOW}Programdan çıkılıyor...${NC}"
          exit 0
          ;;

      *)
          echo -e "${RED}Geçersiz seçim! Lütfen 1-3 arasında bir sayı girin.${NC}"
          ;;
  esac
done
