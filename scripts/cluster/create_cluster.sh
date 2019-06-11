#!/bin/bash

if [ $# -ne 1 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of slaves>\n" "$0"
    exit 1
fi


VM_IMAGE_PREFIX="/home/arccn/images/xenial-server-cloudimg-amd64-disk1-"
BASE_CONFIG="/home/arccn/images/config"

CONFIG_DIR="./config"
IMAGES_DIR="./images"

VXLAN_ID_START=40
DEV="br-ext"
LOCAL_IP="172.30.11.100"   # local server with virtual machines
REMOTE_IP="192.168.131.36" # remote server with ovs or linux bridge

CLUSTER_NET="10.0.0."
CLUSTER_IFACE="ens3"

N=$1
NODES="master"

# GENERATE NODE NAMES
for ((i=1; i <= $N; i++))
do
    NODES+=" slave"$i 
done


# CREATE WORK DIRECTORIES
mkdir -p $CONFIG_DIR
mkdir -p $IMAGES_DIR

# ============ CREATE CONFIG, IMAGE and START NODES =======
id=0
LANG=en_US
for node in $NODES
do
    image="master"
    if [ "$node" != "master" ] ; then
        image="slave"
    fi

    # create bridge
    vxlan=$((VXLAN_ID_START+id))
    vxlan_iface="vxlan"$vxlan
    vxlan_bridge="br-vxlan"$vxlan
    id=$((id+1))

    # printf "id -> '%d'; iface -> '%s'; bridge -> '%s'\n" $id $vxlan_iface $vxlan_bridge

    sudo ip link add name $vxlan_iface type vxlan id $vxlan dev $DEV remote $REMOTE_IP local $LOCAL_IP dstport 4789
    sudo ip link add $vxlan_bridge type bridge
    sudo ip link set $vxlan_iface master $vxlan_bridge
    sudo ip link set $vxlan_iface up
    sudo ip link set $vxlan_bridge up  

    printf "bridge '%s' was created\n" "$vxlan_bridge"

    # create virtual machine
    printf "%s creation was started\n" "$node"

    cloud-localds $CONFIG_DIR/"config-""$node"".img" $BASE_CONFIG
    qemu-img create -f qcow2 -b $VM_IMAGE_PREFIX"$image"".qcow2" $IMAGES_DIR/"$node"".img"
    sudo virt-install --name $node --ram 1024 --vcpus=1 --os-type=linux --os-variant=ubuntu16.04 --virt-type=kvm --hvm --disk $IMAGES_DIR/"$node"".img",device=disk,bus=virtio --disk $CONFIG_DIR/"config-""$node"".img",device=cdrom --network network=default --network bridge="$vxlan_bridge" --graphics none --import --quiet --noautoconsole

    printf "%s was created\n\n" "$node"
done

# show info about bridges
sudo brctl show


TIMEOUT=10
printf "Wait %d seconds while nodes are assigned IP addresses\n" "$TIMEOUT"
sleep $TIMEOUT

printf "Network addresses\n"
sudo virsh net-dhcp-leases default

sudo virsh list --all


# =================== CONFIGURE NODES =====================
printf "Nodes configuration was started\n"
NAMES=$(sudo virsh list --name)
IP_ADDRESSES=""

for n in $NAMES
do 
    if [ "$(echo "$NODES" | grep -w "$n")" == "" ]
    then
        echo "NOT CLUSTER NODE -> ""$n"
        continue
    fi

    IP_ADDRESSES+=" "$( echo $([[ ! -z $n ]] && sudo virsh domifaddr $n) | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
done

echo "IP ADDRESSES -> "$IP_ADDRESSES

# SSH TO NODES AND START CONFIGURE
CLUSTER_IP_ADDRESSES="10.0.0.2"
for (( i = 1; i <= $N; i++ ))
do
    CLUSTER_IP_ADDRESSES+=",""$CLUSTER_NET""$((i+2))"
done

echo "CLUSTER_IP_ADDRESSES -> ""$CLUSTER_IP_ADDRESSES"

IFS=" "
read -ra HOSTS <<< "$IP_ADDRESSES"
read -ra NODES_ARRAY <<< "$NODES"

HOSTS_COMMAS="${HOSTS[0]}"
for (( i = 1; i < "${#HOSTS[@]}"; i++ ))
do
    HOSTS_COMMAS+=",""${HOSTS[$i]}"
done

echo "HOSTS_COMMAS -> ""$HOSTS_COMMAS"

exit 1 # TODO add to node_setup.sh CLUSTER_IP_ADDRESSES and set ip_address to $CLUSTER_IFACE 

for (( i = 0; i < "${#HOSTS[@]}"; i++ ))
do
    name=${NODES_ARRAY[$i]}
    addr=${HOSTS[$i]}
    echo "HOST[""$i""]: NAME = "$name", IP = ""$addr"
    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -t ubuntu@"$addr" "sudo su - mpiuser -c \"cd /home/mpiuser/scripts && sudo ./node_setup.sh $name $HOSTS_COMMAS\""

    # NOTE hostname changing command you should add to node_setup.sh
    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -t ubuntu@"$addr" "sudo su -c \"hostname $name && echo $name > /etc/hostname\""

done

printf "Well done!!!\n"

