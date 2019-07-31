#!/bin/bash


HOSTS_FILE="/etc/hosts"
CLUSTER_HOSTS_FILE="/home/mpiuser/hostfile"
#HOSTS_FILE="test.txt"
NODE_TYPE=$1
SUFFIX=$2
IP_ADDRESSES=$3
USER="mpiuser"
PASSWD="mpiuser"

# Check number of input parameters
if [ "$#" -ne 3 ]; then
    printf "Error in input parameters\n"
    printf "Type %s <node type::= master | slaveN> <suffix for node name> <IP addresses separated by comma>\n" $0
    printf "\nExample:\n\t%s master '-second' 172.30.7.10,172.30.7.11,172.30.7.12,172.30.7.13\n" $0
    printf "\nExample:\n\t%s slave1 '-second' 172.30.7.10,172.30.7.11,172.30.7.12,172.30.7.13\n" $0
    printf "\nExample:\n\t%s slave4 '-second' 172.30.7.10,172.30.7.11,172.30.7.12,172.30.7.13\n" $0
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
        echo -e "${HOSTS[$i]}""\tmaster""$SUFFIX" >> $HOSTS_FILE
        echo -e "master""$SUFFIX" >> $CLUSTER_HOSTS_FILE
    else
        echo -e "${HOSTS[$i]}""\tslave""$SUFFIX""-""$i" >> $HOSTS_FILE
        echo -e "slave""$SUFFIX""-""$i" >> $CLUSTER_HOSTS_FILE
    fi 
done

# Change hostname for virtual machine
sudo hostname $NODE_TYPE
sudo echo $NODE_TYPE > /etc/hostname

# Specific steps according to node type
if echo "$NODE_TYPE" | grep -qw "master"; then
    printf "Specific steps for master node\n"
    printf "Generate ssh key-pair\n"

    ssh-keygen -b 2048 -t rsa -f /home/"$USER"/.ssh/id_rsa -q -N ""
    chown $USER:$USER "/home/"$USER"/.ssh/id_rsa"
    chown $USER:$USER "/home/"$USER"/.ssh/id_rsa.pub"

    printf "Copy ssh public key to all nodes\n"

    for (( i = 0; i < "$N"; i++ ))
    do
        if [ "$i" -eq 0 ]; then
            echo "sudo -u "$USER" sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no master""$SUFFIX"
            sudo -u "$USER" sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no master"$SUFFIX"
        else
            echo "sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no "slave""$SUFFIX""-""$i""
            sudo -u "$USER" sshpass -p"$PASSWD" ssh-copy-id -i /home/"$USER"/.ssh/id_rsa.pub -oStrictHostKeyChecking=no "slave""$SUFFIX""-""$i"
        fi 
    done
else
    # Specific steps for slave node
    printf "Specific steps for %s node\n" $NODE_TYPE

    # delete old mount if exists
    sudo sed -i '/\/home\/mpiuser\/cloud/d' /etc/fstab
    sudo umount -f -l '/home/mpiuser/cloud'

    sudo mount -t nfs master"$SUFFIX":/home/mpiuser/cloud /home/mpiuser/cloud
    echo -e "master""$SUFFIX"":/home/mpiuser/cloud /home/mpiuser/cloud nfs" >> "/etc/fstab"
fi

echo "Well done!"
