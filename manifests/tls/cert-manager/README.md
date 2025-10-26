# cert-manager Manifests

Phase 3: Kubernetes certificate controller for automatic TLS.

## Files

- **cert-manager-helmchart.yaml**: k3s HelmChart manifest for cert-manager
  - Installs cert-manager CRDs automatically
  - Minimal resource configuration
  - Prometheus metrics enabled

## Auto-Deployment

cert-manager is automatically deployed by k3s on boot. The HelmChart is copied to `/var/lib/rancher/k3s/server/manifests/cert-manager.yaml` in the bootc image.

## Configuration

- **Namespace**: `cert-manager`
- **CRDs**: Installed automatically
- **Resources**: Minimal (10m CPU, 32Mi memory requests)
- **Metrics**: Prometheus ServiceMonitor enabled

## Verification

```bash
# Check deployment
kubectl -n cert-manager get pods

# Check CRDs
kubectl get crds | grep cert-manager

# View logs
kubectl -n cert-manager logs -l app=cert-manager
```

## Documentation

See [../../docs/PHASE3-TLS.md](../../docs/PHASE3-TLS.md) for complete Phase 3 documentation.
