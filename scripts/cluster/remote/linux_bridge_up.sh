#!/bin/bash

if [ $# -ne 6 ]; then
    printf "error in input parameters\n"
    printf "type %s <start vxlan id> <number of vxlan interfaces> <vxlan bridge name> <dev> <local ip> <remote ip>\n" "$0"
    printf "Example: %s 40 16 br-cluster eth0 192.168.131.36 172.30.11.100\n" "$0"
    exit 1
fi


VXLAN_START_ID=$1
VXLAN_NUMBER=$2
VXLAN_BRIDGE=$3
DEV=$4
LOCAL_IP=$5
REMOTE_IP=$6


if [[ ! `ip -d link show $VXLAN_BRIDGE | tail -n +2 | grep bridge` ]] ; then
    printf "Bridge %s is not existed. Creating...\n" "$VXLAN_BRIDGE"

    sudo ip link add $VXLAN_BRIDGE type bridge

    printf "%s was created\n" "$VXLAN_BRIDGE"
fi

# add interfaces
for (( i = 0; i < $VXLAN_NUMBER; i++ ))
do
    vxlan="$((VXLAN_START_ID+i))"
    vxlan_iface="vxlan"$vxlan

    printf "Create interface '%s'\n" "$vxlan_iface"

    sudo ip link add name $vxlan_iface type vxlan id $vxlan dev $DEV remote $REMOTE_IP local $LOCAL_IP dstport 4789
    sudo ip link set $vxlan_iface master $VXLAN_BRIDGE
    sudo ip link set $vxlan_iface up
done

# up bridge
sudo ip link set $VXLAN_BRIDGE up

# show info about bridges
sudo brctl show

