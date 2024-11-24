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

while true; do
  echo -e "\n${GREEN}Lütfen ağ türünü seçin:${NC}"
  echo -e "1) Mainnet"
  echo -e "2) Testnet"
  echo -e "3) Çıkış"

  read -p "Seçiminiz (1-3): " network_choice

  case $network_choice in
      1)
          echo -e "\n${BLUE}Mainnet Projeleri:${NC}"
          echo "1) Dymension"
          echo "2) Lava Network"
          echo "3) Zetachain"
          echo "4) Geri"

          read -p "Proje seçin (1-4): " mainnet_choice

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
                  echo "Zetachain kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/zetachain.sh)
                  ;;
              4)
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
          echo "2) MantraChain"
          echo "3) Warden"
          echo "4) Geri"

          read -p "Proje seçin (1-4): " testnet_choice

          case $testnet_choice in
              1)
                  echo "Story Protocol kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/story.sh)
                  ;;
              2)
                  echo "MantraChain kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/mantra.sh)
                  ;;
              3)
                  echo "Warden kurulumu başlatılıyor..."
                  bash <(wget -qO- https://raw.githubusercontent.com/CoinHuntersTR/props/main/AutoInstall/warden.sh)
                  ;;
              4)
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
