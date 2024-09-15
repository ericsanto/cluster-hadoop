#!/bin/bash

service ssh start

service mysql start

service grafana-server start

service ssh start

/usr/local/bin/script-database-zabbix.sh

/bin/bash
