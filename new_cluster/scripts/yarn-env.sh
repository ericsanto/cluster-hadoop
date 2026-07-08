#!/bin/bash


cat <<EOF > "$HADOOP_HOME/etc/hadoop/yarn-env.sh"

export YARN_RESOURCEMANAGER_OPTS="$YARN_RESOURCEMANAGER_OPTS \
-javaagent:/opt/jmx/jmx_prometheus_javaagent-1.6.0.jar=9405:/opt/jmx/resourcemanager.yml"

export YARN_NODEMANAGER_OPTS="$YARN_NODEMANAGER_OPTS \
-javaagent:/opt/jmx/jmx_prometheus_javaagent-1.6.0.jar=9407:/opt/jmx/nodemanager.yml"


EOF