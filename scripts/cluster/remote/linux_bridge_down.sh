#!/bin/bash

if [ $# -ne 1 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of vxlan interfaces>\n" "$0"
    exit 1
fi


N=$1
VXLAN_START_ID=40
VXLAN_BRIDGE="br-cluster"


# down bridge and delete it
printf "Bridge '%s' was down and deleted\n" "$VXLAN_BRIDGE"
sudo ip link set $VXLAN_BRIDGE down
sudo ip link delete $VXLAN_BRIDGE

# delete vxlan interfaces
for (( i = 0; i < $N; i++ ))
do
    vxlan="$((VXLAN_START_ID+i))"
    vxlan_iface="vxlan"$vxlan
   
    printf "Delete interface '%s'\n" "$vxlan_iface"

    sudo ip link delete $vxlan_iface
done

# show info about devices
sudo brctl show

