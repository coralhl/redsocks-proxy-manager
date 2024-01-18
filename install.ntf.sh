#!/bin/bash

binfile="redsocks_$(uname --machine)"
cp ${binfile} /usr/bin/redsocks

if [[ ! -d /etc/redsocks/redsocksenv ]]; then
    mkdir /etc/redsocks
    touch /etc/redsocks/redsocksenv
fi

SOCKS5_SERVER="127.0.0.1"  # адрес прокси-сервера SOCKS5
SOCKS5_PORT="10808"        # порт прокси-сервера SOCKS5
PROXY_PORT="12345"         # прослушивающий порт redsocks

rm -rf redsocks.conf
cp redsocks.conf.example /etc/redsocks/redsocks.conf

echo "Redsocks will listen on port $PROXY_PORT,"
echo "make sure it is not occupied by another process."

if [[ ! -f proxyserverinfo ]]; then
    touch proxyserverinfo
    # Конфигурация прокси-сервера SOCKS5, если она ещё не создана
    read -p "Please tell me your socks_server [hit Enter for $SOCKS5_SERVER]:" s_server
    if [[ ${s_server} != "" ]]; then
        SOCKS5_SERVER=${s_server}
    else
        SOCKS5_SERVER=$SOCKS5_SERVER
    fi

    read -p "Please tell me your socks_port [hit Enter for $SOCKS5_PORT]:" s_port
    if [[ ${s_port} != "" ]]; then
        SOCKS5_PORT=${s_port}
    else
        SOCKS5_PORT=$SOCKS5_PORT
    fi

    echo "${SOCKS5_SERVER}:${SOCKS5_PORT}" > proxyserverinfo
else
    # Конфигурация прокси-сервера SOCKS5, если она уже существует
    SOCKS5_SERVER=$(head -n 1 proxyserverinfo | awk -F: '{print $1}')
    SOCKS5_PORT=$(head -n 1 proxyserverinfo | awk -F: '{print $2}')
fi

# функция обновления файла redsocks.conf
update_redsocks_conf() {
    sed -i '18s/daemon.*/daemon = on;/g' /etc/redsocks/redsocks.conf
    sed -i '44s/local_port.*/local_port = '${PROXY_PORT}';/g' /etc/redsocks/redsocks.conf
    sed -i '61s/ip.*/ip = '${SOCKS5_SERVER}';/g' /etc/redsocks/redsocks.conf
    sed -i '62s/port.*/port = '${SOCKS5_PORT}';/g' /etc/redsocks/redsocks.conf
}

update_redsocks_conf

# Проверка типа текущей системы инициализации
if [[ $(ps -p 1 -o comm=) == "systemd" ]]; then
    # systemd
    cp redsocks.service.ntf /etc/systemd/system/redsocks.service
    systemctl daemon-reload
    systemctl enable redsocks.service
    systemctl start redsocks.service
else
    # SysV init
    cp redsocks-service.ntf /etc/init.d/redsocks
    chmod +x /etc/init.d/redsocks
    service redsocks start
fi

# Копирование настроек прокси
cp NoProxy.list /etc/redsocks/NoProxy.list
cp ToProxy.list /etc/redsocks/ToProxy.list

# Копирование скрипта прокси-сервера
cp -rf rs-proxy.ntf /usr/local/bin/rs-proxy && chmod +x /usr/local/bin/rs-proxy && sed -i 's/SED_SOCKS5_SERVER/'${SOCKS5_SERVER}'/g' /usr/local/bin/rs-proxy && sed -i 's/SED_PROXY_PORT/'${PROXY_PORT}'/g' /usr/local/bin/rs-proxy
cp -rf rs-proxyall.ntf /usr/local/bin/rs-proxyall && chmod +x /usr/local/bin/rs-proxyall && sed -i 's/SED_SOCKS5_SERVER/'${SOCKS5_SERVER}'/g' /usr/local/bin/rs-proxyall && sed -i 's/SED_PROXY_PORT/'${PROXY_PORT}'/g' /usr/local/bin/rs-proxyall
cp -rf rs-restart.ntf /usr/local/bin/rs-restart && chmod +x /usr/local/bin/rs-restart
cp -rf rs-manage-ip /usr/local/bin/rs-manage-ip && chmod +x /usr/local/bin/rs-manage-ip
