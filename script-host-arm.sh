#!/bin/bash

service ssh start

service grafana-server start

/usr/local/bin/script-zabbix-arm.sh

/bin/bash
