#!/bin/bash

source functions.sh

MASTER_HOST=${MASTER_HOST:-master}

MEMORY=${MEMORY:-2048}

REPLICATION=${REPLICATION:-1}

core=$(cat <<EOF
<configuration>

    <property>

        <name>fs.defaultFS</name>

        <value>hdfs://${MASTER_HOST}:9000</value>

    </property>

</configuration>
EOF
)

write_xml \
"$HADOOP_HOME/etc/hadoop/core-site.xml" \
"$core"


hdfs=$(cat <<EOF
<configuration>

    <property>

        <name>dfs.namenode.name.dir</name>

        <value>$HOME/hdfs/namenode</value>

    </property>

    <property>

        <name>dfs.datanode.data.dir</name>

        <value>$HOME/hdfs/datanode</value>

    </property>

    <property>

        <name>dfs.replication</name>

        <value>${REPLICATION}</value>

    </property>

</configuration>
EOF
)

write_xml \
"$HADOOP_HOME/etc/hadoop/hdfs-site.xml" \
"$hdfs"


yarn=$(cat <<EOF
<configuration>

    <property>

        <name>yarn.resourcemanager.hostname</name>

        <value>${MASTER_HOST}</value>

    </property>

      <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>

    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>2</value>
    </property>

    <property>

        <name>yarn.nodemanager.resource.memory-mb</name>

        <value>${MEMORY}</value>

    </property>

</configuration>
EOF
)

write_xml \
"$HADOOP_HOME/etc/hadoop/yarn-site.xml" \
"$yarn"

cat workers.txt >> "$HADOOP_HOME/etc/hadoop/workers"

mapred=$(cat <<- EOM
<configuration>

    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value>
    </property>

    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value>
    </property>

    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value>
    </property>

</configuration>
EOM
)


write_xml \
"$HADOOP_HOME/etc/hadoop/mapred-site.xml" \
"$mapred"