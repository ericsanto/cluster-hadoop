#!/bin/bash

JAVA_HOME=$(detect_java_home)

cat <<EOF > "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"

export JAVA_HOME=$JAVA_HOME

export HADOOP_HOME=$HADOOP_HOME

export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

export PATH=\$PATH:\$HADOOP_HOME/bin

export HADOOP_SSH_OPTS="-i ~/.ssh/id_rsa"

export HDFS_NAMENODE_OPTS="$HDFS_NAMENODE_OPTS \
-javaagent:/opt/jmx/jmx_prometheus_javaagent.jar=9404:/opt/jmx/namenode.yml"

export HDFS_DATANODE_OPTS="$HDFS_DATANODE_OPTS \
-javaagent:/opt/jmx/jmx_prometheus_javaagent.jar=9406:/opt/jmx/datanode.yml"

EOF