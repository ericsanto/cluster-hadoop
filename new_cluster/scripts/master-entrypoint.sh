#!/bin/bash

source /scripts/functions.sh

source /scripts/hadoop-env.sh

source /scripts/cluster-config.sh

mkdir -p ~/hdfs/namenode

if [ ! -d ~/hdfs/namenode/current ]; then

    hdfs namenode -format

fi

start-dfs.sh

start-yarn.sh

tail -f /dev/null