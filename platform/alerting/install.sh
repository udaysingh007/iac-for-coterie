#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Alerting Demo Setup ==="
echo "No Docker needed — uses python:3.12-alpine image + ConfigMaps."
echo ""

# --- 1. Create namespace ---
kubectl apply -f "$SCRIPT_DIR/k8s/namespace.yaml"

# --- 2. Create Gmail secret (if not exists) ---
if ! kubectl get secret gmail-credentials -n alerting &>/dev/null; then
  echo ""
  echo "Gmail App Password secret not found."
  echo "Please create it with:"
  echo "  kubectl create secret generic gmail-credentials -n alerting --from-literal=app-password='YOUR_APP_PASSWORD'"
  echo ""
  echo "Then re-run this script."
  exit 1
fi

# --- 3. Deploy canary + runbook controller ---
kubectl apply -f "$SCRIPT_DIR/k8s/canary.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/runbook-controller.yaml"

# --- 4. Wait for pods ---
echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=runbook-controller -n alerting --timeout=120s || true
echo ""
kubectl get pods -n alerting

# --- 5. Configure Grafana alert rules and contact point via API ---
echo ""
echo "Now configure Grafana alerting via API."
echo "You can run this separately if Grafana is not ready yet:"
echo "  $SCRIPT_DIR/configure-grafana-alerts.sh http://localhost <GRAFANA_ADMIN_PASSWORD>"
echo ""
read -rp "Configure Grafana alerts now? (y/n): " CONFIGURE_GRAFANA
if [[ "$CONFIGURE_GRAFANA" == "y" ]]; then
  read -rp "Grafana admin password: " GRAFANA_PW
  "$SCRIPT_DIR/configure-grafana-alerts.sh" "http://localhost" "$GRAFANA_PW"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "IMPORTANT: Ensure AWS Security Group allows inbound TCP 30080 from your IP."
echo ""
echo "Timeline:"
echo "  - Canary pod starts healthy"
echo "  - After ~2 minutes, /healthz returns 503"
echo "  - After ~30s of failures, k8s restarts the pod"
echo "  - Prometheus picks up restart count increase"
echo "  - Grafana alert fires and sends webhook to runbook-controller"
echo "  - Runbook-controller emails you an approval link"
echo "  - Click the link -> pod gets restarted -> healthy again"
echo ""
echo "Monitor:"
echo "  kubectl get pods -n alerting -w"
