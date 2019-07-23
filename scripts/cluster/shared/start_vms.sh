#!/bin/bash


# TODO
# add with or without master flag
# add start number of slave

# TODO
# move timeout to input parameters

if [ $# -ne 8 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of slaves> <start_vxlan_id> <suffix for node name>
            <start ip addresses in subnet 10.0.0.0/24> <directory with images>
            <external interface> <local ip> <remote ip>\n" "$0"
    printf "Example: %s 16 40 '-first' 1 '/home/arccn/mpi' 'br-ext' 172.30.11.100 192.168.131.36\n" "$0"
    exit 1
fi


SLAVES_NUM=$1
VXLAN_ID_START=$2
SUFFIX="$3" # for example "-1", "-first", "-second"
CONFIG_SCRIPT="node_setup.sh" # script for configuring cluster nodes
START_CLUSTER_ADDR=$4
VM_IMAGE_PREFIX="$5"/"xenial-server-cloudimg-amd64-disk1-"
BASE_CONFIG="$5"/"/config"

DEV=$6 # for example "br-ext"
LOCAL_IP=$7   # local server with virtual machines
REMOTE_IP=$8 # remote server with ovs or linux bridge


CLUSTER_NET="10.0.0."
CLUSTER_IFACE="ens3"
CLUSTER_IFACE_CONFIG="/etc/network/interfaces.d/50-cloud-init.cfg"
CONFIG_DIR="./config"
IMAGES_DIR="./images"


# GENERATE NODE NAMES
NODES="master""$SUFFIX"
for ((i=1; i <= $SLAVES_NUM; i++))
do
    NODES+=" slave""$SUFFIX""-"$i
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
    if [ "$node" != "master""$SUFFIX" ] ; then
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
    printf "'%s' creation was started with image '%s'\n" "$node" "$image"

    cloud-localds $CONFIG_DIR/"config-""$node"".img" $BASE_CONFIG
    qemu-img create -f qcow2 -b $VM_IMAGE_PREFIX"$image"".qcow2" $IMAGES_DIR/"$node"".img"
    sudo virt-install --name $node --ram 1024 --vcpus=1 --os-type=linux --os-variant=ubuntu16.04 --virt-type=kvm --hvm --disk $IMAGES_DIR/"$node"".img",device=disk,bus=virtio --disk $CONFIG_DIR/"config-""$node"".img",device=cdrom --network network=default --network bridge="$vxlan_bridge" --graphics none --import --quiet --noautoconsole

    printf "'%s' was created\n\n" "$node"
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
IP_ADDRESSES=""

for n in $NODES
do 
##    if [ "$(echo "$NODES" | grep -w "$n")" == "" ]
##    then
##        echo "NOT CLUSTER NODE -> ""$n"
##        continue
##    fi

    IP_ADDRESSES+=" "$( echo $([[ ! -z $n ]] && sudo virsh domifaddr $n) | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
done

echo "IP ADDRESSES -> "$IP_ADDRESSES

# SSH TO NODES AND START CONFIGURE
CLUSTER_IP_ADDRESSES="$CLUSTER_NET""$START_CLUSTER_ADDR"
for (( i = 1; i <= $SLAVES_NUM; i++ ))
do
    CLUSTER_IP_ADDRESSES+=" ""$CLUSTER_NET""$(($START_CLUSTER_ADDR+i))"
done

echo "CLUSTER_IP_ADDRESSES -> ""$CLUSTER_IP_ADDRESSES"

IFS=" "
read -ra HOSTS <<< "$IP_ADDRESSES"
read -ra NODES_ARRAY <<< "$NODES"
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
    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -t ubuntu@"$addr" "sudo su -c \" printf '\nauto %s\niface %s inet static\naddress %s\nnetmask 255.255.255.0\nmtu 1450\n' $CLUSTER_IFACE $CLUSTER_IFACE $cluster_ip >> $CLUSTER_IFACE_CONFIG && ifup $CLUSTER_IFACE && ifconfig $CLUSTER_IFACE mtu 1450\""

    # copy to each cluster node configuration script
    sshpass -p "ubuntu" scp $CONFIG_SCRIPT ubuntu@"$addr":/tmp
    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -t ubuntu@"$addr" "sudo su -c \"chown mpiuser:mpiuser /tmp/$CONFIG_SCRIPT\" && sudo su - mpiuser -c \"mv /tmp/$CONFIG_SCRIPT /home/mpiuser/scripts/\""
done 

printf "Well done!!!\n"
