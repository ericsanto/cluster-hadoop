#!/bin/bash

service ssh start

service mysql start

service grafana-server start

service ssh start

script-database-zabbix.sh

/bin/bash
