#!/bin/bash
# Deploy Longhorn to k3s cluster
# Phase 2: Storage and Persistence

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Longhorn Deployment Script ===${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}ERROR: kubectl not found${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${RED}ERROR: helm not found. Installing helm...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add Longhorn Helm repository
echo -e "${GREEN}Adding Longhorn Helm repository...${NC}"
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Create longhorn-system namespace
echo -e "${GREEN}Creating longhorn-system namespace...${NC}"
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -

# Check if backup secret should be applied
if [ -f "backup-secret.yaml" ]; then
    echo -e "${GREEN}Applying backup credentials secret...${NC}"
    kubectl apply -f backup-secret.yaml
else
    echo -e "${YELLOW}Note: No backup-secret.yaml found. Backups will not be configured.${NC}"
    echo -e "${YELLOW}To enable backups, create backup-secret.yaml from backup-secret.yaml.example${NC}"
fi

# Deploy Longhorn
echo -e "${GREEN}Deploying Longhorn with Helm...${NC}"
helm upgrade --install longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --values values.yaml \
    --create-namespace \
    --wait \
    --timeout 10m

echo ""
echo -e "${GREEN}Longhorn deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Check deployment status: kubectl -n longhorn-system get pods"
echo "  2. Wait for all pods to be ready (may take a few minutes)"
echo "  3. Check storage class: kubectl get storageclass"
echo "  4. Longhorn UI will be available after Phase 3 (TLS setup)"
echo ""
echo "To test Longhorn:"
echo "  kubectl apply -f test-pvc.yaml"
echo "  kubectl get pvc"
echo ""
