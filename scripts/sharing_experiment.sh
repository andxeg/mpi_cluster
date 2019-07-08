#!/bin/bash


PROG_DIR="/home/mpiuser/cloud/experiments/NPB3.4/NPB3.4-MPI/bin" # path in master node where are programs
RESULT_DIR="/home/mpiuser/cloud/experiments/results/sharing_NPB_size_A_local" # dir in master node for results
MON_RES_DIR="/home/arccn/mpi/experiments/results/sharing_NPB_size_A_local/monitor" # dir in host machine for monitoring results

# MPI programs
# This MPI programs use only 2**N MPI processes
# Run program with one size -> B
P="is ep cg lu ft"
SIZE="A"
##SIZES="A B C"

EXPERIMENTS_AMOUNT=5
MIN_MON_WINDOW=5

MASTER_1="192.168.122.131"
MASTER_2="192.168.122.211"
CLUSTER_1="master-first slave-first-1 slave-first-2 slave-first-3 slave-first-4 slave-first-5 slave-first-6 slave-first-7 slave-first-8 slave-first-9 slave-first-10 slave-first-11 slave-first-12 slave-first-13 slave-first-14 slave-first-15"
CLUSTER_2="master-second slave-second-1 slave-second-2 slave-second-3 slave-second-4 slave-second-5 slave-second-6 slave-second-7 slave-second-8 slave-second-9 slave-second-10 slave-second-11 slave-second-12 slave-second-13 slave-second-14 slave-second-15"


: '
    Args:
        str: string with cluster node names
        int: number of nodes
        str: delimeter
'
get_nodes_str() {
    local N="$2"
    local delim="$3"
    local NODES=""

    read -ra NODES <<< "$1"

    local result="${NODES[0]}"
    for (( i = 1; i < "$N" ; i++ ))
    do
        result+="$delim""${NODES[$i]}"
    done

    echo $result
}

pidfile() {
    echo $BASHPID > "$1"
    shift
    exec "$@"
}


read -ra PROGRAM <<< "$P"

# Run first program in CLUSTER_1, second program in CLUSTER_2

N="${#PROGRAM[@]}"

for (( k = 0; k < EXPERIMENTS_AMOUNT; k++ ))
do
    for (( i = 0; i < N; i++ ))
    do
        for (( j = i; j < N; j++ ))
        do
            P1="${PROGRAM[$i]}"".""$SIZE"".x"
            P2="${PROGRAM[$j]}"".""$SIZE"".x"

            printf "Start group $P1 and $P2\n"
            for np1 in 4 8 16
            do
                for np2 in 4 8 16
                do
                    monitor_first="$(get_nodes_str "$CLUSTER_1" $np1 "\|")"
                    monitor_second="$(get_nodes_str "$CLUSTER_2" $np2 "\|")" ## launch get_monitor_nodes
                    cluster_first="$(get_nodes_str "$CLUSTER_1" $np1 ",")"
                    cluster_second="$(get_nodes_str "$CLUSTER_2" $np2 ",")"

                    printf "[Experiment #$k] RUN PROCS: ($P1, $P2); NP: ($np1, $np2); NODES: (%s, %s); MONITOR(%s, %s) \n" "$cluster_first" "$cluster_second " "$monitor_first" "$monitor_second"

                    # Start monitoring
                    pidfile "/tmp/kvmtop_1.pid" sudo kvmtop -c qemu:///system --printer=text --cpu --net | pidfile "/tmp/grep_1.pid" grep -w "$monitor_first" &> $MON_RES_DIR/$P1"_"$P2"_"$np1"_"$np2"_"mon_first_e_"$k".out &
                    pidfile "/tmp/kvmtop_2.pid" sudo kvmtop -c qemu:///system --printer=text --cpu --net | pidfile "/tmp/grep_2.pid" grep -w "$monitor_second" &> $MON_RES_DIR/$P2"_"$P1"_"$np2"_"$np1"_"mon_second_e_"$k".out &

                    # Run MPI programs
                    sshpass -p "mpiuser" ssh -o StrictHostKeyChecking=no -tT mpiuser@$MASTER_1 "mpirun -np $np1 --hosts $cluster_first $PROG_DIR/$P1 &> $RESULT_DIR/$P1\_$P2\_$np1\_$np2\_e_$k.out" &
                    pids[0]=$!
                    sshpass -p "mpiuser" ssh -o StrictHostKeyChecking=no -tT mpiuser@$MASTER_2 "mpirun -np $np2 --hosts $cluster_second $PROG_DIR/$P2 &> $RESULT_DIR/$P2\_$P1\_$np2\_$np1\_e_$k.out" &
                    pids[1]=$!
 
                    sleep $MIN_MON_WINDOW

                    wait ${pids[0]}
                    sudo kill -9 $(cat "/tmp/kvmtop_1.pid")
                    sudo kill -9 $(cat "/tmp/grep_1.pid")

                    wait ${pids[1]}
                    sudo kill -9 $(cat "/tmp/kvmtop_2.pid")
                    sudo kill -9 $(cat "/tmp/grep_2.pid")

                done
            done
            printf "\n"

        done
    done
done

echo "Well done!!!"
