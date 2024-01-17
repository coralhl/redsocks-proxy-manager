# Введение

Использование redsocks с iptables для перенаправления трафика запросов.

Должено быть настроено защищённое подключение, например `SOCKS5`, через которое будем пропускать трафик. Используем `redsocks` для перенаправления трафика до цели с определённым IP-адресом через это защищённое подключение. Поскольку `redsocks` не предоставляет возможности настройки `iptables`, был написан скрипт, который читает IP-адреса из файла конфигурации и помогает быстро произвести настройки.

В системе должна быть установлена утилита 'host'

```bash
Shell> sudo apt install dnsutils -y
or
Shell> sudo yum install bind-utils
or
...
```

# Как использовать

В этом репозитории есть скомпилированный бинарник для стабильной версии `redsocks` (скомпилированы версии `x86_64` и `aarch64` при помощи `alpine musl gilbc`, чтобы не устанавливать зависимости).

1. Установка:

```bash
Shell> sudo ./install.sh
please tell me you socks_server: 127.0.0.1 # Введите адрес прокси-сервера SOCKS5
please tell me you socks_port: 10808        # Введите порт прокси-сервера SOCKS5
```

2. Запуск redsocks:

```bash
Shell> sudo service redsocks start

```

3. Выбор режима работы:

**Глобальный режим прокси-сервера**

```bash
Shell> sudo rs-proxyall      # Включает режим глобального прокси

 your iptabls OUTPUT chain like this....
 Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 num   pkts bytes target     prot opt in     out     source               destination

 Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 num   pkts bytes target     prot opt in     out     source               destination

 Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 num   pkts bytes target     prot opt in     out     source               destination
 1        0     0 RETURN     tcp  --  *      *       0.0.0.0/0            192.168.188.0/24
 2        0     0 RETURN     tcp  --  *      *       0.0.0.0/0            127.0.0.1
 3        0     0 RETURN     tcp  --  *      *       0.0.0.0/0            127.0.0.1
 4        0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            redir ports 12345

 Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 num   pkts bytes target     prot opt in     out     source               destination
```

**Частичное проксирование**

В этом режиме проксируются только хосты, указанные в файле `ToProxy.list`.

```bash
Shell> sudo rs-proxy

this ip[216.58.194.99] will use proxy connected ....
this ip[180.97.33.107] will use proxy connected ....
your iptabls OUTPUT chain like this....
   Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
   num   pkts bytes target     prot opt in     out     source               destination

   Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
   num   pkts bytes target     prot opt in     out     source               destination

   Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
   num   pkts bytes target     prot opt in     out     source               destination
   1        0     0 RETURN     tcp  --  *      *       0.0.0.0/0            192.168.188.0/24
   2        0     0 RETURN     tcp  --  *      *       0.0.0.0/0            127.0.0.1
   3        0     0 RETURN     tcp  --  *      *       0.0.0.0/0            127.0.0.1
   4        0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            216.58.194.99        redir ports 12345
   5        0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            180.97.33.107        redir ports 12345

   Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
   num   pkts bytes target     prot opt in     out     source               destination

```

4. Выключение проксирования (удаляются правила файрвола) и остановка сервисов:

```bash

Shell> sudo service redsocks stop        # Остановка прокси-сервера redsocks

```

5. Добавление и удаление IP-адресов по имени хоста, к которым нужен доступ через прокси (в файле ToProxy.list).
При этом будут созданы новые правила файрвола.

```bash

Shell> sudo rs-manage-ip -a google.ru    # Добавление IP-адресов google.ru
Shell> sudo rs-manage-ip -d google.ru    # Удаление IP-адресов google.ru

```

6. Принудительный перезапуск прокси (для применения новых записей из ToProxy.list)
Если вам нужен перезапуск прокси, то нужно обновить и правила для файрвола. Для этого не обязательно перезапускать сервис redsocks, нужно выполнить:

```bash

Shell> sudo rs-restart                   # Применяет новые правила для файрвола

```

7. Если вы хотите изменить параметры подключения к Socks серверу (адрес или порт), то запустите 'install.sh' ещё раз.

# Метод статической компиляции

```bash

apk --no-cache add busybox-extras musl-dev linux-headers libevent-static libevent-dev musl-dev gcc make vim bash

```
