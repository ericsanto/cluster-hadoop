#!/bin/bash

source functions.sh

source hadoop-env.sh

source cluster-config.sh

source yar-env.sh

mkdir -p $HADOOP_HOME/hdfs/datanode

tail -f /dev/null