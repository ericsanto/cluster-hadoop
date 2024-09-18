#!/bin/bash

path_file_workers="$HADOOP_HOME/etc/hadoop/workers"
stop_hadoop_cluster="$HADOOP_HOME/sbin/stop-all.sh"
start_hadoop_cluster="$HADOOP_HOME/sbin/start-all.sh"

while IFS= read linha; do
	sleep 200
	status_code=$(curl -o /dev/null -s -w "%{http_code}" "$linha:8042")
        echo $linha	
	if [[ "$status_code" != 200 ]]; then
		$stop_hadoop_cluster
		sleep 5
		$start_hadoop_cluster
	fi
done < "$path_file_workers"
		
		
