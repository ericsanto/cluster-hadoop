#!/bin/bash

master="master"
slave="slave"

while true; do
    read -p "Digite a característica do nó deste pc: Master/Slave: " feature
    feature=${feature,,}

    if [ "$feature" = "$master" ] || [ "$feature" = "$slave" ]; then
        break
    else
        echo "Entrada inválida. Digite apenas $master ou $slave"
    fi
done

if [ "$feature" = "$master" ]; then
    mkdir -p "$HOME/hadoop/hdfs/namenode"
elif [ "$feature" = "$slave" ]; then
    mkdir -p "$HOME/hadoop/hdfs/datanode"
fi


read -p "Quantos slaves terá o cluster? obs: Digite apenas números: " qtd_slave

while ! [[ "$qtd_slave"  =~ ^[0-9]+$ ]]; do
    echo "Entrada inválida. Digite apenas números"
    read -p "Quantos slaves terá o cluster? obs: Digite apenas números: " qtd_slave
done

path_files_hadoop="$HOME/hadoop/etc/hadoop"

# Caminho para o arquivo .bashrc
bash_rc_path="$HOME/.bashrc"

# Linhas a serem adicionadas ao .bashrc
lines_to_add=$(cat <<- EOM
# Configuração de variáveis de ambiente para o Hadoop
export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
export PATH=\$PATH:\$JAVA_HOME/bin
export HADOOP_HOME="/home/hadoop/hadoop"
export PATH="\$PATH:\${HADOOP_HOME}/bin"
EOM
)

# Adicionar linhas ao .bashrc
echo "$lines_to_add" >> "$bash_rc_path"
echo "Linhas adicionadas ao $bash_rc_path com sucesso!"


# Caminho para o arquivo hadoop-env.sh
hadoop_env_path="$path_files_hadoop/hadoop-env.sh"

# Linhas a serem adicionadas ao hadoop-env.sh
lines_to_add_in_hadoop_env_sh=$(cat <<- EOM
export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
export HADOOP_HOME=/home/hadoop/hadoop
export HADOOP_CONF_DIR="\$HADOOP_HOME/etc/hadoop"
export PATH="\${PATH}:\${HADOOP_HOME}/bin"
export HADOOP_SSH_OPTS="-i ~/.ssh/id_rsa"
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens=java.base/java.lang=ALL-UNNAMED"
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

        <name>fs.defaultFS</name>

        <value>hdfs://master:9000</value>

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

#garante que haja uma réplica do dado em cada nó slave, além de uma cópia adicional
#(geralmente no nó master), totalizando qtd_slave + 1 réplicas.
dfs_replication=$((qtd_slave + 1))

# Caminho para o arquivo hdfs-site.xml
path_to_add_config_hdfs_site_xml="$path_files_hadoop/hdfs-site.xml"
lines_to_add_in_config_hdfs_site_xml=$(cat <<- EOM
<configuration>

    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/home/hadoop/hadoop/hdfs/namenode</value>
    </property>

    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/home/hadoop/hadoop/hdfs/datanode</value>
  </property>

  <property>
        <name>dfs.replication</name>
        <value>$qtd_slave</value>
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

# Faz o backup do arquivo mapred-site.xml
cp "$path_to_add_in_config_map_reduce_xml" "$path_to_add_in_config_map_reduce_xml.bak"

# Remove as linhas <configuration></configuration> do arquivo
sed -i '/<configuration>/,/<\/configuration>/d' "$path_to_add_in_config_map_reduce_xml"

# Adiciona as configurações ao arquivo mapred-site.xml
echo "$lines_to_add_in_config_mapred_site_xml" >> "$path_to_add_in_config_map_reduce_xml"
echo "Linhas adicionadas ao $path_to_add_in_config_map_reduce_xml com sucesso!"


verification_isnumber() {
    local input
    while true; do
       read -p "$1" input
        if [[ "$input" =~ ^[0-9]+$ ]]; then
            echo "$input"
            return 0
        
        else
            echo "Entrada inválida. Digite apenas números"
        fi
    done
}

tot_memory=$(verification_isnumber "Total de memória disponível para containers em cada NodeManager? Valor em Megabytes: ") 

# Caminho para o arquivo yarn-site.xml
path_to_add_in_config_yarn_site_xml="$path_files_hadoop/yarn-site.xml"
line_to_add_in_config_yarn_site_xml=$(cat <<- EOM
<configuration>

    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
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
        <value>$tot_memory</value>
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
sed -i '/localhost/d' "$path_file_workers"

user="hadoop"

while [[ "$qtd_slave" -gt 0 ]]; do
    line_to_add_workers_file="slave$qtd_slave"
    echo "$line_to_add_workers_file" >> "$path_file_workers"
    if [[ "$feature" = "$master" ]]; then
    	ssh-copy-id "$user"@"$line_to_add_workers_file"
    fi	
    qtd_slave=$((qtd_slave - 1)) 
done

echo "Quantidade de slaves adicionado no arquivo \$HOME/hadoop/etc/hadoop/workers"

echo "Cluster hadoop configurado com sucesso!"

exec bash --login
