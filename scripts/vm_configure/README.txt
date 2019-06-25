В данной папке находится скрипт для настройки MPI кластера node_setup.sh

Скрипт принимает три параметра
 - master или slaveM, где M - это номер slave узла
 - суффикс у имени узла, например, если суффикс '-second', то имена узлов кластеров будут следующими: master-second, slave-second-1, slave-second-2, ...
 - список ip адресов в виде: <master IP address>,<slave1 IP address>,...,<slaveM IP address>

Скрипт должен выполняться c sudo.

Примеры выполнения скрипта:
   sudo ./node_setup.sh master '-second' 192.168.19.113,192.168.19.102,192.168.19.235,192.168.19.29
   sudo ./node_setup.sh slave1 '-second' 192.168.19.113,192.168.19.102,192.168.19.235,192.168.19.29

