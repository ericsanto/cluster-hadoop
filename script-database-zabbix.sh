#!/bin/bash

MYSQL_PASSWORD_ROOT="default"
ZABBIX_DB="zabbix"
ZABBIX_USER="zabbix"
ZABBIX_PASSWORD="zabbix_password"
SQL_SCRIPT_PATH="/usr/share/zabbix-sql-scripts/mysql/server.sql.gz"

mysql -u root -p"$MYSQL_PASSWORD_ROOT" <<EOF
CREATE DATABASE $ZABBIX_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER '$ZABBIX_USER'@'localhost' IDENTIFIED BY '$ZABBIX_PASSWORD';
GRANT ALL PRIVILEGES ON $ZABBIX_DB.* TO '$ZABBIX_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

echo "Banco de dados e usuário zabbix configurado com sucesso!"

zcat "$SQL_SCRIPT_PATH" | mysql --default-character-set=utf8mb4 -u"$ZABBIX_USER" -p"$ZABBIX_PASSWORD" "$ZABBIX_DB"

echo "Esquema SQL do Zabbix importado com sucesso!"

mysql -u root -p"$MYSQL_PASSWORD_ROOT" <<EOF
set global log_bin_trust_function_creators = 0;
EOF

path_file_zabbix="/etc/zabbix/zabbix_server.conf"

sed -i '/DBPassword/d' "$path_file_zabbix"

line_to_add_zabbix_conf=$(cat <<- EOM
DBPassword=zabbix_password
EOM
)

echo "$line_to_add_zabbix_conf" >> "$path_file_zabbix"

