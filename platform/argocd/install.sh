#!/usr/bin/env bash
# platform/argocd/install.sh
#
# Idempotent install / upgrade of ArgoCD on k3s.
# Run directly on the VM:
#   bash install.sh [--password <admin-password>]

set -euo pipefail

NAMESPACE="argocd"
ARGOCD_PASSWORD="${ARGOCD_ADMIN_PASSWORD:-admin}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --password) ARGOCD_PASSWORD="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

echo "==> Adding Argo Helm repo"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo

echo "==> Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing / upgrading ArgoCD"
helm upgrade --install argocd argo/argo-cd \
  --namespace "$NAMESPACE" \
  --values "$(dirname "$0")/values.yaml" \
  --wait \
  --timeout 10m

echo "==> Setting admin password"
BCRYPT_HASH=$(htpasswd -nbBC 10 "" "$ARGOCD_PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')
kubectl -n "$NAMESPACE" patch secret argocd-secret \
  -p "{\"stringData\": {\"admin.password\": \"$BCRYPT_HASH\", \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"}}" \
  2>/dev/null || true

echo "==> Applying ArgoCD Application manifests"
kubectl apply -f "$(dirname "$0")/applications/"

echo ""
echo "==> Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment/argocd-server \
  --namespace "$NAMESPACE" \
  --timeout 5m

echo ""
echo "==> ArgoCD is available at:"
echo "    http://$(curl -sf http://checkip.amazonaws.com || echo '<VM_PUBLIC_IP>')/argocd"
echo "    Username: admin"
echo "    Password: (set via ARGOCD_ADMIN_PASSWORD)"
