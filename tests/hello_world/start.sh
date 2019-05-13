#!/bin/bash

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
    printf "Error in input parametes\n"
    printf "Type %s <execution mode ::= single | cluster> <hosts in cluster>\n" $0
    exit
fi

make clean && make

MODE=$1
HOSTS=$2

printf "mode = %s, hosts = %s\n" $MODE $HOSTS

if [ $MODE == "single" ]; then
    printf "\nRun mpi_hello_world in single mode:\n"
    mpirun -np 5 ./mpi_hello_world

elif [ $MODE == "cluster" ]; then
    if [ "$HOSTS" == "" ]; then
        printf "Error! Hosts in cluster are not unspecified \n"
        exit
    fi

    printf "\nRun mpi_hello_world in cluster mode\n"
    mpirun -np 5 -hosts "$HOSTS" ./mpi_hello_world

else
    printf "\nUnknown execution mode: %s\n" $MODE
fi

