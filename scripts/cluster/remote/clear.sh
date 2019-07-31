#!/bin/bash

if [ $# -ne 5 ]; then
    printf "error in input parameters\n"
    printf "type %s <with or without master>
                    <number of slaves>
                    <start slave number>
                    <start_vxlan_id>
                    <suffix for nodes names>\n" "$0"
    printf "Example #1: ./clear.sh yes 3 1 40 '-first'\n"
    printf "Example #2: ./clear.sh no  4 4 44 '-first'\n"
    exit 1
fi

CONFIG_DIR="./config"
IMAGES_DIR="./images"

MASTER=$1
SLAVES_NUM=$2
SLAVE_START_NUM=$3
VXLAN_ID_START=$4
SUFFIX="$5"
NODES="master""$SUFFIX"

BRIDGES_NUM=0

# GENERATE NODE NAMES
NODES=""

if [ "$MASTER" == "yes" ] ; then
    NODES="master""$SUFFIX"
    BRIDGES_NUM=1
fi

for ((i=$SLAVE_START_NUM; i < ($SLAVE_START_NUM + $SLAVES_NUM); i++))
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
(( BRIDGES_NUM += $SLAVES_NUM ))
for (( i = 0; i < $BRIDGES_NUM; i++ ))
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

