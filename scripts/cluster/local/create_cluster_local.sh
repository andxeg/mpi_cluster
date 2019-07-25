#!/bin/bash

if [ $# -ne 2 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of slaves> <suffix for node name>\n" "$0"
    printf "Example: ./create_cluster.sh 2 '-second'\n"
    exit 1
fi


VM_IMAGE_PREFIX="/home/arccn/MC2E/images/xenial-server-cloudimg-amd64-disk1-"
BASE_CONFIG="/home/arccn/MC2E/images/config"

CONFIG_DIR="./config"
IMAGES_DIR="./images"

CONFIG_SCRIPT="node_setup.sh" # script for configuring cluster nodes

N=$1
SUFFIX="$2" # for example "-1", "-first", "-second"
NODES="master""$SUFFIX"

# GENERATE NODE NAMES
for ((i=1; i <= $N; i++))
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

    # create virtual machine
    printf "'%s' creation was started with image '%s'\n" "$node" "$image"

    cloud-localds $CONFIG_DIR/"config-""$node"".img" $BASE_CONFIG
    qemu-img create -f qcow2 -b $VM_IMAGE_PREFIX"$image"".qcow2" $IMAGES_DIR/"$node"".img"
    sudo virt-install --name $node --ram 1024 --vcpus=1 --os-type=linux --os-variant=ubuntu16.04 --virt-type=kvm --hvm --disk $IMAGES_DIR/"$node"".img",device=disk,bus=virtio --disk $CONFIG_DIR/"config-""$node"".img",device=cdrom --network network=default --graphics none --import --quiet --noautoconsole

    printf "'%s' was created\n\n" "$node"
done


TIMEOUT=60
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
    IP_ADDRESSES+=" "$( echo $([[ ! -z $n ]] && sudo virsh domifaddr $n) | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
done

echo "IP ADDRESSES -> "$IP_ADDRESSES

IFS=" "
read -ra HOSTS <<< "$IP_ADDRESSES"
read -ra NODES_ARRAY <<< "$NODES"

IP_ADDRESSES_COMMA="${HOSTS[0]}"
for (( i = 1; i < "${#HOSTS[@]}"; i++ ))
do
    IP_ADDRESSES_COMMA+=",""${HOSTS[$i]}"
done

echo "IP_ADDRESSES_COMMA -> ""$IP_ADDRESSES_COMMA"


# configure cluster interfaces
for (( i = 0; i < "${#HOSTS[@]}"; i++ ))
do
    name=${NODES_ARRAY[$i]}
    addr=${HOSTS[$i]}

    # copy to each cluster node configuration script
    ssh-keygen -f "/home/"$USER"/.ssh/known_hosts" -R "$addr"
    sshpass -p "ubuntu" scp -o StrictHostKeyChecking=no $CONFIG_SCRIPT ubuntu@"$addr":/tmp
    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -t ubuntu@"$addr" "sudo su -c \"chown mpiuser:mpiuser /tmp/$CONFIG_SCRIPT\" && sudo su - mpiuser -c \"mv /tmp/$CONFIG_SCRIPT /home/mpiuser/scripts/\""
done 

for (( i = 0; i < "${#HOSTS[@]}"; i++ ))
do
    name=${NODES_ARRAY[$i]}
    addr=${HOSTS[$i]}

    echo "HOST[""$i""]: NAME = "$name", IP = ""$addr"

    ssh-keygen -f "/home/"$USER"/.ssh/known_hosts" -R "$addr"

    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -t ubuntu@"$addr" "sudo su - mpiuser -c \"cd /home/mpiuser/scripts && sudo "./""$CONFIG_SCRIPT" $name $SUFFIX $IP_ADDRESSES_COMMA \""

done

printf "Well done!!!\n"

