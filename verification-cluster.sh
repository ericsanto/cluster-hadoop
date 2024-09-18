#!/bin/bash

path_mapreduce="$HADOOP_HOME/share/hadoop/mapreduce"

test_pi_command="hadoop jar hadoop-mapreduce-examples-3.4.0.jar pi 1 1"



while true; do
	cd "$path_mapreduce"
	$test_pi_command
	if [[ "$?" -ne 0 ]]; then
		echo "comando executado $(date). Tipo de falha $($?)" >> "$HADOOP_HOME/logs-cluster.txt"
		$HADOOP_HOME/sbin/stop-all.sh
		sleep 5
		$HADOOP_HOME/sbin/start-all.sh
		sleep 5
	fi
	sleep 300
done
