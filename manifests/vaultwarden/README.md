# Vaultwarden Manifests

Phase 6: Bitwarden-compatible password manager with SSO support.

## Files

- **vaultwarden-helmchart.yaml**: k3s HelmChart manifest for Vaultwarden
  - Vaultwarden server with SQLite database
  - 5Gi Longhorn volume for vault storage
  - Automatic HTTPS via step-ca
  - SSO pre-configured for Authentik
  - Websocket support for real-time sync

## Auto-Deployment

Vaultwarden is automatically deployed by k3s on boot. The HelmChart is copied to `/var/lib/rancher/k3s/server/manifests/vaultwarden.yaml` in the bootc image.

## Configuration

- **Namespace**: `vaultwarden`
- **URL**: `https://vaultwarden.local`
- **Database**: SQLite (simple for home use)
- **Vault Storage**: 5Gi Longhorn volume
- **Signups**: Enabled by default (disable after creating accounts)

### Security

**Important**: Change these defaults before production use!

Edit `vaultwarden-helmchart.yaml`:
```yaml
vaultwarden:
  adminToken: "CHANGE-ME-TO-RANDOM-TOKEN"  # Change this!
  sso:
    clientSecret: "AUTHENTIK_CLIENT_SECRET"  # Replace with Authentik secret
```

Generate secure token:
```bash
openssl rand -base64 48  # For adminToken
```

## SSO Integration

**Automated!** The Vaultwarden OAuth provider is automatically configured via Authentik blueprints.

See [../../docs/PHASE6-APPLICATIONS.md](../../docs/PHASE6-APPLICATIONS.md#vaultwarden-configuration) for complete setup.

Quick steps:
1. Retrieve client secret from Authentik UI (auto-generated on first boot)
2. Update Vaultwarden HelmChart with the client secret
3. Rebuild or update the HelmChart
4. Users can log in to Vaultwarden with Authentik

## Accessing Vaultwarden

```bash
# Add to /etc/hosts
echo "192.168.1.x vaultwarden.local" | sudo tee -a /etc/hosts

# Open browser
https://vaultwarden.local
```

## Initial Setup

1. Go to `https://vaultwarden.local`
2. Create account (local) or sign in with Authentik SSO
3. Install browser extension or mobile app
4. Configure extension/app to use `https://vaultwarden.local`

## Browser Extensions

Vaultwarden is compatible with official Bitwarden extensions:

**Chrome/Edge**: https://chrome.google.com/webstore/detail/bitwarden/nngceckbapebfimnlniiiahkandclblb

**Firefox**: https://addons.mozilla.org/firefox/addon/bitwarden-password-manager/

**Configuration**:
1. Install extension
2. Click extension → Settings (gear icon)
3. Set **Server URL**: `https://vaultwarden.local`
4. Log in with Authentik SSO

## Mobile Apps

**iOS**: https://apps.apple.com/app/bitwarden-password-manager/id1137397744

**Android**: https://play.google.com/store/apps/details?id=com.x8bit.bitwarden

**Configuration**:
1. Install app
2. Tap **Region** → Self-hosted
3. Set **Server URL**: `https://vaultwarden.local`
4. Log in with Authentik SSO

## Admin Panel

Access admin panel at:
```
https://vaultwarden.local/admin
```

Use the `adminToken` configured in `vaultwarden-helmchart.yaml`.

## Email Configuration (Optional)

To enable email for password reset and notifications:

Edit `vaultwarden-helmchart.yaml`:
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

## Verification

```bash
# Check deployment
kubectl -n vaultwarden get pods

# Check storage
kubectl -n vaultwarden get pvc

# Check ingress
kubectl -n vaultwarden get ingress

# Check certificate
kubectl -n vaultwarden get certificate
```

## Backup

The vault is stored in a Longhorn PVC. Configure Longhorn backups to S3/Backblaze for regular backups.

Manual backup:
```bash
kubectl -n vaultwarden exec -it deployment/vaultwarden -- \
  sqlite3 /data/db.sqlite3 ".backup '/data/backup.sqlite3'"

kubectl -n vaultwarden cp vaultwarden-pod:/data/backup.sqlite3 ./vaultwarden-backup.sqlite3
```

## Documentation

See [../../docs/PHASE6-APPLICATIONS.md](../../docs/PHASE6-APPLICATIONS.md) for complete documentation.
