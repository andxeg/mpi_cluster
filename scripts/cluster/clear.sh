#!/bin/bash

if [ $# -ne 1 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of slaves>\n" "$0"
    exit 1
fi

CONFIG_DIR="./config"
IMAGES_DIR="./images"

N=$1
NODES="master"

# GENERATE NODE NAMES
for ((i=1; i <= $N; i++))
do
    NODES+=" slave"$i 
done

# DELETE WORK DIRECTORIES
rm -rf $CONFIG_DIR $IMAGES_DIR

# DESTROY NODES
for node in $NODES
do
    sudo virsh shutdown $node
    sudo virsh destroy $node
    sudo virsh undefine $node 
done

sudo virsh list --all

# DELETE BRIDGES
VXLAN_ID_START=40

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

