#!/bin/bash

if [ $# -ne 11 ]; then
    printf "error in input parameters\n"
    printf "type %s <with or without master>
                    <number of slaves>
                    <start slave number>
                    <suffix for node name>
                    <start ip addresses in subnet 10.0.0.0/24>
                    <virtual machine RAM>
                    <virtual machine vCPUs>
                    <directory with images>
                    <cluster bridge name>
                    <script for vm configure>
                    <timeout for vms start>\n" "$0"
    printf "Example #1: %s yes 15 1 '-first' 1 1024 1 '/home/arccn/mpi' 'cluster-br' 'node_setup.sh' 30\n" "$0"
    printf "Example #2: %s no 16 16 '-first' 17 1024 1 '/home/arccn/mpi' 'cluster-br' 'node_setup.sh' 30\n" "$0"
    exit 1
fi

# ============================== INPUT PARAMETERS =============================
MASTER=$1 # --master yes or --master no
SLAVES_NUM=$2
SLAVE_START_NUM=$3
SUFFIX="$4" # for example "-1", "-first", "-second"
START_CLUSTER_ADDR=$5
VM_RAM=$6
VM_CPU=$7
VM_IMAGE_PREFIX="$8"/"xenial-server-cloudimg-amd64-disk1-"
BASE_CONFIG="$8"/"/config"

CLUSTER_BRIDGE_NAME=${9} # for example "br-ext"
CONFIG_SCRIPT=${10} # script for configuring cluster nodes
TIMEOUT=${11}


CLUSTER_NET="10.0.0."
CLUSTER_IFACE="ens3"
CLUSTER_IFACE_CONFIG="/etc/network/interfaces.d/50-cloud-init.cfg"
CONFIG_DIR="./config"
IMAGES_DIR="./images"


# ============================= GENERATE NODE NAMES ===========================
NODES=""

if [ "$MASTER" == "yes" ] ; then
    NODES="master""$SUFFIX"
fi

for (( i = $SLAVE_START_NUM; i < ($SLAVE_START_NUM + $SLAVES_NUM); i++ ))
do
    NODES+=" slave""$SUFFIX""-"$i
done

# CREATE WORK DIRECTORIES
mkdir -p $CONFIG_DIR
mkdir -p $IMAGES_DIR

# ====================== CREATE CONFIG, IMAGE and START NODES =================

# Start default network
sudo virsh net-start default

LANG=en_US
for node in $NODES
do
    image="master"
    if [ "$node" != "master""$SUFFIX" ] ; then
        image="slave"
    fi

    # create virtual machine
    printf "'%s' creation was started with image '%s'\n" "$node" "$image"

    cloud-localds $CONFIG_DIR/"config-""$node"".img" $BASE_CONFIG
    qemu-img create -f qcow2 -b $VM_IMAGE_PREFIX"$image"".qcow2" $IMAGES_DIR/"$node"".img"
    sudo virt-install --name $node --ram $VM_RAM --vcpus=$VM_CPU --os-type=linux --os-variant=ubuntu16.04 --virt-type=kvm --hvm --disk $IMAGES_DIR/"$node"".img",device=disk,bus=virtio --disk $CONFIG_DIR/"config-""$node"".img",device=cdrom --network network=default --network bridge="$CLUSTER_BRIDGE_NAME" --graphics none --import --quiet --noautoconsole

    printf "'%s' was created\n\n" "$node"
done

# show info about bridges
sudo brctl show


printf "Wait %d seconds while nodes are assigned IP addresses\n" "$TIMEOUT"
sleep $TIMEOUT

printf "Network addresses\n"
sudo virsh net-dhcp-leases default

sudo virsh list --all


# =============================== CONFIGURE NODES =============================
printf "Nodes configuration was started\n"
IP_ADDRESSES=""

for n in $NODES
do 
    IP_ADDRESSES+=" "$( echo $([[ ! -z $n ]] && sudo virsh domifaddr $n) | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
done

echo "IP ADDRESSES -> "$IP_ADDRESSES

IFS=" "
read -ra HOSTS <<< "$IP_ADDRESSES"
read -ra NODES_ARRAY <<< "$NODES"

# SSH TO NODES AND START CONFIGURE
CLUSTER_IP_ADDRESSES=""
for (( i = $START_CLUSTER_ADDR; i < ($START_CLUSTER_ADDR + ${#NODES_ARRAY[@]}); i++ ))
do
    CLUSTER_IP_ADDRESSES+=" ""$CLUSTER_NET""$i"
done

echo "CLUSTER_IP_ADDRESSES -> ""$CLUSTER_IP_ADDRESSES"

IFS=" "
read -ra CLUSTER_HOSTS <<< "$CLUSTER_IP_ADDRESSES"
CLUSTER_IP_ADDRESSES_COMMA="${CLUSTER_HOSTS[0]}"
for (( i = 1; i < "${#CLUSTER_HOSTS[@]}"; i++ ))
do
    CLUSTER_IP_ADDRESSES_COMMA+=",""${CLUSTER_HOSTS[$i]}"
done

echo "CLUSTER_IP_ADDRESSES_COMMA -> ""$CLUSTER_IP_ADDRESSES_COMMA"


# configure cluster interfaces
for (( i = 0; i < "${#HOSTS[@]}"; i++ ))
do
    name=${NODES_ARRAY[$i]}
    addr=${HOSTS[$i]}
    cluster_ip=${CLUSTER_HOSTS[$i]}

    # set ip address to cluster net interface
    ssh-keygen -f "/home/"$USER"/.ssh/known_hosts" -R "$addr"
    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -T ubuntu@"$addr" "sudo su -c \" printf '\nauto %s\niface %s inet static\naddress %s\nnetmask 255.255.255.0\nmtu 1450\n' $CLUSTER_IFACE $CLUSTER_IFACE $cluster_ip >> $CLUSTER_IFACE_CONFIG && ifup $CLUSTER_IFACE && ifconfig $CLUSTER_IFACE mtu 1450\""

    # copy to each cluster node configuration script
    sshpass -p "ubuntu" scp $CONFIG_SCRIPT ubuntu@"$addr":/tmp
    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -T ubuntu@"$addr" "sudo su -c \"chown mpiuser:mpiuser /tmp/$CONFIG_SCRIPT\" && sudo su - mpiuser -c \"mv /tmp/$CONFIG_SCRIPT /home/mpiuser/scripts/\""
done 

printf "Well done!!!\n"
