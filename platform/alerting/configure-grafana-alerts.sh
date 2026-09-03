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

# --- 4. Get the Prometheus datasource UID ---
PROM_UID=$(curl -sf "${GRAFANA_URL}/api/datasources/name/Prometheus" \
  -u "$AUTH" | python3 -c "import sys,json; print(json.load(sys.stdin)['uid'])")
echo "  Prometheus datasource UID: $PROM_UID"

# --- 5. Create candidate-api error rate alert rule ---
echo "Creating candidate-api error rate alert rule..."
curl -sf -X POST "${GRAFANA_URL}/api/v1/provisioning/alert-rules" \
  -u "$AUTH" \
  -H "Content-Type: application/json" \
  -H "X-Disable-Provenance: true" \
  -d "$(cat <<EOF
{
  "uid": "candidate-api-error-alert",
  "orgID": 1,
  "folderUID": "${FOLDER_UID}",
  "ruleGroup": "candidate-api-alerts",
  "title": "CandidateApi High Error Rate",
  "condition": "C",
  "noDataState": "OK",
  "execErrState": "Error",
  "for": "2m",
  "data": [
    {
      "refId": "A",
      "relativeTimeRange": {"from": 600, "to": 0},
      "datasourceUid": "${PROM_UID}",
      "model": {
        "expr": "candidate_api:availability:ratio5m",
        "instant": true,
        "range": false,
        "refId": "A"
      }
    },
    {
      "refId": "B",
      "relativeTimeRange": {"from": 600, "to": 0},
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
      "relativeTimeRange": {"from": 600, "to": 0},
      "datasourceUid": "__expr__",
      "model": {
        "type": "threshold",
        "expression": "B",
        "conditions": [
          {
            "evaluator": {
              "type": "lt",
              "params": [0.999]
            }
          }
        ],
        "refId": "C"
      }
    }
  ],
  "labels": {"severity": "critical"},
  "annotations": {
    "summary": "candidate-api availability has dropped below 99.9%",
    "description": "The candidate-api is returning 5xx errors. Availability SLO is being violated. Automated rollback is available via approval link.",
    "runbook_url": "http://13.216.126.57:30080/pending"
  }
}
EOF
)" && echo " -> OK" || echo " -> Already exists or failed, continuing..."

echo ""
echo "=== Grafana Alerting Configured ==="
echo "Check: ${GRAFANA_URL}/alerting/list"
echo "Runbook approvals: http://13.216.126.57:30080/pending"
