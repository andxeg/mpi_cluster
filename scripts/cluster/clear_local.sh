#!/bin/bash

if [ $# -ne 2 ]; then
    printf "error in input parameters\n"
    printf "type %s <number of slaves> <suffix for nodes names>\n" "$0"
    printf "Example: ./clear.sh 2 '-second'\n"
    exit 1
fi

CONFIG_DIR="./config"
IMAGES_DIR="./images"

N=$1
SUFFIX="$2"
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

