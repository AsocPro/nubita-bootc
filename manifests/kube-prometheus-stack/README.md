# kube-prometheus-stack Manifests

Phase 4: Complete monitoring stack with Prometheus, Grafana, and Alertmanager.

## Files

- **helmchart.yaml**: k3s HelmChart manifest for kube-prometheus-stack
  - Prometheus for metrics collection
  - Grafana for visualization
  - Alertmanager for alerting
  - Node Exporter and kube-state-metrics
  - All with automatic HTTPS via step-ca

## Auto-Deployment

The monitoring stack is automatically deployed by k3s on boot. The HelmChart is copied to `/var/lib/rancher/k3s/server/manifests/kube-prometheus-stack.yaml` in the bootc image.

## Configuration

- **Namespace**: `monitoring`
- **Grafana URL**: `https://grafana.local`
- **Prometheus URL**: `https://prometheus.local`
- **Alertmanager URL**: `https://alertmanager.local`
- **Default Credentials**: admin / admin (change on first login!)

### Storage

- **Grafana**: 5Gi Longhorn volume
- **Prometheus**: 15Gi Longhorn volume (15-day retention)
- **Alertmanager**: 2Gi Longhorn volume

### Resources

Optimized for home server:
- **Grafana**: 128Mi memory, 50m CPU (requests)
- **Prometheus**: 512Mi memory, 100m CPU (requests)
- **Alertmanager**: 64Mi memory, 10m CPU (requests)

## Accessing Grafana

```bash
# Add to /etc/hosts
echo "192.168.1.x grafana.local" | sudo tee -a /etc/hosts

# Open browser
https://grafana.local

# Login: admin / admin
```

## Verification

```bash
# Check deployment
kubectl -n monitoring get pods

# Check storage
kubectl -n monitoring get pvc

# Check ingress
kubectl -n monitoring get ingress

# Check certificates
kubectl -n monitoring get certificates
```

## Pre-Loaded Dashboards

Grafana includes default Kubernetes dashboards:
- Cluster overview
- Node metrics
- Pod metrics
- Persistent volume metrics
- Network metrics

## Custom Dashboards

Import from [grafana.com/dashboards](https://grafana.com/dashboards):
- **1860**: Node Exporter Full
- **12740**: Kubernetes Monitoring
- **13770**: Longhorn (if available)

## Documentation

See [../../docs/PHASE4-MONITORING.md](../../docs/PHASE4-MONITORING.md) for complete documentation.
