#!/bin/bash

# Install dependencies
apt update
apt install -y git curl build-essential libssl-dev zlib1g-dev xxd

# Clone repository
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy

# Build MTProxy
make

cd objs/bin

# Download Telegram secret and config
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

# Generate user secret
SECRET=$(head -c 16 /dev/urandom | xxd -ps)

echo "MTProxy secret: $SECRET"

# Run MTProxy
./mtproto-proxy -u nobody -p 443 -H 443 -S "$SECRET" --aes-pwd proxy-secret proxy-multi.conf -M 1
