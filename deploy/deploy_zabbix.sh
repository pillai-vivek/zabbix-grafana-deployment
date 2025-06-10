#!/bin/bash

echo "Deploying Zabbix external scripts..."
cp /opt/zabbix-grafana-deployment/zabbix/externalscripts/* /usr/lib/zabbix/externalscripts/
chmod +x /usr/lib/zabbix/externalscripts/*

echo "Importing Zabbix template..."
ZABBIX_URL="http://localhost/zabbix"
ZABBIX_USER="Admin"
ZABBIX_PASS="zabbix"

auth_token=$(curl -s -X POST -H 'Content-Type: application/json' \
-d '{
  "jsonrpc": "2.0", "method": "user.login",
  "params": { "user": "'"$ZABBIX_USER"'", "password": "'"$ZABBIX_PASS"'" },
  "id": 1
}' "$ZABBIX_URL/api_jsonrpc.php" | jq -r .result)

template_data=$(< /opt/zabbix-grafana-deployment/zabbix/templates/template.yaml)

curl -s -X POST -H 'Content-Type: application/json' \
-d '{
  "jsonrpc": "2.0", "method": "configuration.import",
  "params": {
    "rules": { "templates": { "createMissing": true, "updateExisting": true } },
    "source": "'"$template_data"'",
    "format": "yaml"
  },
  "auth": "'"$auth_token"'",
  "id": 2
}' "$ZABBIX_URL/api_jsonrpc.php"
