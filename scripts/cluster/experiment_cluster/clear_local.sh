#!/bin/bash

if [ $# -ne 4 ]; then
    printf "error in input parameters\n"
    printf "type %s <with or without master>
                    <number of slaves>
                    <start slave number>
                    <suffix for nodes names>\n" "$0"
    printf "Example #1: %s yes 3 1 '-first'\n" "$0"
    printf "Example #2: %s no  4 4 '-first'\n" "$0"
    exit 1
fi

CONFIG_DIR="./config"
IMAGES_DIR="./images"

MASTER=$1
SLAVES_NUM=$2
SLAVE_START_NUM=$3
SUFFIX="$4"
NODES="master""$SUFFIX"


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

