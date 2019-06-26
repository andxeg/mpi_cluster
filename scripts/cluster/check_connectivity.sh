#!/bin/bash

N=$1
SUFFIX=$2


if [ "$#" -ne 2 ]; then
    printf "Error in input parameters\n"
    printf "Type %s <number of slave> <suffix for node name>\n" "$0"
    printf "Example: %s 15 '-first'\n" "$0"
    exit
fi


# GENERATE NODE NAMES
NODES="master""$SUFFIX"
for ((i=1; i <= $N; i++))
do
    NODES+=" slave""$SUFFIX""-"$i
done

for node in $NODES; do ssh -t "$node" "exit"; done

for node in $NODES; do ping -c5 "$node"; done

