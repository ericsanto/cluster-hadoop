#!/bin/bash

source functions.sh

source hadoop-env.sh

source cluster-config.sh

source yarn-env.sh


mkdir -p $HOME/hdfs/namenode

if [ ! -d $HOME/hdfs/namenode/current ]; then

    hdfs namenode -format
fi

echo "Iniciando NameNode..."
hdfs --daemon start namenode

echo "Iniciando ResourceManager..."
yarn --daemon start resourcemanager

tail -f /dev/null