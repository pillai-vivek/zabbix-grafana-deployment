#!/bin/bash
cd /opt/zabbix-grafana-deployment || exit 1
git pull --quiet

bash ./deploy/deploy_zabbix.sh
bash ./deploy/deploy_grafana.sh
