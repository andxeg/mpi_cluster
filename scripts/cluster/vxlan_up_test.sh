#!/bin/bash

if [ $# -ne 1 ]; then
    printf "error in input parameters\n"
    printf "type %s <vxlan id>\n" "$0"
    exit 1
fi

# vxlan id
VXLAN="$1"
VXLAN_IFACE="vxlan"$VXLAN
VXLAN_BRIDGE="br-vxlan"$VXLAN

printf "%s; %s; %s\n" "$VXLAN" "$VXLAN_IFACE" "$VXLAN_BRIDGE"

DEV="br-ext"
LOCAL_IP="172.30.11.100"
REMOTE_IP="192.168.131.36"
##DEV="eth0"
##LOCAL_IP="192.168.131.36"
##REMOTE_IP="172.30.11.100"

sudo ip link add name $VXLAN_IFACE type vxlan id $VXLAN dev $DEV remote $REMOTE_IP local $LOCAL_IP dstport 4789
sudo ip link add $VXLAN_BRIDGE type bridge
sudo ip link set $VXLAN_IFACE master $VXLAN_BRIDGE
sudo ip link set $VXLAN_IFACE up
sudo ip link set $VXLAN_BRIDGE up

# show info about bridges
sudo brctl show

# show forwarding table
bridge fdb show dev $VXLAN_IFACE
