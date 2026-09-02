#!/usr/bin/env bash
set -euo pipefail

# Configure Grafana alert rules and contact points via HTTP API.
# Usage: ./configure-grafana-alerts.sh [GRAFANA_URL] [GRAFANA_PASSWORD]

GRAFANA_URL="${1:-http://localhost}"
GRAFANA_PASSWORD="${2:-}"

if [ -z "$GRAFANA_PASSWORD" ]; then
  echo "Usage: $0 <GRAFANA_URL> <GRAFANA_ADMIN_PASSWORD>"
  exit 1
fi

AUTH="admin:${GRAFANA_PASSWORD}"

echo "=== Configuring Grafana Alerting ==="

# --- 1. Create contact point (webhook to runbook-controller) ---
echo "Creating webhook contact point..."
curl -sf -X POST "${GRAFANA_URL}/api/v1/provisioning/contact-points" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -H "X-Disable-Provenance: true" \
  -d '{
    "name": "runbook-webhook",
    "type": "webhook",
    "settings": {
      "url": "http://runbook-controller.alerting.svc.cluster.local:8081/webhook",
      "httpMethod": "POST"
    }
  }' && echo " -> OK" || echo " -> Already exists or failed, continuing..."

# --- 2. Set notification policy to use the webhook contact point ---
echo "Updating notification policy..."
curl -sf -X PUT "${GRAFANA_URL}/api/v1/provisioning/policies" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -H "X-Disable-Provenance: true" \
  -d '{
    "receiver": "runbook-webhook",
    "group_by": ["grafana_folder", "alertname"],
    "group_wait": "10s",
    "group_interval": "1m",
    "repeat_interval": "4h"
  }' && echo " -> OK"

# --- 3. Create or find the folder for alert rules ---
echo "Creating alert folder..."
FOLDER_UID=$(curl -sf -X POST "${GRAFANA_URL}/api/folders" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -d '{"uid": "alerting-folder", "title": "Alerting"}' 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('uid',''))" 2>/dev/null || true)

if [ -z "$FOLDER_UID" ]; then
  FOLDER_UID="alerting-folder"
  echo " -> Using existing folder UID: $FOLDER_UID"
else
  echo " -> Created folder UID: $FOLDER_UID"
fi

# --- 4. Create alert rule ---
echo "Creating alert rule..."

# Get the Prometheus datasource UID
PROM_UID=$(curl -sf "${GRAFANA_URL}/api/datasources/name/Prometheus" \
  -u "$AUTH" | python3 -c "import sys,json; print(json.load(sys.stdin)['uid'])")
echo "  Prometheus datasource UID: $PROM_UID"

curl -sf -X POST "${GRAFANA_URL}/api/v1/provisioning/alert-rules" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -H "X-Disable-Provenance: true" \
  -d "$(cat <<EOF
{
  "uid": "canary-restart-alert",
  "orgID": 1,
  "folderUID": "${FOLDER_UID}",
  "ruleGroup": "canary-alerts",
  "title": "Canary Pod High Restart Count",
  "condition": "C",
  "noDataState": "NoData",
  "execErrState": "Error",
  "for": "30s",
  "data": [
    {
      "refId": "A",
      "relativeTimeRange": {"from": 300, "to": 0},
      "datasourceUid": "${PROM_UID}",
      "model": {
        "expr": "increase(kube_pod_container_status_restarts_total{namespace=\"alerting\", container=\"canary\"}[5m])",
        "instant": false,
        "range": true,
        "refId": "A"
      }
    },
    {
      "refId": "B",
      "relativeTimeRange": {"from": 300, "to": 0},
      "datasourceUid": "__expr__",
      "model": {
        "type": "reduce",
        "expression": "A",
        "reducer": "last",
        "refId": "B"
      }
    },
    {
      "refId": "C",
      "relativeTimeRange": {"from": 300, "to": 0},
      "datasourceUid": "__expr__",
      "model": {
        "type": "threshold",
        "expression": "B",
        "conditions": [
          {
            "evaluator": {
              "type": "gt",
              "params": [1]
            }
          }
        ],
        "refId": "C"
      }
    }
  ],
  "labels": {"severity": "warning"},
  "annotations": {
    "summary": "Canary pod is restarting frequently",
    "description": "The canary pod in the alerting namespace has restarted more than once in the last 5 minutes."
  }
}
EOF
)" && echo " -> OK"

echo ""
echo "=== Grafana Alerting Configured ==="
echo "Check: ${GRAFANA_URL}/alerting/list"
