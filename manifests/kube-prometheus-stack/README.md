# kube-prometheus-stack Manifests

Phase 4: Complete monitoring stack with Prometheus, Grafana, and Alertmanager.

## Files

- **kube-prometheus-stack-helmchart.yaml**: k3s HelmChart manifest for kube-prometheus-stack
  - Prometheus for metrics collection
  - Grafana for visualization
  - Alertmanager for alerting
  - Node Exporter and kube-state-metrics
  - All with automatic HTTPS via step-ca
- **grafana-oauth-secret.yaml.example**: Template for Grafana OAuth secret (copy to grafana-oauth-secret.yaml)

## Auto-Deployment

The monitoring stack is automatically deployed by k3s on boot. The HelmChart is copied to `/var/lib/rancher/k3s/server/manifests/kube-prometheus-stack.yaml` in the bootc image.

## Configuration

- **Namespace**: `monitoring`
- **Grafana URL**: `https://grafana.local`
- **Prometheus URL**: `https://prometheus.local`
- **Alertmanager URL**: `https://alertmanager.local`
- **Default Credentials**: admin / admin (change on first login!)

### OAuth Setup (Authentik Integration)

To enable Authentik SSO for Grafana:

1. **Copy the secret template**:
   ```bash
   cp manifests/kube-prometheus-stack/grafana-oauth-secret.yaml.example \
      manifests/kube-prometheus-stack/grafana-oauth-secret.yaml
   ```

2. **Get the client secret from Authentik**:
   - After Authentik is deployed, log into https://authentik.local
   - Navigate to: Applications → Providers → Grafana
   - Click "View" to see the auto-generated client secret

3. **Update the secret file**:
   ```bash
   vim manifests/kube-prometheus-stack/grafana-oauth-secret.yaml
   # Replace AUTHENTIK_CLIENT_SECRET_HERE with the actual value
   ```

4. **Rebuild the bootc image** (the secret is deployed automatically on boot):
   ```bash
   ./scripts/build.sh
   sudo bootc switch --transport=oci localhost/nubita-bootc:latest
   sudo systemctl reboot
   ```

**Note**: The secret file is automatically gitignored to prevent committing sensitive data.

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
