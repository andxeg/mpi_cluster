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

sudo ip link set $VXLAN_BRIDGE down
sudo ip link delete $VXLAN_BRIDGE
sudo ip link delete $VXLAN_IFACE

# show info about devices
sudo brctl show

