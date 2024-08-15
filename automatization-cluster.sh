#!/bin/bash

master="master"
slave="slave"

while true; do
    read -p "Digite a característica do nó deste pc: Master/Slave" feature
    feature=${feature,,}

    if [ "$feature" = "$master" ] || [ "$feature" = "$slave" ]; then
        break
    else
        echo "Entrada inválida. Digite apenas $master ou $slave"
    fi
done

path_files_hadoop="$HOME/hadoop/etc/hadoop"

# Caminho para o arquivo .bashrc
bash_rc_path="$HOME/.bashrc"

# Linhas a serem adicionadas ao .bashrc
lines_to_add=$(cat <<- EOM
export JAVA_HOME=/usr/java/jdk-22-oracle-x64
export PATH=\$PATH:\$JAVA_HOME/bin
export HADOOP_HOME=\$HOME/hadoop
export PATH=\$PATH:\$HADOOP_HOME/bin
EOM
)

# Adicionar linhas ao .bashrc
echo "$lines_to_add" >> "$bash_rc_path"
echo "Linhas adicionadas ao $bash_rc_path com sucesso!"

# Aplicar mudanças no .bashrc (verifique se o comando funciona no seu terminal)
source "$bash_rc_path"

# Caminho para o arquivo hadoop-env.sh
hadoop_env_path="$path_files_hadoop/hadoop-env.sh"

# Linhas a serem adicionadas ao hadoop-env.sh
lines_to_add_in_hadoop_env_sh=$(cat <<- EOM
export JAVA_HOME=/usr/java/jdk-22-oracle-x64
export HADOOP_HOME=/home/hadoop/hadoop
export HADOOP_CONF_DIR="\$HADOOP_HOME/etc/hadoop"
export PATH="\${PATH}:\${HADOOP_HOME}/bin"
export HADOOP_SSH_OPTS="-i ~/.ssh/id_rsa"
EOM
)

# Adicionar linhas ao hadoop-env.sh
echo "$lines_to_add_in_hadoop_env_sh" >> "$hadoop_env_path"
echo "Linhas adicionadas ao $hadoop_env_path com sucesso!"

# Caminho para o arquivo core-site.xml
path_to_add_config_core_site_xml="$path_files_hadoop/core-site.xml"
lines_to_add_in_hadoop_core_site_xml=$(cat <<- EOM
<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://master:19000</value>
    </property>
</configuration>
EOM
)

# Faz o backup do arquivo core-site.xml
cp "$path_to_add_config_core_site_xml" "$path_to_add_config_core_site_xml.bak"

# Remove as linhas <configuration></configuration> do arquivo
sed -i '/<configuration>/,/<\/configuration>/d' "$path_to_add_config_core_site_xml"

# Adiciona as configurações ao arquivo core-site.xml
echo "$lines_to_add_in_hadoop_core_site_xml" >> "$path_to_add_config_core_site_xml"
echo "Linhas adicionadas ao $path_to_add_config_core_site_xml com sucesso!"

# Cria diretórios
mkdir -p "$HOME/hadoop/dfs/data"
mkdir -p "$HOME/hadoop/dfs/namespace_logs"

# Caminho para o arquivo hdfs-site.xml
path_to_add_config_hdfs_site_xml="$path_files_hadoop/hdfs-site.xml"
lines_to_add_in_config_hdfs_site_xml=$(cat <<- EOM
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>\$HOME/hadoop/dfs/namespace_logs</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>\$HOME/hadoop/dfs/data</value>
    </property>
</configuration>
EOM
)

# Faz o backup do arquivo hdfs-site.xml
cp "$path_to_add_config_hdfs_site_xml" "$path_to_add_config_hdfs_site_xml.bak"

# Remove as linhas <configuration></configuration> do arquivo
sed -i '/<configuration>/,/<\/configuration>/d' "$path_to_add_config_hdfs_site_xml"

# Adiciona as configurações ao arquivo hdfs-site.xml
echo "$lines_to_add_in_config_hdfs_site_xml" >> "$path_to_add_config_hdfs_site_xml"
echo "Linhas adicionadas ao $path_to_add_config_hdfs_site_xml com sucesso!"

# Caminho para o arquivo mapred-site.xml
path_to_add_in_config_map_reduce_xml="$path_files_hadoop/mapred-site.xml"
lines_to_add_in_config_mapred_site_xml=$(cat <<- EOM
<configuration>
    <property>
        <name>mapreduce.job.user.name</name>
        <value>hadoop</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>master:8032</value>
    </property>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=\$HOME/hadoop</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=\$HOME/hadoop</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=\$HOME/hadoop</value>
    </property>
</configuration>
EOM
)

# Faz o backup do arquivo mapred-site.xml
cp "$path_to_add_in_config_map_reduce_xml" "$path_to_add_in_config_map_reduce_xml.bak"

# Remove as linhas <configuration></configuration> do arquivo
sed -i '/<configuration>/,/<\/configuration>/d' "$path_to_add_in_config_map_reduce_xml"

# Adiciona as configurações ao arquivo mapred-site.xml
echo "$lines_to_add_in_config_mapred_site_xml" >> "$path_to_add_in_config_map_reduce_xml"
echo "Linhas adicionadas ao $path_to_add_in_config_map_reduce_xml com sucesso!"

# Caminho para o arquivo yarn-site.xml
path_to_add_in_config_yarn_site_xml="$path_files_hadoop/yarn-site.xml"
line_to_add_in_config_yarn_site_xml=$(cat <<- EOM
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>1536</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>1536</value>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>128</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.server.resourcemanager.application.expiry.interval</name>
        <value>60000</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>-1</value>
    </property>
    <property>
        <name>yarn.application.classpath</name>
        <value>\$HADOOP_CONF_DIR,\${HADOOP_COMMON_HOME}/share/hadoop/common/*,\${HADOOP_COMMON_HOME}/share/hadoop/common/lib/*,\${HADOOP_HDFS_HOME}/share/hadoop/hdfs/*,\${HADOOP_HDFS_HOME}/share/hadoop/hdfs/lib/*,\${HADOOP_MAPRED_HOME}/share/hadoop/mapreduce/*,\${HADOOP_MAPRED_HOME}/share/hadoop/mapreduce/lib/*,\${HADOOP_YARN_HOME}/share/hadoop/yarn/*,\${HADOOP_YARN_HOME}/share/hadoop/yarn/lib/*</value>
    </property>
</configuration>
EOM
)

# Remove as linhas <configuration></configuration> do arquivo
sed -i '/<configuration>/,/<\/configuration>/d' "$path_to_add_in_config_yarn_site_xml"

# Faz o backup do arquivo yarn-site.xml
cp "$path_to_add_in_config_yarn_site_xml" "$path_to_add_in_config_yarn_site_xml.bak"

# Adiciona as configurações ao arquivo yarn-site.xml
echo "$line_to_add_in_config_yarn_site_xml" >> "$path_to_add_in_config_yarn_site_xml"
echo "Linhas adicionadas ao $path_to_add_in_config_yarn_site_xml com sucesso!"

path_file_workers="/home/hadoop/hadoop/etc/hadoop/workers"

line_to_add_workers_file="slave"

if [ $feature = $master ]; then
    sed -i '/localhost/d' "$path_file_workers"
    echo "$line_to_add_workers_file" >> "$path_file_workers"
fi

echo "Configuração do Hadoop concluída com sucesso!"
