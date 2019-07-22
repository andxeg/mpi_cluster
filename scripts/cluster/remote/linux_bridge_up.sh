#!/bin/bash

if [ $# -ne 1 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of vxlan interfaces>\n" "$0"
    exit 1
fi


N=$1
VXLAN_START_ID=40
VXLAN_BRIDGE="br-cluster"
DEV="eth0"
LOCAL_IP="192.168.131.36"
REMOTE_IP="172.30.11.100"


# create bridge
sudo ip link add $VXLAN_BRIDGE type bridge

# add interfaces
for (( i = 0; i < $N; i++ ))
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

