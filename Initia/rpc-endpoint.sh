#!/bin/bash

# Fonksiyon: RPC bağlantısını kontrol et
check_rpc_connection() {
    if curl $RPC_URL/status; then
        SUCCESS=1
    else
        SUCCESS=0
    fi
}

# IP adresini al
IP=$(wget -qO- eth0.me)

# RPC bağlantı noktasını al
RPC_PORT=$(grep -A 3 "\[rpc\]" $HOME/.initia/config/config.toml | grep -oP ":\K[0-9]+")
RPC_URL="http://$IP:$RPC_PORT"

# RPC bağlantısını kontrol et
check_rpc_connection

# Eğer bağlantı başarısızsa, gerekli işlemleri yap
if [ "$SUCCESS" = "0" ]; then
    # Config dosyasını düzenle ve node'u yeniden başlat
    sed -i '/\[rpc\]/,/\[/{s/^laddr = "tcp:\/\/127\.0\.0\.1:/laddr = "tcp:\/\/0.0.0\.0:/}' $HOME/.initia/config/config.toml
    sudo systemctl restart initiad
    sleep 5

    # Yeniden RPC bağlantısını kontrol et
    check_rpc_connection

    # Eğer hala bağlantı başarısızsa, firewall'u kontrol et ve bağlantı noktasını aç
    if [ "$SUCCESS" = "0" ]; then
        PORT=$(grep -A 3 "\[rpc\]" $HOME/.initia/config/config.toml | egrep -o ":[0-9]+") && \
        PORT=${PORT#:} && \
        sudo ufw allow $PORT/tcp
        sudo systemctl restart initiad
        sleep 5

        # Son kez RPC bağlantısını kontrol et
        check_rpc_connection
    fi
fi

# Sonuçları yazdır
if [ "$SUCCESS" = "1" ]; then
    echo -e "\n\033[1;32mRPC BAĞLANTISI BAŞARILI\033[0m"
    echo -e "Public RPC URL'si: $RPC_URL"
else
    echo -e "\n\033[1;31mRPC bağlantısı başarısız oldu.\033[0m"
fi

# Beni takip et
echo -e "\nBeni X'te takip edin: https://x.com/brsbtc"
