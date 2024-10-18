#!/bin/bash

master="master"
slave="slave"
user="hadoop"

remove_with_sed() {
        local file_remove_line="$1"
        sed -i '/<configuration>/,/<\/configuration>/d' "$file_remove_line"
}

create_backup_file() {
        local file_ori="$1"
        cp "$file_ori" "$file_ori.bak"
        echo "Backup do arquivo $file_ori criado como $file_ori.bak"
}

send_content_to_file() {
        local content="$1"
        local file="$2"
        echo "$content" >> "$file"
        echo "Linhas adicionadas ao $file com sucesso!"
}

#while true; do
#    read -p "Digite a característica do nó deste pc: Master/Slave: " feature
#    feature=${feature,,}

#    if [ "$feature" = "$master" ] || [ "$feature" = "$slave" ]; then
#        break
#    else
#        echo "Entrada inválida. Digite apenas $master ou $slave"
#    fi
#done

#if [ "$feature" = "$master" ]; then
#    mkdir -p "$HOME/hadoop/hdfs/namenode"
#    ssh-copy-id "$user"@"$master"
#elif [ "$feature" = "$slave" ]; then
#    mkdir -p "$HOME/hadoop/hdfs/datanode"
#fi


#read -p "Quantos slaves terá o cluster? obs: Digite apenas números: " qtd_slave

#while ! [[ "$qtd_slave"  =~ ^[0-9]+$ ]]; do
#    echo "Entrada inválida. Digite apenas números"
#    read -p "Quantos slaves terá o cluster? obs: Digite apenas números: " qtd_slave
#done

config=""
slaves=""
memory_ram=""

while [[ "$#" -gt 0 ]]; do
	case "$1" in
		--config) config="$2"; shift;;
		--slaves) slaves="$2"; shift;;
		--memory-ram) memory_ram="$2"; shift;;
		*) echo "Opção inválida: $1"; exit 1;;
	esac
	shift
done



if [ "$config" = "$master" ]; then
    mkdir -p "$HOME/hadoop/hdfs/namenode"
    ssh-copy-id "$user"@"$master"
elif [ "$config" = "$slave" ]; then
    mkdir -p "$HOME/hadoop/hdfs/datanode"
fi


path_files_hadoop="$HOME/hadoop/etc/hadoop"

# Caminho para o arquivo .bashrc
bash_rc_path="$HOME/.bashrc"

# Linhas a serem adicionadas ao .bashrc
lines_to_add=$(cat <<- EOM
# Configuração de variáveis de ambiente para o Hadoop
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export PATH=\$PATH:\$JAVA_HOME/bin
export HADOOP_HOME="/home/hadoop/hadoop"
export PATH="\$PATH:\${HADOOP_HOME}/bin"
export SPARK_HOME=/home/hadoop/spark
export PATH=\$PATH:\$SPARK_HOME/bin
export YARN_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
EOM
)

# Adicionar linhas ao .bashrc
send_content_to_file "$lines_to_add" "$bash_rc_path"


# Caminho para o arquivo hadoop-env.sh
hadoop_env_path="$path_files_hadoop/hadoop-env.sh"

# Linhas a serem adicionadas ao hadoop-env.sh
lines_to_add_in_hadoop_env_sh=$(cat <<- EOM
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export HADOOP_HOME=/home/hadoop/hadoop
export HADOOP_CONF_DIR="\$HADOOP_HOME/etc/hadoop"
export PATH="\${PATH}:\${HADOOP_HOME}/bin"
export HADOOP_SSH_OPTS="-i ~/.ssh/id_rsa"
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens=java.base/java.lang=ALL-UNNAMED"
EOM
)

# Adicionar linhas ao hadoop-env.sh
send_content_to_file "$lines_to_add_in_hadoop_env_sh" "$hadoop_env_path"

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
create_backup_file "$path_to_add_config_core_site_xml"

# Remove as linhas <configuration></configuration> do arquivo
remove_with_sed "$path_to_add_config_core_site_xml"

# Adiciona as configurações ao arquivo core-site.xml
send_content_to_file "$lines_to_add_in_hadoop_core_site_xml"  "$path_to_add_config_core_site_xml"

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
        <value>$slaves</value>
  </property>


</configuration>
EOM
)

# Faz o backup do arquivo hdfs-site.xml
create_backup_file "$path_to_add_config_hdfs_site_xml"

# Remove as linhas <configuration></configuration> do arquivo
remove_with_sed  "$path_to_add_config_hdfs_site_xml"

# Adiciona as configurações ao arquivo hdfs-site.xml
send_content_to_file "$lines_to_add_in_config_hdfs_site_xml" "$path_to_add_config_hdfs_site_xml"


# Caminho para o arquivo mapred-site.xml
# 
# remove_with_sed() {
# 	local file_remove_line="$1"
# 	sed -i '/<configuration>/,/<\/configuration>/d' "$file_remove_line"
# }
# 
# create_backup_file() {
# 	local file_ori="$1"
# 	cp "$file_ori" "$file_ori.bak"
# 	echo "Backup do arquivo $file_ori criado como $file_ori.bak"
# }
# 
# send_content_to_file() {
# 	local content="$1"
# 	local file="$2"
# 	echo "$content" >> "$file"
# 	echo "Linhas adicionadas ao $file com sucesso!"
# }
# 
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


remove_with_sed "$path_to_add_in_config_map_reduce_xml"

create_backup_file "$path_to_add_in_config_map_reduce_xml"

send_content_to_file "$lines_to_add_in_config_mapred_site_xml" "$path_to_add_in_config_map_reduce_xml"

# Faz o backup do arquivo mapred-site.xml
#cp "$path_to_add_in_config_map_reduce_xml" "$path_to_add_in_config_map_reduce_xml.bak"

# Remove as linhas <configuration></configuration> do arquivo
#sed -i '/<configuration>/,/<\/configuration>/d' "$path_to_add_in_config_map_reduce_xml"

# Adiciona as configurações ao arquivo mapred-site.xml
#echo "$lines_to_add_in_config_mapred_site_xml" >> "$path_to_add_in_config_map_reduce_xml"
#echo "Linhas adicionadas ao $path_to_add_in_config_map_reduce_xml com sucesso!"


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

#tot_memory=$(verification_isnumber "Total de memória disponível para containers em cada NodeManager? Valor em Megabytes: ") 

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
        <value>$memory_ram</value>
    </property>


</configuration>
EOM
)

# Remove as linhas <configuration></configuration> do arquivo
#sed -i '/<configuration>/,/<\/configuration>/d' "$path_to_add_in_config_yarn_site_xml"

# Faz o backup do arquivo yarn-site.xml
#cp "$path_to_add_in_config_yarn_site_xml" "$path_to_add_in_config_yarn_site_xml.bak"

# Adiciona as configurações ao arquivo yarn-site.xml
#echo "$line_to_add_in_config_yarn_site_xml" >> "$path_to_add_in_config_yarn_site_xml"
#echo "Linhas adicionadas ao $path_to_add_in_config_yarn_site_xml com sucesso!"

remove_with_sed "$path_to_add_in_config_yarn_site_xml"
 
create_backup_file "$path_to_add_in_config_yarn_site_xml"

send_content_to_file "$line_to_add_in_config_yarn_site_xml" "$path_to_add_in_config_yarn_site_xml" 

path_file_workers="/home/hadoop/hadoop/etc/hadoop/workers"
sed -i '/localhost/d' "$path_file_workers"

#user="hadoop"

while [[ "$slaves" -gt 0 ]]; do
    line_to_add_workers_file="slave$slaves"
    echo "$line_to_add_workers_file" >> "$path_file_workers"
    if [[ "$feature" = "$master" ]]; then
    	ssh-copy-id "$user"@"$line_to_add_workers_file"
    fi	
    slaves=$((slaves - 1)) 
done

#ssh-copy-id "$user"@"$master"

echo "Quantidade de slaves adicionado no arquivo \$HOME/hadoop/etc/hadoop/workers"

path_spark_conf_dir_default="/home/hadoop/spark/conf/spark-defaults.conf.template"
path_spark_new_conf_dir="/home/hadoop/spark/conf/spark-defaults.conf"

cp "$path_spark_conf_dir_default" "$path_spark_new_conf_dir"

lines_to_add_spark_new_conf_dir=$(cat <<- EOM
# Configurar o Spark para usar o YARN como gerenciador de recursos
spark.master                        yarn

# Configurar o modo de deploy em cluster (opcional, pode ser "client" ou "cluster")
spark.submit.deployMode              cluster

# Quantidade de memória para o ApplicationMaster (AM) no YARN
spark.yarn.am.memory                 1G

# Memória alocada para cada executor
spark.executor.memory                2G

# Número de núcleos de CPU para cada executor
spark.executor.cores                 2

# Número de executores (pode ajustar conforme o tamanho do cluster)
spark.executor.instances             4

# Memória alocada para o driver
spark.driver.memory                  1G

# Habilitar logs de eventos para monitoramento
spark.eventLog.enabled               true

# Diretório no HDFS onde os logs de eventos serão armazenados
spark.eventLog.dir                   hdfs:///spark-logs


# Configura a prioridade do job Spark no YARN (opcional)
spark.yarn.queue                     default
EOM
)

send_content_to_file "$lines_to_add_spark_new_conf_dir"  "$path_spark_new_conf_dir"

echo "Cluster hadoop configurado com sucesso!"

exec bash --login
