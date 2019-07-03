#!/bin/bash


PROG_DIR="/home/mpiuser/cloud/experiments/NPB3.4/NPB3.4-MPI/bin" # path in master node where are programs
RESULT_DIR="/home/mpiuser/cloud/experiments/results/pure_NPB" # dir in master node for results
MON_RES_DIR="/home/arccn/mpi/experiments/results/pure_NPB/monitor" # dir in host machine for monitoring results

# MPI programs
# This MPI programs use only 2**N MPI processes
P="is ep cg lu ft"
SIZES="S W A B C D"

MASTER="192.168.122.207"
CLUSTER="master-first slave-first-1 slave-first-2 slave-first-3 slave-first-4 slave-first-5 slave-first-6 slave-first-7 slave-first-8 slave-first-9 slave-first-10 slave-first-11 slave-first-12 slave-first-13 slave-first-14 slave-first-15"


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

pidfile() { (
    echo $BASHPID > "$1"
    shift
    exec "$@"
) }


read -ra PROGRAM <<< "$P"

# Run program in CLUSTER

N="${#PROGRAM[@]}"
for (( i = 0; i < N; i++ ))
do
    for size in $SIZES
    do
        PROG="${PROGRAM[$i]}"".""$size"".x"

        printf "Start group '$PROG' with size '$size'\n"
        for np in 1 2 4 8 16
        do
            monitor_nodes="$(get_nodes_str "$CLUSTER" $np "\|")"
            cluster_nodes="$(get_nodes_str "$CLUSTER" $np ",")"

            printf "RUN PROGRAM: ($PROG); NP: ($np); NODES: (%s); MONITOR: (%s) \n" "$cluster_nodes" "$monitor_nodes"

            # Start monitoring
            pidfile "/tmp/kvmtop.pid" sudo kvmtop -c qemu:///system --printer=text --cpu --net | pidfile "/tmp/grep.pid" grep -w "$monitor_nodes" &> $MON_RES_DIR/$PROG"_"$size"_"$np"_"mon.out &

            # Run MPI programs
            sshpass -p "mpiuser" ssh -o StrictHostKeyChecking=no -tT mpiuser@$MASTER "mpirun -np $np --hosts $cluster_nodes $PROG_DIR/$PROG &> $RESULT_DIR/$PROG\_$size\_$np.out"
           
            # Stop monitoring
            sudo kill -9 $(cat "/tmp/kvmtop.pid")
            sudo kill -9 $(cat "/tmp/grep.pid")

        done
        printf "\n"

    done
done


echo "Well done!!!"
