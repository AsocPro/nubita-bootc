# Longhorn Storage Manifests

Phase 2: Distributed block storage with automatic deployment via k3s Helm controller.

## Files

- **longhorn-helmchart.yaml**: k3s HelmChart manifest (auto-deployed by k3s)
- **values.yaml**: Reference Helm values (deprecated - use longhorn-helmchart.yaml)
- **backup-secret.yaml.example**: Template for S3 backup credentials
- **test-pvc.yaml**: Test PVC and pod to verify Longhorn works

## Quick Deploy

**No deployment needed!** Longhorn is automatically deployed by k3s when the system boots.

The `longhorn-helmchart.yaml` is copied to `/var/lib/rancher/k3s/server/manifests/longhorn.yaml` in the bootc image, and k3s's Helm controller deploys it automatically.

## Configuration

### Single-Node Settings (Default)

- 1 replica per volume
- Storage path: `/var/lib/longhorn`
- Minimal resource requests
- Runs on control-plane nodes

### Enable Backups

1. Create backup secret:
   ```bash
   cp backup-secret.yaml.example backup-secret.yaml
   # Edit with your S3 credentials
   kubectl apply -f backup-secret.yaml
   ```

2. Uncomment backup settings in `longhorn-helmchart.yaml`:
   ```yaml
   backupTarget: s3://bucket@region/
   backupTargetCredentialSecret: longhorn-backup-secret
   ```

3. Either:
   - **Rebuild bootc image** with updated longhorn-helmchart.yaml, OR
   - **Live update**: `kubectl edit helmchart longhorn -n kube-system`

## Testing

```bash
# Create test PVC
kubectl apply -f test-pvc.yaml

# Verify
kubectl get pvc longhorn-test-pvc
kubectl get pod longhorn-test-pod

# Cleanup
kubectl delete -f test-pvc.yaml
```

## Documentation

See [../../docs/PHASE2-LONGHORN.md](../../docs/PHASE2-LONGHORN.md) for complete documentation.
