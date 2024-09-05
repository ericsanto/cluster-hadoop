#!/bin/bash

echo "BEM VINDO AO CLUSTER APACHE HADOOP"
echo "Aguarde 10 segundos. Estamos preparando o melhor ambiente para você :)"

sleep 10

path_file_locale="/etc/default/locale"

sudo locale-gen pt_BR.UTF-8
sudo update-locale LANG=pt_BR.UTF-8
echo "LANG=pt_BR.UTF-8"  | sudo tee "$path_file_locale"
echo "LANGUAGE=pt_BR:pt" | sudo tee "$path_file_locale"
echo "LC_ALL=pt_BR.UTF-8" | sudo tee "$path_file_locale"

MYSQL_PASSWORD_ROOT="default"
ZABBIX_DB="zabbix"
ZABBIX_USER="zabbix"
ZABBIX_PASSWORD="zabbix_password"
SQL_SCRIPT_PATH="/usr/share/zabbix-sql-scripts/mysql/server.sql.gz"

USER_HADOOP="hadoop"
GROUP_MYSQL="mysql"


sudo mysql -u root -p"$MYSQL_PASSWORD_ROOT" <<EOF
CREATE DATABASE $ZABBIX_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER '$ZABBIX_USER'@'localhost' IDENTIFIED BY '$ZABBIX_PASSWORD';
GRANT ALL PRIVILEGES ON $ZABBIX_DB.* TO '$ZABBIX_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

echo "Banco de dados e usuário zabbix configurado com sucesso!"

echo "Importando banco de dados. Por favor, espere um pouco..."
sudo zcat "$SQL_SCRIPT_PATH" | mysql --default-character-set=utf8mb4 -u"$ZABBIX_USER" -p"$ZABBIX_PASSWORD" "$ZABBIX_DB"

echo "Esquema SQL do Zabbix importado com sucesso!"

sudo mysql -u root -p"$MYSQL_PASSWORD_ROOT" <<EOF
set global log_bin_trust_function_creators = 0;
EOF

path_file_zabbix="/etc/zabbix/zabbix_server.conf"

#sudo sed -i '/DBPassword/d' "$path_file_zabbix"

#line_to_add_zabbix_conf=$(cat <<- EOM
#DBPassword=$ZABBIX_PASSWORD
#EOM
#)

sudo gpasswd -a "$USER_HADOOP" "$GROUP_MYSQL"
sudo chmod 777 /var/run/mysqld


#echo "$line_to_add_zabbix_conf" | sudo tee "$path_file_zabbix"

path_zabbix_agent_conf="/etc/zabbix/zabbix_agentd.conf"

#cp "$path_zabbix_agent_conf" "$path_zabbix_agent_conf.bak"

#sed -i '/^Server=/d' "$path_zabbix_agent_conf"
#sed -i '/^ServerActive=/d' "$path_zabbix_agent_conf"
#sed -i '/^Hostname=/d' "$path_zabbix_agent_conf"

hostname_format=$(echo $HOSTNAME | sed 's/[0-9]*//g')
hostname_compare="slave"
server="master"

if [[ "$hostname_format" = "$hostname_compare" ]]; then
	cp "$path_zabbix_agent_conf" "$path_zabbix_agent_conf.bak"
	sed -i '/^Server=/d' "$path_zabbix_agent_conf"
	sed -i '/^ServerActive=/d' "$path_zabbix_agent_conf"
	sed -i '/^Hostname=/d' "$path_zabbix_agent_conf"
	echo "Server=$server" | sudo tee -a "$path_zabbix_agent_conf"
	echo "ServerActive=$server" | sudo tee -a "$path_zabbix_agent_conf"
	echo "Hostname=$HOSTNAME" | sudo tee -a "$path_zabbix_agent_conf"
	sudo service zabbix-agent start
	echo "Arquivo /etc/zabbix/zabbix-agentd.conf configurado com sucesso"
fi

if [[ "$hostname_format" = "$server" ]]; then
	sudo sed -i '/DBPassword/d' "$path_file_zabbix"

	line_to_add_zabbix_conf=$(cat <<- EOM
	DBPassword=$ZABBIX_PASSWORD
	EOM
	)
	
	echo "$line_to_add_zabbix_conf" | sudo tee "$path_file_zabbix"

	sudo service zabbix-server start
	sudo service apache2 start
      	echo "Servidor Zabbix está pronto para uso. Acesse: localhost/zabbix"

fi

#echo "Servidor Zabbix está pronto para uso. Acesse: localhost/zabbix"

#Faz o balanceamento entre hdfs dos datanodes
#hdfs balancer –threshold 5
