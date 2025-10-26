# Gitea Manifests

Phase 6: Self-hosted Git service with Actions and SSO support.

## Files

- **gitea-helmchart.yaml**: k3s HelmChart manifest for Gitea
  - Gitea server with PostgreSQL database
  - 20Gi Longhorn volume for repositories
  - 10Gi Longhorn volume for PostgreSQL
  - Automatic HTTPS via step-ca
  - Gitea Actions enabled (GitHub Actions compatible)
  - SSH support enabled

## Auto-Deployment

Gitea is automatically deployed by k3s on boot. The HelmChart is copied to `/var/lib/rancher/k3s/server/manifests/gitea.yaml` in the bootc image.

## Configuration

- **Namespace**: `gitea`
- **URL**: `https://gitea.local`
- **Database**: PostgreSQL (10Gi Longhorn volume)
- **Repository Storage**: 20Gi Longhorn volume
- **Admin User**: `gitadmin` (password: `changeme` - change this!)

### Security

**Important**: Change these defaults before production use!

Edit `gitea-helmchart.yaml`:
```yaml
gitea:
  admin:
    password: "changeme"  # Change this!
  config:
    database:
      PASSWD: gitea  # Change this!
    security:
      SECRET_KEY: "change-this-to-a-random-string"  # Change this!
      INTERNAL_TOKEN: "change-this-to-a-random-string"  # Change this!
```

Generate secure values:
```bash
openssl rand -base64 48  # For SECRET_KEY and INTERNAL_TOKEN
openssl rand -base64 32  # For passwords
```

## SSO Integration

**Automated!** The Gitea OAuth provider is automatically configured via Authentik blueprints.

See [../../docs/PHASE6-APPLICATIONS.md](../../docs/PHASE6-APPLICATIONS.md#gitea-configuration) for complete setup.

Quick steps:
1. Retrieve client secret from Authentik UI (auto-generated on first boot)
2. Configure OAuth in Gitea admin panel
3. Users can log in to Gitea with Authentik

## Accessing Gitea

```bash
# Add to /etc/hosts
echo "192.168.1.x gitea.local" | sudo tee -a /etc/hosts

# Open browser
https://gitea.local
```

## Initial Setup

1. Log in with admin credentials (`gitadmin` / `changeme`)
2. Change admin password immediately
3. Configure OAuth in Site Administration → Authentication Sources
4. Create repositories and start using Git!

## Gitea Actions

Gitea Actions (CI/CD) is enabled by default.

Create `.gitea/workflows/build.yaml` in your repository:
```yaml
name: Build
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: make build
```

## SSH Access

Gitea supports Git over SSH:

```bash
# Clone via SSH
git clone git@gitea.local:username/repo.git

# Add SSH key in Gitea
# Settings → SSH / GPG Keys → Add Key
```

## Verification

```bash
# Check deployment
kubectl -n gitea get pods

# Check storage
kubectl -n gitea get pvc

# Check ingress
kubectl -n gitea get ingress

# Check certificate
kubectl -n gitea get certificate
```

## Documentation

See [../../docs/PHASE6-APPLICATIONS.md](../../docs/PHASE6-APPLICATIONS.md) for complete documentation.
