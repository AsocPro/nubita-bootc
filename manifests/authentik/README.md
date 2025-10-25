# Authentik Manifests

Phase 5: SSO and authentication provider with OIDC/LDAP support.

## Files

- **helmchart.yaml**: k3s HelmChart manifest for Authentik
  - Authentik server and worker
  - PostgreSQL database with Longhorn storage
  - Redis cache with Longhorn storage
  - All with automatic HTTPS via step-ca

## Auto-Deployment

Authentik is automatically deployed by k3s on boot. The HelmChart is copied to `/var/lib/rancher/k3s/server/manifests/authentik.yaml` in the bootc image.

## Configuration

- **Namespace**: `authentik`
- **URL**: `https://authentik.local`
- **Database**: PostgreSQL (5Gi Longhorn volume)
- **Cache**: Redis (1Gi Longhorn volume)

### Security

**Important**: Change these defaults before production use!

Edit `helmchart.yaml`:
```yaml
authentik:
  secret_key: "CHANGE-ME-TO-A-RANDOM-STRING"
  postgresql:
    password: "CHANGE-ME"
```

Generate secure values:
```bash
openssl rand -base64 48  # For secret_key
openssl rand -base64 32  # For PostgreSQL password
```

## Accessing Authentik

```bash
# Add to /etc/hosts
echo "192.168.1.x authentik.local" | sudo tee -a /etc/hosts

# Open browser
https://authentik.local
```

## Initial Setup

On first access:
1. Create admin user
2. Set admin password
3. Configure domain (`authentik.local`)

## SSO Integration

### For Grafana

See [../../docs/PHASE5-AUTHENTIK.md](../../docs/PHASE5-AUTHENTIK.md#configuring-sso-for-grafana) for complete setup.

Quick steps:
1. Create OAuth provider in Authentik
2. Create application in Authentik
3. Update Grafana configuration with OAuth settings
4. Users can log in to Grafana with Authentik

## Verification

```bash
# Check deployment
kubectl -n authentik get pods

# Check storage
kubectl -n authentik get pvc

# Check ingress
kubectl -n authentik get ingress

# Check certificate
kubectl -n authentik get certificate
```

## Documentation

See [../../docs/PHASE5-AUTHENTIK.md](../../docs/PHASE5-AUTHENTIK.md) for complete documentation.
