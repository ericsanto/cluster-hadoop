#!/bin/bash

source functions.sh

source hadoop-env.sh

source cluster-config.sh

source yarn-env.sh

mkdir -p $HADOOP_HOME/hdfs/datanode

start-dfs.sh

start-yarn.sh

tail -f /dev/null