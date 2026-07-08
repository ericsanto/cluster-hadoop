#!/bin/bash

source functions.sh

source hadoop-env.sh

source cluster-config.sh

source yarn-env.sh

source config-ssh.sh

mkdir -p $HOME/hdfs/namenode

if [ ! -d $HOME/hdfs/namenode/current ]; then

    hdfs namenode -format
fi


# service ssh start

# start-dfs.sh

start-yarn.sh

tail -f /dev/null