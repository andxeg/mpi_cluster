Average delay between master and slaves

Launch ping from master to all slave, save results to file and then run command below:
$ grep "time=" out.txt | cut -d'=' -f4 | cut -d' ' -f1 | awk '{s+=$1; i+=1} END {print s/i; }'

