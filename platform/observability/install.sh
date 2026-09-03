#!/usr/bin/env bash
# platform/observability/install.sh
#
# Idempotent install / upgrade of the kube-prometheus-stack on the k3s node.
# Run directly on the VM:
#   bash install.sh [--password <grafana-admin-password>]
#
# Or invoked by the GHA observability workflow automatically.

set -euo pipefail

NAMESPACE="monitoring"
RELEASE="kube-prometheus-stack"
GRAFANA_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"  # overridden by GHA secret

# Parse optional --password flag
while [[ $# -gt 0 ]]; do
  case "$1" in
    --password) GRAFANA_PASSWORD="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

echo "==> Adding Helm repo"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community

echo "==> Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing / upgrading $RELEASE"
helm upgrade --install "$RELEASE" prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" \
  --values "$(dirname "$0")/values.yaml" \
  --set grafana.adminPassword="$GRAFANA_PASSWORD" \
  --wait \
  --timeout 10m

echo ""
echo "==> Applying Traefik ServiceMonitor"
kubectl apply -f "$(dirname "$0")/traefik-servicemonitor.yaml"

echo "==> Applying SLO recording rules & alerts"
kubectl apply -f "$(dirname "$0")/slo-rules.yaml"

echo "==> Provisioning candidate-api Grafana dashboard"
SCRIPT_DIR="$(dirname "$0")"
kubectl create configmap candidate-api-dashboard \
  --namespace "$NAMESPACE" \
  --from-file=candidate-api-slo.json="$SCRIPT_DIR/dashboards/candidate-api-slo.json" \
  --dry-run=client -o yaml | \
  kubectl label --local -f - grafana_dashboard=1 -o yaml --dry-run=client | \
  kubectl apply -f -

echo ""
echo "==> Done. Waiting for Grafana pod to be ready..."
kubectl rollout status deployment/"$RELEASE-grafana" \
  --namespace "$NAMESPACE" \
  --timeout 5m

echo ""
echo "==> Grafana is available at:"
echo "    http://$(curl -sf http://checkip.amazonaws.com || echo '<VM_PUBLIC_IP>')/grafana"
echo "    Username: admin"
echo "    Password: (set via GRAFANA_ADMIN_PASSWORD)"
