#!/usr/bin/env bash
# platform/loki/install.sh
#
# Idempotent install / upgrade of Loki + Promtail on the k3s node.
# Run directly on the VM:
#   bash install.sh
#
# Or invoked by the GHA loki workflow automatically.

set -euo pipefail

NAMESPACE="monitoring"
LOKI_RELEASE="loki"
PROMTAIL_RELEASE="promtail"
SCRIPT_DIR="$(dirname "$0")"

echo "==> Adding Helm repo"
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana

echo "==> Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing / upgrading $LOKI_RELEASE"
helm upgrade --install "$LOKI_RELEASE" grafana/loki \
  --namespace "$NAMESPACE" \
  --values "$SCRIPT_DIR/values.yaml" \
  --wait \
  --timeout 10m

echo "==> Installing / upgrading $PROMTAIL_RELEASE"
helm upgrade --install "$PROMTAIL_RELEASE" grafana/promtail \
  --namespace "$NAMESPACE" \
  --values "$SCRIPT_DIR/promtail-values.yaml" \
  --wait \
  --timeout 5m

echo ""
echo "==> Done. Loki + Promtail deployed in namespace: $NAMESPACE"
echo "    Loki gateway: http://loki-gateway.$NAMESPACE.svc.cluster.local"
echo "    Add as Grafana datasource (type: Loki) with the URL above."
