#!/bin/bash

# Interrompe o script imediatamente se qualquer comando falhar
set -e

echo "BEM VINDO AO CLUSTER APACHE HADOOP"
echo "Aguarde 10 segundos. Estamos preparando o melhor ambiente para você :)"

sleep 10

path_file_locale="/etc/default/locale"

sudo locale-gen pt_BR.UTF-8
sudo update-locale LANG=pt_BR.UTF-8
echo "LANG=pt_BR.UTF-8" | sudo tee "$path_file_locale"
echo "LANGUAGE=pt_BR:pt" | sudo tee "$path_file_locale"
echo "LC_ALL=pt_BR.UTF-8" | sudo tee "$path_file_locale"

# Variáveis do Zabbix (A senha do root não é mais necessária no script)
ZABBIX_DB="zabbix"
ZABBIX_USER="zabbix"
ZABBIX_PASSWORD="zabbix_password"
SQL_SCRIPT_PATH="/usr/share/zabbix-sql-scripts/mysql/server.sql.gz"

USER_HADOOP="hadoop"
GROUP_MYSQL="mysql"

# Configuração do Banco via ROOT (Usando autenticação nativa por socket - Sem senha exposta)
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $ZABBIX_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '$ZABBIX_USER'@'localhost' IDENTIFIED BY '$ZABBIX_PASSWORD';
GRANT ALL PRIVILEGES ON $ZABBIX_DB.* TO '$ZABBIX_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

echo "Banco de dados e usuário zabbix configurados com sucesso!"

# Verifica se o arquivo de esquema do Zabbix realmente existe antes de importar
if [ -f "$SQL_SCRIPT_PATH" ]; then
    echo "Importando banco de dados. Por favor, espere um pouco..."
    sudo zcat "$SQL_SCRIPT_PATH" | mysql --default-character-set=utf8mb4 -u"$ZABBIX_USER" -p"$ZABBIX_PASSWORD" "$ZABBIX_DB"
    echo "Esquema SQL do Zabbix importado com sucesso!"
else
    echo "AVISO: Arquivo de esquema do Zabbix não encontrado em $SQL_SCRIPT_PATH. Pulando importação."
fi

# Restaura a configuração de segurança global do MariaDB
sudo mysql <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF

path_file_zabbix="/etc/zabbix/zabbix_server.conf"

sudo gpasswd -a "$USER_HADOOP" "$GROUP_MYSQL"
sudo chmod 777 /var/run/mysqld

path_zabbix_agent_conf="/etc/zabbix/zabbix_agent2.conf"

hostname_format=$(echo "$HOSTNAME" | sed 's/[0-9]//g')
hostname_compare="slave"
server="master"

if [[ "$hostname_format" = "$hostname_compare" ]]; then
    sudo cp "$path_zabbix_agent_conf" "$path_zabbix_agent_conf.bak"
    sudo sed -i '/^Server=/d' "$path_zabbix_agent_conf"
    sudo sed -i '/^ServerActive=/d' "$path_zabbix_agent_conf"
    sudo sed -i '/^Hostname=/d' "$path_zabbix_agent_conf"
    echo "Server=$server" | sudo tee -a "$path_zabbix_agent_conf"
    echo "ServerActive=$server" | sudo tee -a "$path_zabbix_agent_conf"
    echo "Hostname=$HOSTNAME" | sudo tee -a "$path_zabbix_agent_conf"
    sudo service zabbix-agent2 start
    echo "Arquivo /etc/zabbix/zabbix-agentd.conf configurado com sucesso"
fi

if [[ "$hostname_format" = "$server" ]]; then
    sudo sed -i '/DBPassword/d' "$path_file_zabbix"

    line_to_add_zabbix_conf=$(cat <<- EOM
DBPassword=$ZABBIX_PASSWORD
EOM
)

    echo "$line_to_add_zabbix_conf" | sudo tee -a "$path_file_zabbix"

    sudo service zabbix-server start
    sudo service apache2 start
    echo "Servidor Zabbix está pronto para uso. Acesse: localhost/zabbix"
fi