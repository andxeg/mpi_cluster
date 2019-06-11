#!/bin/bash


HOSTS_FILE="/etc/hosts"
#HOSTS_FILE="test.txt"
NODE_TYPE=$1
IP_ADDRESSES=$2
USER="mpiuser"
PASSWD="mpiuser"

# Check number of input parameters
if [ "$#" -ne 2 ]; then
    printf "Error in input parameters\n"
    printf "Type %s <node type::= master | slaveN> <IP addresses separated by comma>\n" $0
    printf "\nExample:\n\t%s master 172.30.7.10,172.30.7.11,172.30.7.12,172.30.7.13\n" $0
    printf "\nExample:\n\t%s slave1 172.30.7.10,172.30.7.11,172.30.7.12,172.30.7.13\n" $0
    printf "\nExample:\n\t%s slave4 172.30.7.10,172.30.7.11,172.30.7.12,172.30.7.13\n" $0
    exit
fi

# Split string with IP addresses
printf "IP addresses: %s\n" "$IP_ADDRESSES"

IFS=","
read -ra HOSTS <<< "$IP_ADDRESSES"

# Print number of IP addresses
N="${#HOSTS[@]}"
if [ "$N" -eq 0 ]; then
    printf "There are not any nodes in cluster\n"
    exit
else
    printf "Cluster has %d nodes\n" $N
fi

# Save ip addresses in HOSTS_FILE
for (( i = 0; i <"$N"; i++ ))
do
    echo "HOST[""$i""] = " "${HOSTS[$i]}"
    if [ "$i" -eq 0 ]; then
        echo -e "${HOSTS[$i]}""\tmaster" >> $HOSTS_FILE
    else
        echo -e "${HOSTS[$i]}""\tslave""$i" >> $HOSTS_FILE
    fi 
done

# Change user to mpiuser

# Specific steps according to node type
if [ "$NODE_TYPE" == "master" ]; then
    printf "Specific steps for master node\n"
    printf "Generate ssh key-pair\n"

    ssh-keygen -b 2048 -t rsa -f /home/"$USER"/.ssh/id_rsa -q -N ""
    chown $USER:$USER "/home/"$USER"/.ssh/id_rsa"
    chown $USER:$USER "/home/"$USER"/.ssh/id_rsa.pub"

    printf "Copy ssh public key to all nodes\n"

    for (( i = 0; i < "$N"; i++ ))
    do
        if [ "$i" -eq 0 ]; then
            echo "sudo -u "$USER" sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no master"
            # sudo -u "$USER" ssh-copy-id master
            sudo -u "$USER" sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no master
        else
            echo "sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no "slave""$i""
            #sudo -u "$USER" ssh-copy-id "slave""$i" 
            sudo -u "$USER" sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no "slave""$i"
        fi 
    done
else
    printf "Specific steps for %s node\n" $NODE_TYPE
    # For slave node
    # Change hostname to slaveN 
    # hostname "$NODE_TYPE"
fi

echo "Well done!"

