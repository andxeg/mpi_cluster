#!/bin/bash

if [ $# -ne 3 ]; then
    printf "error in input parameters\n"
    printf "type %s <start vxlan id> <number of vxlan interfaces> <vxlan bridge name>\n" "$0"
    printf "Example: %s 40 16 br-cluster\n" "$0"
    exit 1
fi


VXLAN_START_ID=$1
VXLAN_NUMBER=$2
VXLAN_BRIDGE=$3


# down bridge and delete it
printf "Bridge '%s' was down and deleted\n" "$VXLAN_BRIDGE"
sudo ip link set $VXLAN_BRIDGE down
sudo ip link delete $VXLAN_BRIDGE

# delete vxlan interfaces
for (( i = 0; i < $VXLAN_NUMBER; i++ ))
do
    vxlan="$((VXLAN_START_ID+i))"
    vxlan_iface="vxlan"$vxlan
   
    printf "Delete interface '%s'\n" "$vxlan_iface"

    sudo ip link delete $vxlan_iface
done

# show info about devices
sudo brctl show

