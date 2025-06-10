#!/bin/bash

echo "Deploying Grafana dashboards..."
GRAFANA_URL="http://localhost:3000"
GRAFANA_API_KEY="Bearer <your_api_key>"

for file in /opt/zabbix-grafana-deployment/grafana/dashboards/*.json; do
  dash_name=$(jq -r '.title' "$file")
  echo "Uploading: $dash_name"

  curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Authorization: $GRAFANA_API_KEY" \
    -H "Content-Type: application/json" \
    -d @<(jq -n --argjson dash "$(cat "$file")" \
                '{dashboard: $dash, overwrite: true, folderId: 0}')
done
