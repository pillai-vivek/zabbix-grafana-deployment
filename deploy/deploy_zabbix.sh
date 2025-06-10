#!/bin/bash

echo "🔁 Starting Zabbix external script and template deployment..."

# === Step 1: Copy externalscripts ===
echo "📦 Copying Zabbix external scripts..."
cp /opt/zabbix-grafana-deployment/zabbix/externalscripts/* /usr/lib/zabbix/externalscripts/ 2>/dev/null
chmod +x /usr/lib/zabbix/externalscripts/*

# === Step 2: Authenticate with Zabbix API ===
ZABBIX_URL="http://34.130.47.12/zabbix"
ZABBIX_USER="Admin"
ZABBIX_PASS="zabbix"

echo "🔐 Authenticating with Zabbix API..."
auth_token=$(curl -s -X POST -H 'Content-Type: application/json' \
-d '{
  "jsonrpc": "2.0", "method": "user.login",
  "params": { "user": "'"$ZABBIX_USER"'", "password": "'"$ZABBIX_PASS"'" },
  "id": 1
}' "$ZABBIX_URL/api_jsonrpc.php" | jq -r .result)

if [ -z "$auth_token" ] || [ "$auth_token" = "null" ]; then
  echo "❌ Authentication with Zabbix API failed."
  exit 1
fi

# === Step 3: Import templates ===
echo "📂 Searching for template files..."
TEMPLATE_DIR="/opt/zabbix-grafana-deployment/zabbix/templates"
shopt -s nullglob
template_files=("$TEMPLATE_DIR"/*)

if [ ${#template_files[@]} -eq 0 ]; then
  echo "⚠️ No template files found in $TEMPLATE_DIR."
  exit 0
fi

for TEMPLATE_FILE in "${template_files[@]}"; do
  echo "📄 Importing template: $TEMPLATE_FILE"

  template_format=$(basename "$TEMPLATE_FILE" | awk -F. '{print tolower($NF)}')
  
  # Escape for JSON
  template_data=$(sed 's/"/\\"/g' "$TEMPLATE_FILE" | awk '{printf "%s\\n", $0}')
  
  response=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc": "2.0", "method": "configuration.import",
    "params": {
      "rules": { "templates": { "createMissing": true, "updateExisting": true } },
      "source": "'"$template_data"'",
      "format": "'"$template_format"'"
    },
    "auth": "'"$auth_token"'",
    "id": 2
  }' "$ZABBIX_URL/api_jsonrpc.php")

  if echo "$response" | grep -q '"result"'; then
    echo "✅ Successfully imported: $(basename "$TEMPLATE_FILE")"
  else
    echo "❌ Failed to import: $(basename "$TEMPLATE_FILE")"
    echo "🔎 Response: $response"
  fi
done

echo "✅ Zabbix deployment script finished."
