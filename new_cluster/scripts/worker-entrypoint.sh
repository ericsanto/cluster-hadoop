#!/bin/bash

source functions.sh

source hadoop-env.sh

source cluster-config.sh

mkdir -p $HADOOP_HOME/hdfs/datanode

tail -f /dev/null