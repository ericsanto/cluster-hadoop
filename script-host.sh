#!/bin/bash

service ssh start

service mysql start

script-database-zabbix.sh

/bin/bash
