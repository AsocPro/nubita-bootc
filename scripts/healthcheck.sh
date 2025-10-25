#!/bin/bash
# Health check script for k3s cluster

set -e

# Check if k3s is running
if ! systemctl is-active --quiet k3s; then
    echo "ERROR: k3s service is not running"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl command not found"
    exit 1
fi

# Check if we can connect to the API server
if ! kubectl get --raw /healthz &> /dev/null; then
    echo "ERROR: Cannot connect to k3s API server"
    exit 1
fi

# Check if nodes are ready
NODE_STATUS=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
if [ "$NODE_STATUS" != "True" ]; then
    echo "ERROR: Node is not ready"
    exit 1
fi

echo "OK: k3s cluster is healthy"
exit 0
