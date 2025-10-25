# Longhorn Storage Manifests

Phase 2: Distributed block storage with optional encrypted backups.

## Files

- **values.yaml**: Minimal Helm values for single-node Longhorn deployment
- **backup-secret.yaml.example**: Template for S3 backup credentials
- **deploy.sh**: Automated deployment script
- **test-pvc.yaml**: Test PVC and pod to verify Longhorn works

## Quick Deploy

```bash
./deploy.sh
```

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

2. Uncomment backup settings in values.yaml:
   ```yaml
   backupTarget: s3://bucket@region/
   backupTargetCredentialSecret: longhorn-backup-secret
   ```

3. Redeploy:
   ```bash
   helm upgrade longhorn longhorn/longhorn \
       --namespace longhorn-system \
       --values values.yaml
   ```

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
