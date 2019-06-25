#!/bin/bash

if [ $# -ne 3 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of slaves> <start_vxlan_id> <suffix for nodes names>\n" "$0"
    printf "Example: ./clear.sh 2 56 '-second'\n"
    exit 1
fi

CONFIG_DIR="./config"
IMAGES_DIR="./images"

N=$1
SUFFIX="$3"
NODES="master""$SUFFIX"

# GENERATE NODE NAMES
for ((i=1; i <= $N; i++))
do
    NODES+=" slave""$SUFFIX""-"$i
done

# DELETE WORK DIRECTORIES
for node in $NODES
do
    rm $CONFIG_DIR/"config-""$node"".img"
    rm $IMAGES_DIR/"$node"".img"
done

# DESTROY NODES
for node in $NODES
do
    sudo virsh shutdown $node
    sudo virsh destroy $node
    sudo virsh undefine $node 
done

sudo virsh list --all

# DELETE BRIDGES
VXLAN_ID_START=$2

for (( i = 0; i <= $N; i++ ))
do
    vxlan=$((VXLAN_ID_START+i))
    vxlan_iface="vxlan"$vxlan
    vxlan_bridge="br-vxlan"$vxlan

    printf "Delete bridge '%s'\n" $vxlan_bridge

    sudo ip link set $vxlan_bridge down
    sudo ip link delete $vxlan_bridge
    sudo ip link delete $vxlan_iface  
done

# show info about bridges
sudo brctl show

