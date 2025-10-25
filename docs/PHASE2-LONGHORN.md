# Phase 2: Longhorn Storage Deployment

## Overview

Phase 2 adds Longhorn distributed block storage to the k3s cluster, providing persistent storage for applications with optional encrypted backups to S3-compatible storage.

## Prerequisites

- Phase 1 completed: k3s cluster running
- kubectl access to the cluster
- Helm 3 installed (script will install if missing)
- At least 10GB free space in `/var/lib/longhorn`

## Quick Start

```bash
cd manifests/longhorn
./deploy.sh
```

## What Gets Deployed

### Longhorn Components

- **Longhorn Manager**: Manages volumes and storage
- **Longhorn Driver**: CSI driver for Kubernetes
- **Longhorn UI**: Web interface for management
- **Longhorn Engine**: Distributed block storage engine

### Storage Configuration

- **Storage Path**: `/var/lib/longhorn` (configured in Containerfile)
- **Default Replica Count**: 1 (single-node cluster)
- **Storage Class**: `longhorn` (set as default)
- **Reclaim Policy**: Retain (data persists after PVC deletion)

## Manual Deployment

If you prefer manual deployment:

```bash
# Add Longhorn Helm repo
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Create namespace
kubectl create namespace longhorn-system

# Optional: Create backup secret (see Backup Configuration below)
kubectl apply -f backup-secret.yaml

# Install Longhorn
helm install longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --values values.yaml \
    --create-namespace
```

## Configuration

### Basic Settings (values.yaml)

The Longhorn configuration is minimal and optimized for single-node operation:

- **Single replica**: Perfect for single-node clusters
- **Storage overprovisioning**: 200% (allows flexible volume creation)
- **Minimal resources**: CPU/memory limits suitable for home servers
- **Tolerations**: Allows running on control-plane nodes

### Backup Configuration (Optional)

Longhorn supports encrypted backups to S3-compatible storage:

#### Step 1: Create Backup Secret

```bash
# Copy the example
cp backup-secret.yaml.example backup-secret.yaml

# Edit with your credentials
nano backup-secret.yaml
```

#### Step 2: Apply the Secret

```bash
kubectl apply -f backup-secret.yaml
```

#### Step 3: Update values.yaml

Uncomment the backup settings:

```yaml
defaultSettings:
  backupTarget: s3://your-bucket@region/
  backupTargetCredentialSecret: longhorn-backup-secret
```

#### Step 4: Update Longhorn

```bash
helm upgrade longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --values values.yaml
```

### Supported Backup Targets

- **AWS S3**: `s3://bucket@region/`
- **Backblaze B2**: `s3://bucket@region/` (use B2 S3-compatible API)
- **MinIO**: `s3://bucket@region/` (self-hosted S3-compatible)
- **NFS**: `nfs://server:/path`

## Verification

### Check Deployment Status

```bash
# Watch pods come up
kubectl -n longhorn-system get pods -w

# Check all components
kubectl -n longhorn-system get pods
```

All pods should be in `Running` state within 5-10 minutes.

### Verify Storage Class

```bash
kubectl get storageclass
```

Expected output:
```
NAME                 PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE
longhorn (default)   driver.longhorn.io   Retain          Immediate
local-path           ...                  Delete          WaitForFirstConsumer
```

### Test Volume Creation

```bash
# Create test PVC and pod
kubectl apply -f test-pvc.yaml

# Wait for PVC to be bound
kubectl get pvc longhorn-test-pvc

# Check if pod is running
kubectl get pod longhorn-test-pod

# Cleanup test resources
kubectl delete -f test-pvc.yaml
```

## Accessing Longhorn UI

The Longhorn UI will be accessible after Phase 3 (step-ca and cert-manager for TLS).

For now, you can port-forward:

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
```

Then access: http://localhost:8080

## Multi-Node Expansion

When adding additional nodes to your cluster:

1. **Update replica count** in values.yaml:
   ```yaml
   persistence:
     defaultClassReplicaCount: 2  # Or 3 for high availability
   ```

2. **Enable anti-affinity**:
   ```yaml
   defaultSettings:
     replicaSoftAntiAffinity: true
     replicaAutoBalance: best-effort
   ```

3. **Upgrade Longhorn**:
   ```bash
   helm upgrade longhorn longhorn/longhorn \
       --namespace longhorn-system \
       --values values.yaml
   ```

## Troubleshooting

### Pods Not Starting

Check node requirements:

```bash
# Longhorn requires certain kernel modules
lsmod | grep -E 'dm_crypt|dm_snapshot|dm_mirror|dm_thin_pool'

# Check for required packages
rpm -qa | grep iscsi
```

### Storage Not Provisioning

```bash
# Check Longhorn manager logs
kubectl -n longhorn-system logs -l app=longhorn-manager

# Check node status in Longhorn
kubectl -n longhorn-system get nodes.longhorn.io
```

### Backup Failures

```bash
# Check backup secret
kubectl -n longhorn-system get secret longhorn-backup-secret

# Test S3 connectivity from a pod
kubectl run -it --rm debug --image=amazon/aws-cli --restart=Never -- \
    s3 ls --endpoint-url=https://your-endpoint
```

## Performance Tuning

For better performance on SSDs:

```yaml
defaultSettings:
  # Disable sync for better performance (trade-off: less durability)
  disableRevisionCounter: true

  # Faster snapshot operations
  snapshotDataIntegrity: disabled

  # Adjust I/O timeout
  engineReplicaTimeout: 8
```

## Backup Best Practices

1. **Regular snapshots**: Set up recurring snapshots for important volumes
2. **Test restores**: Periodically test backup restoration
3. **Encryption**: Always use encryption for backups (CRYPTO_KEY_VALUE)
4. **Retention**: Configure backup retention policies
5. **Monitor backup jobs**: Check Longhorn UI for failed backups

## Next Steps

After Longhorn is deployed and validated:

1. **Proceed to Phase 3**: Deploy step-ca and cert-manager for TLS
2. **Enable Longhorn UI ingress**: Configure in Phase 3 with automatic TLS
3. **Set up backup schedules**: Create recurring backup jobs
4. **Monitor storage usage**: Check Longhorn UI regularly

See [../CLAUDE.md](../CLAUDE.md) for overall project status.

## Resources

- [Longhorn Documentation](https://longhorn.io/docs/)
- [Longhorn Best Practices](https://longhorn.io/docs/latest/best-practices/)
- [Backup and Restore](https://longhorn.io/docs/latest/snapshots-and-backups/)
