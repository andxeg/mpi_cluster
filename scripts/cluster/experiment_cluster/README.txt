======================= Cluster nodes =====================

Соединены в full-mesh
head
w1
w2
w3
w4

Следующие сервера соединены только с head'ом
s247
(check) smz
(check) s761
(???) mc2e


Копии файлов /etc/network/interfaces находятся в директории ./interfaces,
для Жениного стенда в директории stepanov_cluster/interfaces


========== VM with fibre channels ==========
Create VM. Add vm to cluster-br
$ cd ~/MC2E/cluster/
$ cloud-localds ./config/config-cluster-test.img /home/arccn/MC2E/images/config
$ qemu-img create -f qcow2 -b /home/arccn/MC2E/images/xenial-server-cloudimg-amd64-disk1-master.qcow2 ./images/cluster-test.img
$ sudo virt-install --name cluster-test --ram 1024 --vcpus=1 --os-type=linux --os-variant=ubuntu16.04 --virt-type=kvm --hvm --disk "./images/cluster-test.img",device=disk,bus=virtio --disk "./config/config-cluster-test.img",device=cdrom --network network=default --network bridge=cluster-br --graphics none --import --quiet --noautoconsole

Into VM create interface
sudo su -c "printf '\nauto ens3\niface ens3 inet static\naddress 1.0.0.2\nnetmask 255.255.255.0\nmtu 1450\n' >> /etc/network/interfaces.d/50-cloud-init.cfg  && ifup ens3 && ifconfig ens3 mtu 1450"

Delete VM
$ cd ~/MC2E/cluster/
$ rm ./config/config-cluster-test.img
$ rm ./images/cluster-test.img
$ sudo virsh shutdown cluster-test && sudo virsh destroy cluster-test && sudo virsh undefine cluster-test


Average delay calculation
$ ping -c 50 <ip_address> > ping.out
$ cat ping.out | grep "time=" | cut -d'=' -f4 | awk '{sum+=$1; n+=1} END { print sum/n}'


=== Delete IP address from interface
ip addr del 10.22.30.44/16 dev eth0

=== Check OVS instead linux bridge ===
Check with head and w3
Create:
head$ sudo ovs-vsctl add-br cluster-ovs
w3$ sudo ovs-vsctl add-br cluster-ovs

Add optical interface
head$ sudo ovs-vsctl add-port cluster-ovs ens9f0
w3$ sudo ovs-vsctl add-port cluster-ovs ens1f0

Delete interface from bridge
sudo ovs-vsctl del-port cluster-ovs ens9f0

Delete bridge
sudo ovs-vsctl del-br cluster-ovs


See [1] - instruction how create KVM VM and
attach it to OVS bridge.

See [2] - connect KVM VM to OVS

Just add “virtualport_type=openvswitch” to your network settings.


sudo virt-install --name cluster-test --ram 1024 --vcpus=1 --os-type=linux --os-variant=ubuntu16.04 --virt-type=kvm --hvm --disk "./images/cluster-test.img",device=disk,bus=virtio --disk "./config/config-cluster-test.img",device=cdrom --network network=default --network bridge=cluster-ovs,virtualport_type=openvswitch --graphics none --import --quiet --noautoconsole



======= Manual cluster creation with fibre channel ========
На сервера в директории MC2E/cluster нужно скопировать
    скрипты clear_local.sh, configure_vms.sh node_setup.sh start_vms_opt.sh

    $ scp *.sh arccn@172.30.2.1:/home/arccn/MC2E/cluster && scp *.sh arccn@172.30.2.11:/home/arccn/MC2E/cluster && scp *.sh arccn@172.30.2.12:/home/arccn/MC2E/cluster && scp *.sh arccn@172.30.2.13:/home/arccn/MC2E/cluster && scp *.sh arccn@172.30.2.14:/home/arccn/MC2E/cluster

Три этапа создания
    # STEP 1: create bridges with necessary interfaces
    # STEP 2: start virtual machine in each server and attach them to bridges
    # STEP 3: configure virtual machines in whole cluster


# STEP 1: create bridges with necessary interfaces
Создаем коммутатор, добавляем туда оптические интерфейсы.

    head -> добавляем все оптические интерфейсы, которые ведут
    на другие сервера

    Название коммутаторов -> cluster-br

    Для остальных серверов добавляем только интерфейс на head (пока,
    потом можно добавить все интерфейсы, но при этом придется
    настроить STP, чтобы не было штормов, либо прописывать всегда
    грамотно коммутацию по макам виртуальных машин - при создании
    виртуальной машины в virt-intstall можно указывать конкретный
    мак адрес)

    Проверка оптических интерфейсов
    $ iface=headln1; sudo ifconfig $iface up && sudo ethtool $iface


# STEP 2: start virtual machine in each server and attach them to bridges
    На каждом сервере по 2 ВМ сделать
    head -> master-experiment, slave-experiment-1
    w1   -> slave-experiment-2, slave-experiment-3
    ### w2   -> slave-experiment-4, slave-experiment-5
    w3   -> slave-experiment-4, slave-experiment-5
    w4   -> slave-experiment-6, slave-experiment-7

    head -> ./start_vms_opt.sh yes 1 1 '-experiment' 1 1024 1 '/home/arccn/MC2E/images' 'cluster-br' 'node_setup.sh' 30

    w1   -> ./start_vms_opt.sh no  2 2 '-experiment' 3 1024 1 '/home/arccn/MC2E/images' 'cluster-br' 'node_setup.sh' 30

    ### w2   -> ./start_vms_opt.sh no  2 4 '-experiment' 5 1024 1 '/data/MC2E/images' 'cluster-br' 'node_setup.sh' 30

    w3   -> ./start_vms_opt.sh no  2 4 '-experiment' 5 1024 1 '/home/arccn/MC2E/images' 'cluster-br' 'node_setup.sh' 30

    w4   -> ./start_vms_opt.sh no  2 6 '-experiment' 7 1024 1 '/home/arccn/MC2E/images' 'cluster-br' 'node_setup.sh' 30


# STEP 3: configure virtual machines in whole cluster

    head -> bash ./configure_vms.sh yes 1 1 '-experiment' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8'

    w1   -> bash ./configure_vms.sh no  2 2 '-experiment' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8'

    ### w2   -> bash ./configure_vms.sh no  2 4 '-experiment' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8'

    w3   -> ./configure_vms.sh no  2 4 '-experiment' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8'

    w4   -> bash ./configure_vms.sh no  2 6 '-experiment' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8'


# Delete cluster virtual machines
    head -> sudo ./clear_local.sh yes 1 1 '-experiment'
    w1   -> sudo ./clear_local.sh no  2 2 '-experiment'
    ### w2   -> sudo ./clear_local.sh no  2 4 '-experiment'
    w3   -> sudo ./clear_local.sh no  2 4 '-experiment'
    w4   -> sudo ./clear_local.sh no  2 6 '-experiment'


========================= Links ===========================
1.  http://fosshelp.blogspot.com/2014/10/kvm-virtual-machine-attach-openvswitch.html
2.  https://pinrojas.com/2017/05/03/how-to-use-virt-install-to-connect-at-openvswitch-bridges/


Loader_kdump и origin_ubuntu можешь скопировать
