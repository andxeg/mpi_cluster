#!/bin/bash

# This script run programs for each size with 1, 2, 4, 16 nodes in cluster

P="is ep cg lu ft"
SIZES="A B C D"
SUFFIX="-first" # suffix in cluster node names

PROG_DIR="/home/mpiuser/cloud/experiments/NPB3.4/NPB3.4-MPI/bin"
RESULTS_DIR="/home/mpiuser/cloud/experiments/results"

read -ra PROGRAM <<< "$P"

N="${#PROGRAM[@]}"
for (( i = 0; i < N; i++ ))
do
    for size in $SIZES
    do
        program="${PROGRAM[$i]}"

        echo "RUN '$program' with size '$size'"

        echo "mpirun -np 1 --hosts master"$SUFFIX" "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_1.out""
        mpirun -np 1 --hosts master"$SUFFIX" "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_1.out"

        echo "mpirun -np 4 --hosts master"$SUFFIX",slave"$SUFFIX"-1,slave"$SUFFIX"-2,slave"$SUFFIX"-3 "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_4.out""
        mpirun -np 4 --hosts master"$SUFFIX",slave"$SUFFIX"-1,slave"$SUFFIX"-2,slave"$SUFFIX"-3 "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_4.out"

        echo "mpirun -np 8 --hosts master"$SUFFIX",slave"$SUFFIX"-1,slave"$SUFFIX"-2,slave"$SUFFIX"-3,slave"$SUFFIX"-4,slave"$SUFFIX"-5,slave"$SUFFIX"-6,slave"$SUFFIX"-7 "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_8.out""
        mpirun -np 8 --hosts master"$SUFFIX",slave"$SUFFIX"-1,slave"$SUFFIX"-2,slave"$SUFFIX"-3,slave"$SUFFIX"-4,slave"$SUFFIX"-5,slave"$SUFFIX"-6,slave"$SUFFIX"-7 "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_8.out"

        echo "mpirun -np 16 --hosts master"$SUFFIX",slave"$SUFFIX"-1,slave"$SUFFIX"-2,slave"$SUFFIX"-3,slave"$SUFFIX"-4,slave"$SUFFIX"-5,slave"$SUFFIX"-6,slave"$SUFFIX"-7,slave"$SUFFIX"-8,slave"$SUFFIX"-9,slave"$SUFFIX"-10,slave"$SUFFIX"-11,slave"$SUFFIX"-12,slave"$SUFFIX"-13,slave"$SUFFIX"-14,slave"$SUFFIX"-15 "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_16.out""
        mpirun -np 16 --hosts master"$SUFFIX",slave"$SUFFIX"-1,slave"$SUFFIX"-2,slave"$SUFFIX"-3,slave"$SUFFIX"-4,slave"$SUFFIX"-5,slave"$SUFFIX"-6,slave"$SUFFIX"-7,slave"$SUFFIX"-8,slave"$SUFFIX"-9,slave"$SUFFIX"-10,slave"$SUFFIX"-11,slave"$SUFFIX"-12,slave"$SUFFIX"-13,slave"$SUFFIX"-14,slave"$SUFFIX"-15 "$PROG_DIR"/"$program"."$size".x &> "$RESULTS_DIR"/"$program""_""$size""_np_16.out"

    done

    echo "------------------------------"
done

