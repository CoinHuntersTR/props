#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/CoinHuntersTR/Logo/main/common.sh)

printLogo

# Kullanıcıdan bilgileri al
read -p "API ismi (örneğin: sunrise-api): " api_name
read -p "RPC ismi (örneğin: sunrise-rpc): " rpc_name
read -p "API proxy_pass port değeri (örneğin: 26317): " api_port
read -p "RPC proxy_pass port değeri (örneğin: 26657): " rpc_port
read -p "API server_name (örneğin: sunrise-api.chainad.org): " api_server_name
read -p "RPC server_name (örneğin: sunrise-rpc.chainad.org): " rpc_server_name

# Paketleri güncelle ve gerekli paketleri yükle
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential snapd unzip nginx
sudo apt -qy upgrade

# API için nginx yapılandırmasını oluştur
sudo tee /etc/nginx/sites-available/$api_name > /dev/null <<EOL
server {
listen 80;
server_name $api_server_name;

location / {
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Max-Age 3600;
    add_header Access-Control-Expose-Headers Content-Length;
    
    proxy_pass http://0.0.0.0:$api_port;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
}
}
EOL

# RPC için nginx yapılandırmasını oluştur
sudo tee /etc/nginx/sites-available/$rpc_name > /dev/null <<EOL
server {
listen 80;
server_name $rpc_server_name;

location / {
    proxy_pass http://0.0.0.0:$rpc_port;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
}
}
EOL

# Sites-enabled dizininde sembolik linkler oluştur
sudo ln -s /etc/nginx/sites-available/$api_name /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/$rpc_name /etc/nginx/sites-enabled/

# Nginx yapılandırmasını test et ve yeniden yükle
sudo nginx -t && sudo systemctl reload nginx

# Certbot'u yükle ve yapılandır
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo snap set certbot trust-plugin-with-root=ok
sudo certbot --nginx --register-unsafely-without-email

echo "Tüm adımlar başarıyla tamamlandı!"
