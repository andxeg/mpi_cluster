#!/bin/bash

if [ $# -ne 6 ]; then
    printf "error in input parameters\n"
    printf "type %s <with or without master>
                    <number of slaves>
                    <start slave number>
                    <suffix for node name>
                    <script for vm configure>
                    <cluster's ip addresses separated by comma>\n" "$0"
    printf "Example #1: %s yes 15 1  '-first' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8,10.0.0.9,10.0.0.10,10.0.0.11,10.0.0.12,10.0.0.13,10.0.0.14,10.0.0.15,10.0.0.16'\n" "$0"
    printf "Example #2: %s no  16 16 '-first' 'node_setup.sh' '10.0.0.17,10.0.0.18,10.0.0.19,10.0.0.20,10.0.0.21,10.0.0.22,10.0.0.23,10.0.0.24,10.0.0.25,10.0.0.26,10.0.0.27,10.0.0.28,10.0.0.29,10.0.0.30,10.0.0.31,10.0.0.32'\n" "$0"
    exit 1
fi

# ============================== INPUT PARAMETERS =============================
MASTER=$1 # --master yes or --master no
SLAVES_NUM=$2
SLAVE_START_NUM=$3
SUFFIX="$4" # for example "-1", "-first", "-second"
CONFIG_SCRIPT=$5
CLUSTER_IP_ADDRESSES_COMMA=$6

# GENERATE NODE NAMES
NODES=""

if [ "$MASTER" == "yes" ] ; then
    NODES="master""$SUFFIX"
fi

for (( i = $SLAVE_START_NUM; i < ($SLAVE_START_NUM + $SLAVES_NUM); i++ ))
do
    NODES+=" slave""$SUFFIX""-"$i
done


# =============================== CONFIGURE NODES =============================
printf "Nodes configuration was started\n"
IP_ADDRESSES=""

for n in $NODES
do 
    IP_ADDRESSES+=" "$( echo $([[ ! -z $n ]] && sudo virsh domifaddr $n) | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
done

echo "IP ADDRESSES -> "$IP_ADDRESSES

echo "CLUSTER_IP_ADDRESSES_COMMA -> ""$CLUSTER_IP_ADDRESSES_COMMA"

IFS=" "
read -ra HOSTS <<< "$IP_ADDRESSES"
read -ra NODES_ARRAY <<< "$NODES"

# Configure cluster's virtual machines
for (( i = 0; i < "${#HOSTS[@]}"; i++ ))
do
    name=${NODES_ARRAY[$i]}
    addr=${HOSTS[$i]}

    echo "HOST[""$i""]: NAME = "$name", IP = ""$addr"

    ssh-keygen -f "/home/"$USER"/.ssh/known_hosts" -R "$addr"

    sshpass -p "ubuntu" ssh -o StrictHostKeyChecking=no -T ubuntu@"$addr" "sudo su - mpiuser -c \"cd /home/mpiuser/scripts && sudo "./""$CONFIG_SCRIPT" $name $SUFFIX $CLUSTER_IP_ADDRESSES_COMMA \""

done

printf "Well done!!!\n"
