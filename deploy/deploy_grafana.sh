#!/bin/bash

# === Configuration ===
GRAFANA_URL="http://34.130.47.12:3000"
GRAFANA_API_KEY="your_grafana_api_key_here"  
DASHBOARD_DIR="/opt/zabbix-grafana-deployment/grafana"

# === Start Deployment ===
echo "Starting Grafana dashboard deployment from $DASHBOARD_DIR..."

if [ ! -d "$DASHBOARD_DIR" ]; then
  echo "Dashboard directory not found: $DASHBOARD_DIR"
  exit 1
fi

shopt -s nullglob
dashboard_files=("$DASHBOARD_DIR"/*.json)

if [ ${#dashboard_files[@]} -eq 0 ]; then
  echo "No dashboard JSON files found in $DASHBOARD_DIR"
  exit 0
fi

for DASHBOARD_FILE in "${dashboard_files[@]}"; do
  echo "📄 Importing dashboard: $DASHBOARD_FILE"

  # Read dashboard content
  dashboard_json=$(cat "$DASHBOARD_FILE")

  # Extract UID from the JSON (if it exists)
  uid=$(jq -r '.uid' "$DASHBOARD_FILE")
  if [ "$uid" = "null" ]; then
    echo "Dashboard UID missing in file. Skipping: $DASHBOARD_FILE"
    continue
  fi

  # Prepare import payload
  payload=$(jq -n \
    --argjson dashboard "$dashboard_json" \
    --arg folderId "0" \
    --arg overwrite "true" \
    '{dashboard: $dashboard, folderId: ($folderId | tonumber), overwrite: ($overwrite | test("true"))}')

  # Import via API
  response=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $GRAFANA_API_KEY" \
    -d "$payload")

  if echo "$response" | grep -q '"status":"success"'; then
    echo "Successfully imported: $(basename "$DASHBOARD_FILE")"
  else
    echo "Failed to import: $(basename "$DASHBOARD_FILE")"
    echo "🔎 Response: $response"
  fi
done

echo "✅ Grafana dashboard deployment finished."
