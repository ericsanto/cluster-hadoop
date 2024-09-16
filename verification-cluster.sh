#!/bin/bash

test_pi_command="hadoop jar hadoop-mapreduce-examples-3.4.0.jar pi 1 1"

while true; do
	"$test_pi_command"
	if [[ "$?" -eq 255 ]]; then
		$HADOOP_HOME/sbin/stop-all.sh
		sleep 5
		$HADOOP_HOME/sbin/start-all.sh
	fi
	sleep 30
done
