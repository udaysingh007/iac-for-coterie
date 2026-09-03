#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Alerting & Runbook Setup ==="
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

# --- 3. Deploy runbook controller ---
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
echo "How the runbook demo works:"
echo "  1. Deploy candidate-api with chaos mode enabled (uncomment in Program.cs)"
echo "  2. Synthetic monitor generates traffic to /dev/api/work-items"
echo "  3. After ~5 minutes, the endpoint starts returning 500 errors"
echo "  4. Availability SLO drops below 99.9%"
echo "  5. Grafana alert fires and sends webhook to runbook-controller"
echo "  6. Runbook-controller emails you an approval link"
echo "  7. Click the link -> GitOps rollback via GitHub API -> ArgoCD syncs -> healthy again"
echo ""
echo "Pending approvals page: http://13.216.126.57/runbook/pending"
