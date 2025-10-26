# Phase 6: Core Applications

## Overview

Phase 6 adds essential self-hosted applications with automatic SSO integration via Authentik:

- **Gitea**: Self-hosted Git service with Actions (CI/CD)
- **Vaultwarden**: Bitwarden-compatible password manager

Both applications are auto-deployed via k3s Helm controller and pre-configured for Authentik SSO using blueprints.

## Components

### Gitea
- Self-hosted Git hosting
- Pull requests, issues, wikis
- Gitea Actions (GitHub Actions compatible)
- PostgreSQL database with Longhorn storage
- **Auto-deployed** via k3s Helm controller
- **SSO pre-configured** via Authentik blueprint

### Vaultwarden
- Bitwarden-compatible password manager
- End-to-end encrypted vault
- Browser extensions and mobile apps supported
- SQLite database with Longhorn storage
- **Auto-deployed** via k3s Helm controller
- **SSO pre-configured** via Authentik blueprint

## Quick Start

**No manual OAuth setup needed!** Both applications have OAuth providers automatically created by Authentik blueprints.

1. Boot the bootc image
2. k3s deploys Gitea and Vaultwarden
3. Authentik auto-creates OAuth providers
4. Retrieve client secrets from Authentik UI
5. Update application configurations
6. Access applications with SSO

## Accessing Applications

### Gitea
```
https://gitea.local
```

### Vaultwarden
```
https://vaultwarden.local
```

**Setup DNS:**
```bash
# Add to /etc/hosts
echo "192.168.1.x gitea.local" | sudo tee -a /etc/hosts
echo "192.168.1.x vaultwarden.local" | sudo tee -a /etc/hosts
```

## Automatic OAuth Configuration

Both Gitea and Vaultwarden OAuth providers are automatically configured via Authentik blueprints!

**What's automated:**
- OAuth provider creation in Authentik
- Application registration in Authentik
- Redirect URI configuration
- Scope mappings (openid, profile, email)
- Client ID assignment (gitea, vaultwarden)

**What you need to do:**
- Retrieve auto-generated client secrets from Authentik UI
- Update application configurations with secrets

## Initial Setup

### Gitea Configuration

#### Step 1: Retrieve OAuth Client Secret

1. Log in to Authentik at `https://authentik.local`
2. Go to **Applications** → **Providers**
3. Click on **Gitea** provider
4. Click **View details** to see the **Client Secret**
5. Copy the client secret

#### Step 2: Configure Gitea OAuth

Gitea OAuth is configured via the UI after first login:

1. Access Gitea at `https://gitea.local`
2. Log in with admin credentials (from helmchart.yaml):
   - Username: `gitadmin`
   - Password: `changeme` (change this!)
3. Go to **Site Administration** → **Authentication Sources**
4. Click **Add Authentication Source**
5. Configure:
   - **Authentication Type**: OAuth2
   - **Authentication Name**: Authentik
   - **OAuth2 Provider**: OpenID Connect
   - **Client ID**: `gitea`
   - **Client Secret**: Paste from Step 1
   - **OpenID Connect Auto Discovery URL**: `https://authentik.local/application/o/gitea/.well-known/openid-configuration`
6. Click **Add Authentication Source**

Users can now sign in with Authentik!

#### Step 3: Security Configuration

**Important**: Change default passwords in `manifests/gitea/gitea-helmchart.yaml`:

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
# For SECRET_KEY and INTERNAL_TOKEN
openssl rand -base64 48

# For passwords
openssl rand -base64 32
```

Then rebuild the bootc image.

### Vaultwarden Configuration

#### Step 1: Retrieve OAuth Client Secret

1. Log in to Authentik at `https://authentik.local`
2. Go to **Applications** → **Providers**
3. Click on **Vaultwarden** provider
4. Click **View details** to see the **Client Secret**
5. Copy the client secret

#### Step 2: Update Vaultwarden Configuration

Edit `manifests/vaultwarden/vaultwarden-helmchart.yaml` and replace the placeholder:

```yaml
vaultwarden:
  sso:
    enabled: true
    clientId: "vaultwarden"
    clientSecret: "PASTE_YOUR_CLIENT_SECRET_HERE"
```

The OAuth configuration is already enabled, you just need to add the real client secret.

#### Step 3: Rebuild and Redeploy

```bash
# Rebuild bootc image with updated secret
./scripts/build.sh

# Redeploy to apply changes
```

Or update the running HelmChart without rebuilding:
```bash
kubectl edit helmchart vaultwarden -n kube-system
# Update the clientSecret value
```

#### Step 4: Security Configuration

**Important**: Change default admin token in `manifests/vaultwarden/vaultwarden-helmchart.yaml`:

```yaml
vaultwarden:
  adminToken: "CHANGE-ME-TO-RANDOM-TOKEN"
```

Generate secure token:
```bash
openssl rand -base64 48
```

Then rebuild the bootc image.

#### Step 5: First Login

1. Go to `https://vaultwarden.local`
2. Click **Enterprise Single Sign-On**
3. Enter your email (registered in Authentik)
4. Authenticate with Authentik
5. You're logged in to Vaultwarden!

Alternatively, create a local account (if `signupsAllowed: true`):
1. Go to `https://vaultwarden.local`
2. Click **Create Account**
3. Fill in details and create account

## Configuration

### Gitea Settings

Configured in `manifests/gitea/gitea-helmchart.yaml`:

- **Namespace**: `gitea`
- **URL**: `https://gitea.local`
- **Database**: PostgreSQL (10Gi Longhorn volume)
- **Repository Storage**: 20Gi Longhorn volume
- **SSH**: Enabled (port 22)
- **Actions**: Enabled (GitHub Actions compatible)

### Vaultwarden Settings

Configured in `manifests/vaultwarden/vaultwarden-helmchart.yaml`:

- **Namespace**: `vaultwarden`
- **URL**: `https://vaultwarden.local`
- **Database**: SQLite (simple for home use)
- **Vault Storage**: 5Gi Longhorn volume
- **Signups**: Enabled by default (disable after creating accounts)
- **SSO**: Pre-configured for Authentik

### Resources

Optimized for home server:

**Gitea**:
- Application: 256Mi memory, 100m CPU (requests)
- PostgreSQL: 256Mi memory, 100m CPU (requests)

**Vaultwarden**:
- Application: 128Mi memory, 50m CPU (requests)

## Verification

### Check Gitea Deployment

```bash
# Check pods
kubectl -n gitea get pods

# Check PVCs
kubectl -n gitea get pvc

# Check ingress
kubectl -n gitea get ingress

# Check certificate
kubectl -n gitea get certificate
```

### Check Vaultwarden Deployment

```bash
# Check pods
kubectl -n vaultwarden get pods

# Check PVCs
kubectl -n vaultwarden get pvc

# Check ingress
kubectl -n vaultwarden get ingress

# Check certificate
kubectl -n vaultwarden get certificate
```

### Check OAuth Providers in Authentik

```bash
# Log in to Authentik
open https://authentik.local

# Navigate to: Applications → Providers
# You should see:
# - Grafana
# - Gitea
# - Vaultwarden
```

## Using Gitea

### Creating Repositories

1. Log in to Gitea
2. Click **+** in top right → **New Repository**
3. Configure repository settings
4. Click **Create Repository**

### Gitea Actions (CI/CD)

Gitea Actions is enabled by default, providing GitHub Actions-compatible CI/CD.

**Example workflow** (`.gitea/workflows/test.yaml`):
```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: make test
```

**Note**: By default, Gitea uses external runners (GitHub Actions runners). To use in-cluster runners, uncomment the `gitea-actions-runner` section in `manifests/gitea/gitea-helmchart.yaml`.

### SSH Access

Gitea supports Git over SSH:

```bash
# Clone via SSH
git clone git@gitea.local:username/repo.git

# Add SSH key in Gitea
# Settings → SSH / GPG Keys → Add Key
```

## Using Vaultwarden

### Browser Extensions

Vaultwarden is compatible with official Bitwarden extensions:

**Chrome/Edge**:
https://chrome.google.com/webstore/detail/bitwarden/nngceckbapebfimnlniiiahkandclblb

**Firefox**:
https://addons.mozilla.org/firefox/addon/bitwarden-password-manager/

**Configuration**:
1. Install extension
2. Click extension icon → Settings (gear icon)
3. Set **Server URL**: `https://vaultwarden.local`
4. Log in with Authentik SSO

### Mobile Apps

Official Bitwarden mobile apps work with Vaultwarden:

**iOS**: https://apps.apple.com/app/bitwarden-password-manager/id1137397744

**Android**: https://play.google.com/store/apps/details?id=com.x8bit.bitwarden

**Configuration**:
1. Install app
2. Tap **Region** → Self-hosted
3. Set **Server URL**: `https://vaultwarden.local`
4. Log in with Authentik SSO

### Admin Panel

Access Vaultwarden admin panel at:
```
https://vaultwarden.local/admin
```

Use the `adminToken` configured in `manifests/vaultwarden/vaultwarden-helmchart.yaml`.

## Email Configuration (Optional)

### Gitea Email

Edit `manifests/gitea/gitea-helmchart.yaml`:

```yaml
gitea:
  config:
    mailer:
      ENABLED: true
      FROM: gitea@yourdomain.com
      SMTP_ADDR: smtp.gmail.com
      SMTP_PORT: 587
      USER: your-email@gmail.com
      PASSWD: your-app-password
```

### Vaultwarden Email

Edit `manifests/vaultwarden/vaultwarden-helmchart.yaml`:

```yaml
vaultwarden:
  smtp:
    host: smtp.gmail.com
    port: 587
    from: vaultwarden@yourdomain.com
    username: your-email@gmail.com
    password: your-app-password
    security: starttls
```

For Gmail:
1. Enable 2FA on your Google account
2. Create an App Password: https://myaccount.google.com/apppasswords
3. Use the app password in the configuration

## Troubleshooting

### Gitea Not Starting

```bash
# Check logs
kubectl -n gitea logs -l app.kubernetes.io/name=gitea

# Check PostgreSQL
kubectl -n gitea get pods -l app.kubernetes.io/name=postgresql

# Check PVC
kubectl -n gitea describe pvc
```

### OAuth Not Working in Gitea

1. **Verify Client Secret**: Must match in both Authentik and Gitea
2. **Check Redirect URI**: Should be `https://gitea.local/user/oauth2/authentik/callback`
3. **Check Discovery URL**: `https://authentik.local/application/o/gitea/.well-known/openid-configuration`
4. **Check Logs**: Look at Gitea logs for OAuth errors

```bash
kubectl -n gitea logs -l app.kubernetes.io/name=gitea | grep -i oauth
```

### Vaultwarden Not Starting

```bash
# Check logs
kubectl -n vaultwarden logs -l app.kubernetes.io/name=vaultwarden

# Check PVC
kubectl -n vaultwarden describe pvc

# Port-forward to test directly
kubectl -n vaultwarden port-forward svc/vaultwarden 8080:80
# Access http://localhost:8080
```

### SSO Not Working in Vaultwarden

1. **Verify Client Secret**: Must match in both Authentik and Vaultwarden
2. **Check Authority URL**: Should end with `.well-known/openid-configuration`
3. **Check Logs**: Look at Vaultwarden logs for SSO errors

```bash
kubectl -n vaultwarden logs -l app.kubernetes.io/name=vaultwarden | grep -i sso
```

### Can't Access Applications

```bash
# Check ingress
kubectl -n gitea describe ingress
kubectl -n vaultwarden describe ingress

# Check certificates
kubectl -n gitea describe certificate gitea-tls
kubectl -n vaultwarden describe certificate vaultwarden-tls

# Check DNS resolution
nslookup gitea.local
nslookup vaultwarden.local
```

## Backup and Restore

### Gitea Backup

**Manual backup**:
```bash
# Exec into Gitea pod
kubectl -n gitea exec -it deployment/gitea -- /bin/bash

# Run backup
gitea dump -c /data/gitea/conf/app.ini

# Copy backup file out
kubectl -n gitea cp gitea-pod:/app/gitea-dump-*.zip ./gitea-backup.zip
```

**Automated backups**: Configure Longhorn backups (see PHASE2-LONGHORN.md)

### Vaultwarden Backup

**Database backup** (SQLite):
```bash
# The Longhorn PVC contains the entire vault
# Backup the PVC using Longhorn snapshots

# Or manually copy the database
kubectl -n vaultwarden exec -it deployment/vaultwarden -- \
  sqlite3 /data/db.sqlite3 ".backup '/data/backup.sqlite3'"

kubectl -n vaultwarden cp vaultwarden-pod:/data/backup.sqlite3 ./vaultwarden-backup.sqlite3
```

**Automated backups**: Configure Longhorn backups (see PHASE2-LONGHORN.md)

## Security Best Practices

1. **Change Default Passwords**: Update all passwords in HelmCharts
2. **Disable Signups**: After creating accounts, disable public signups
3. **Enable 2FA**: In Authentik, require 2FA for all users
4. **Regular Backups**: Configure Longhorn backups to S3/Backblaze
5. **Email Verification**: Enable email verification for new signups
6. **Admin Token Security**: Use strong random tokens for admin access
7. **Review Logs**: Check application logs regularly

## Advanced Configuration

### Gitea Actions with In-Cluster Runner

Uncomment in `manifests/gitea/gitea-helmchart.yaml`:

```yaml
gitea-actions-runner:
  enabled: true
  replicas: 1
```

This deploys a self-hosted Actions runner within the cluster.

### Vaultwarden with PostgreSQL

For better performance with many users, switch to PostgreSQL.

Edit `manifests/vaultwarden/vaultwarden-helmchart.yaml`:

```yaml
database:
  type: postgresql
  host: vaultwarden-postgresql
  port: 5432
  database: vaultwarden
  username: vaultwarden
  password: "changeme"

# Add PostgreSQL sub-chart
postgresql:
  enabled: true
  auth:
    username: vaultwarden
    password: changeme
    database: vaultwarden
  primary:
    persistence:
      enabled: true
      storageClass: longhorn
      size: 5Gi
```

### Custom Domains

To use real domains instead of `.local`:

1. Update ingress hostnames in HelmCharts
2. Update Authentik redirect URIs
3. Configure external DNS or update public DNS records
4. Update step-ca to issue certificates for your domains

## Next Phase

**Phase 7: Advanced Applications** will add:
- Home Assistant (smart home automation)
- Backup finalization
- Multi-node documentation
- NVIDIA/LLM support documentation

## Resources

- [Gitea Documentation](https://docs.gitea.com/)
- [Gitea Actions](https://docs.gitea.com/usage/actions/overview)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Bitwarden Help](https://bitwarden.com/help/)
- [Authentik OAuth Setup](https://goauthentik.io/docs/providers/oauth2/)
