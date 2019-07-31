# Иерархия каталога
```
./
├── local
│   ├── check_connectivity.sh
│   ├── clear_local.sh
│   └── create_cluster_local.sh
├── README.md
├── remote
│   ├── clear.sh
│   ├── create_cluster.sh
│   ├── linux_bridge_down.sh
│   ├── linux_bridge_up.sh
│   ├── scheme.jpeg
│   ├── vxlan_down_test.sh
│   └── vxlan_up_test.sh
└── shared
    └── create_cluster_shared.py
```

# Common Prerequisites
On each physical server where you will start virtual machine run:
```bash
sudo apt install cloud-image-utils qemu-kvm
sudo apt install sshpass
```


# Задача 1
- Поднять виртуальные машины на одном сервере
- Трафик между виртуальными машинами должен проходить через программный коммутатор, который располагается на том же сервере, что и виртуальные машины


# Решение
Пусть есть один сервер: `server1`, и стоит задача сделать кластер из `N` узлов.

На сервере `server1` нужно запустить скрипт `./local/create_cluster_local.sh` необходимыми аргументами.
Этот скрипт создаст `N` виртуальных машин, настроит между ними связность по ssh, настроит NFS.

Для удаления кластера нужно запустить скрипт `./local/clear_local.sh`.



# Задача 2
- Поднять виртуальные машины на одном сервере
- Трафик между виртуальными машинами должен проходить через программный коммутатор, который располагается на другом сервере

Пример схемы подключения см. в `./remote/scheme.jpeg`.

# Решение
Пусть есть два сервера: `server1` и `server2`, и стоит задача сделать кластер из `N` узлов.
Сервера должны быть доступны друг другу.

На сервере `server2` нужно запустить скрипт `./remote/linux_bridge_up.sh` с аргументом `N`. Этот скрипт создаст linux bridge с необходимым для работы кластера количеством vxlan интерфейсов. Для удаления этого linux bridge'а нужно запустить скрипт `./remote/linux_bridge_down.sh` с аргументом `N`.

На серверe `server1` нужно запустить скрипт `./remote/create_cluster.sh` с необходимыми аргументами. Этот скрипт создаст `N` виртуальных машин, настроит между ними связность по ssh, настроит NFS, создаст linux bridge'и и vxlan интерфейсы таким образом, чтобы трафик проходил через `server2`.

Для удаления кластера нужно запустить скрипт `./remote/clear.sh`.

Важно! IP адреса `server1` и `server2` нужно прописать в скриптах `./remote/linux_bridge_up.sh`, `./remote/create_cluster.sh`.

# Задача 3
- Поднять виртуальные машины на нескольких серверах
- Трафик между виртуальными машинами должен проходить через программный коммутатор, который располагается на отдельном сервере

# Prerequisites
On local machine where you will start script `./shared/create_cluster_shared.py` you should run:
```bash
sudo apt install build-essential libssl-dev libffi-dev python3-dev python3-pip
sudo pip install cryptography tqdm==2.2.3 termcolor

```

На каждом сервере нужно создать отдельную директорию, в которой будет располагаться все необходимые для создания и работы кластера данные. Например, директория `/home/$USER/mpi/`. В ней должны быть две директории `./images` и `./cluster`. В директорию `./images` нужно скопировать образы виртуальных машин (https://disk.yandex.ru/client/disk/MC2E/ubuntu_18_04) и конфигурацию в файле config для `cloud-init`:
```bash
#cloud-config
password: ubuntu
chpasswd: { expire: False }
ssh_pwauth: True
```


# Решение
Пусть есть несколько серверов: `server1`, ..., `serverM`, и стоит задача сделать MPI кластер.
Сервера должны быть доступны друг другу.

Сначала нужно сформировать конфигурационный файл, в котором описать все сервера, их параметры (CPU, RAM, HDD, IP address, user, password). Также нужно указать сервер, на котором будет располагаться программный коммутатор, через который будут проходить TCP потоки между узлами кластера. Шаблон конфигурационного файла -> `./shared/config.template`.


# Примечания

- Нужно зайти на master ноду кластера и запустить скрипт `./local/check_connectivity.sh`, который проверит доступность slave узлов

- Простой способ проверить, что все работает
```
mpiexec.mpich -np 4 -hosts 10.0.0.3,10.0.0.4 hostname
```
- В предложенной схеме между серверами создается vxlan туннель. Чтобы пакеты не дропались коммутаторами внутренней сети (LAN), нужно уменьшить MTU у интерфейсов виртуальных машин.
```
sudo ifconfig <iface_name> mtu <size, 1450 recommended>
```
- Проверить, не запущен ли firewall на серверах и виртуальных машинах
- На серверах и виртуальных машинах проверить iptables. В идеале удалить все лишние правила, default policy сделать ACCEPT.
```
arccn@mc2e:~$ sudo iptables -t nat -S
-P PREROUTING ACCEPT
-P INPUT ACCEPT
-P OUTPUT ACCEPT
-P POSTROUTING ACCEPT
-A POSTROUTING -s 192.168.122.0/24 -d 224.0.0.0/24 -j RETURN
-A POSTROUTING -s 192.168.122.0/24 -d 255.255.255.255/32 -j RETURN
-A POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p tcp -j MASQUERADE --to-ports 1024-65535
-A POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p udp -j MASQUERADE --to-ports 1024-65535
-A POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
arccn@mc2e:~$ sudo iptables -S
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
-A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
-A OUTPUT -p tcp -m tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
-A OUTPUT -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
```
- Чтобы поставить правила выше, нужно выполнить
```
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT && \
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT && \
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT && \
sudo iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT && \
sudo iptables -A OUTPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT && \
sudo iptables -A INPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
```
См. (https://www.digitalocean.com/community/tutorials/iptables-essentials-common-firewall-rules-and-commands)

- На серверах также проверить `ebtables` для созданных linux bridge'ей. Никаких правил не должно быть.
- На серверах в `/etc/sysctl.conf` должны быть следующие параметры:
```
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0
net.bridge.bridge-nf-filter-pppoe-tagged = 0
net.bridge.bridge-nf-filter-vlan-tagged = 0
net.bridge.bridge-nf-pass-vlan-input-dev = 0
```

- затем обновить конфигурацию `# sysctl -p`
- modprobe br_netfilter (эту команду нужно выполнить, если обновить конфигурацию не удалось)

- Проверить доступность порта (https://www.tecmint.com/check-remote-port-in-linux/)
- Может понадобиться ограничить порты для `mpirun` и `mpiexec` (https://wiki.mpich.org/mpich/index.php/Using_the_Hydra_Process_Manager#Environment_Settings)
- Проверить, что ssh настроен без пароля на узлах кластера
- Проверить, что в `/etc/hosts` есть все узлы

