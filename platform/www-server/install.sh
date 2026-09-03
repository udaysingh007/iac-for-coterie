#!/usr/bin/env bash
# platform/www-server/install.sh
#
# Deploy the landing page to the default namespace.

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

echo "==> Deploying landing page"
kubectl apply -f "$SCRIPT_DIR/k8s/"

echo "==> Restarting pod to pick up ConfigMap changes"
kubectl rollout restart deployment/landing-page --namespace default

echo "==> Waiting for deployment..."
kubectl rollout status deployment/landing-page --namespace default --timeout 2m

echo ""
echo "==> Landing page available at:"
echo "    http://$(curl -sf http://checkip.amazonaws.com || echo '<VM_PUBLIC_IP>')/"
