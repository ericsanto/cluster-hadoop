#!/bin/bash

source /scripts/functions.sh

source /scripts/hadoop-env.sh

source /scripts/cluster-config.sh

mkdir -p ~/hdfs/datanode

hdfs --daemon start datanode

yarn --daemon start nodemanager

tail -f /dev/null