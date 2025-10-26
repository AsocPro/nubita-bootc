# Phase 5: Authentication with Authentik

## Overview

Phase 5 adds Authentik as the central authentication provider, enabling SSO (Single Sign-On) and LDAP for all services. Users can log in once and access all applications.

## Components

### Authentik
- Modern authentication provider
- OIDC/OAuth2 support for web applications
- LDAP support for legacy applications
- User and group management
- **Auto-deployed** via k3s Helm controller

### PostgreSQL
- Database for Authentik
- Persistent storage via Longhorn
- **Auto-deployed** with Authentik

### Redis
- Caching layer for Authentik
- Persistent storage via Longhorn
- **Auto-deployed** with Authentik

## Quick Start

**No manual steps needed!** Authentik is automatically deployed when the system boots.

1. Boot the bootc image
2. k3s deploys Authentik with PostgreSQL and Redis
3. Access Authentik at `https://authentik.local`
4. Complete initial setup wizard

## Accessing Authentik

```
https://authentik.local
```

**Setup DNS:**
```bash
# Add to /etc/hosts
echo "192.168.1.x authentik.local" | sudo tee -a /etc/hosts
```

## Automatic Configuration via Blueprints

This deployment uses **Authentik Blueprints** to automatically configure OAuth providers and applications. On first boot, Authentik will:

1. Create a Grafana OAuth2/OIDC provider with client ID `grafana`
2. Create a Grafana application linked to the provider
3. Auto-generate a secure client secret

This eliminates manual configuration steps! The blueprint is defined in `manifests/authentik/blueprint-configmap.yaml` and loaded via ConfigMap.

**What's automated:**
- OAuth provider creation
- Application registration
- Redirect URI configuration
- Scope mappings (openid, profile, email)

**What you still need to do:**
- Retrieve the auto-generated client secret from Authentik UI
- Update Grafana configuration with the secret

## Initial Setup

### First Login

On first access, Authentik will show a setup wizard:

1. **Create Admin User**
   - Email: `admin@authentik.local` (or your email)
   - Username: `admin`
   - Password: Choose a strong password

2. **Configure Basic Settings**
   - Domain: `authentik.local`
   - Branding (optional)

### Security Recommendations

**Important**: Change default passwords in `manifests/authentik/authentik-helmchart.yaml`:

```yaml
authentik:
  secret_key: "CHANGE-ME-TO-A-RANDOM-STRING-AT-LEAST-50-CHARS"
  postgresql:
    password: "CHANGE-ME"
```

Generate secure values:
```bash
# Generate secret key (50+ chars)
openssl rand -base64 48

# Generate PostgreSQL password
openssl rand -base64 32
```

Then rebuild the bootc image.

## Configuring SSO for Grafana

**Good news!** The Grafana OAuth provider is automatically configured via Authentik blueprints. You only need to retrieve the client secret and update Grafana.

### Step 1: Retrieve OAuth Client Secret

The OAuth provider and application are created automatically on first boot. To get the client secret:

1. Log in to Authentik at `https://authentik.local`
2. Go to **Applications** → **Providers**
3. Click on **Grafana** provider
4. Click **View details** to see the **Client Secret**
5. Copy the client secret

### Step 2: Update Grafana Configuration

Edit `manifests/kube-prometheus-stack/kube-prometheus-stack-helmchart.yaml` and replace the placeholder:

```yaml
grafana:
  grafana.ini:
    auth.generic_oauth:
      client_secret: "PASTE_YOUR_CLIENT_SECRET_HERE"
```

The OAuth configuration is already enabled, you just need to add the real client secret.

### Step 3: Rebuild and Redeploy

```bash
# Rebuild bootc image with updated secret
./scripts/build.sh

# Redeploy to apply changes
```

Or update the running HelmChart without rebuilding:
```bash
kubectl edit helmchart kube-prometheus-stack -n kube-system
# Update the client_secret value
```

### Step 4: Test SSO

1. Go to `https://grafana.local`
2. Click **Sign in with Authentik**
3. Authenticate with your Authentik credentials
4. You're logged in to Grafana!

## Creating Users and Groups

### Add Users

1. In Authentik, go to **Directory** → **Users**
2. Click **Create**
3. Fill in user details:
   - Username
   - Name
   - Email
   - Password (or let user set on first login)
4. Click **Create**

### Create Groups

1. Go to **Directory** → **Groups**
2. Click **Create**
3. Name: `admins` (for Grafana admin access)
4. Add users to the group
5. Click **Create**

### Assign Group Permissions

For Grafana role mapping:
- Users in `admins` group → Grafana Admin role
- Other users → Grafana Viewer role

This is configured in the `role_attribute_path` setting.

## LDAP Support

Authentik can provide LDAP for services that don't support OIDC.

### Create LDAP Provider

1. Go to **Applications** → **Providers**
2. Click **Create** → **LDAP Provider**
3. Configure:
   - Name: `LDAP`
   - Bind DN: `cn=ldap,ou=users,dc=ldap,dc=goauthentik,dc=io`
   - Base DN: `dc=ldap,dc=goauthentik,dc=io`
   - Search group: Select group for LDAP access
4. Note the **Bind password**

### Create Outpost

1. Go to **Applications** → **Outposts**
2. Click **Create**
3. Configure:
   - Name: `LDAP Outpost`
   - Type: `LDAP`
   - Applications: Select your LDAP application
4. Click **Create**

### Use LDAP in Applications

LDAP endpoint: `ldap://authentik-ldap:389`

Example configuration:
```yaml
ldap:
  host: authentik-ldap
  port: 389
  bind_dn: cn=ldap,ou=users,dc=ldap,dc=goauthentik,dc=io
  bind_password: YOUR_BIND_PASSWORD
  base_dn: dc=ldap,dc=goauthentik,dc=io
  user_filter: (objectClass=user)
```

## Email Configuration (Optional)

To enable password reset and notifications, configure email:

Edit `manifests/authentik/authentik-helmchart.yaml`:

```yaml
authentik:
  email:
    host: "smtp.gmail.com"
    port: 587
    username: "your-email@gmail.com"
    password: "your-app-password"
    use_tls: true
    from: "authentik@yourdomain.com"
```

For Gmail:
1. Enable 2FA on your Google account
2. Create an App Password: https://myaccount.google.com/apppasswords
3. Use the app password in the configuration

## Configuration

### Authentik Settings

Configured in `manifests/authentik/authentik-helmchart.yaml`:

- **Namespace**: `authentik`
- **URL**: `https://authentik.local`
- **Database**: PostgreSQL (5Gi Longhorn volume)
- **Cache**: Redis (1Gi Longhorn volume)
- **Metrics**: Prometheus ServiceMonitor enabled

### Resources

Optimized for home server:
- **Authentik Server**: 256Mi memory, 100m CPU (requests)
- **Authentik Worker**: 128Mi memory, 50m CPU (requests)
- **PostgreSQL**: 128Mi memory, 50m CPU (requests)
- **Redis**: 64Mi memory, 20m CPU (requests)

## Verification

### Check Deployment

```bash
# Check pods
kubectl -n authentik get pods

# Check PVCs
kubectl -n authentik get pvc

# Check ingress
kubectl -n authentik get ingress

# Check certificate
kubectl -n authentik get certificate
```

### Check PostgreSQL

```bash
# Port-forward to PostgreSQL
kubectl -n authentik port-forward svc/authentik-postgresql 5432:5432

# Connect (requires psql client)
PGPASSWORD=authentik psql -h localhost -U authentik -d authentik
```

### Check Logs

```bash
# Server logs
kubectl -n authentik logs -l app.kubernetes.io/component=server

# Worker logs
kubectl -n authentik logs -l app.kubernetes.io/component=worker
```

## Troubleshooting

### Authentik Not Starting

```bash
# Check server logs
kubectl -n authentik logs -l app.kubernetes.io/component=server

# Check PostgreSQL
kubectl -n authentik get pods -l app.kubernetes.io/name=postgresql

# Check secret_key is set
kubectl -n authentik get secret
```

### Can't Access Authentik UI

```bash
# Check ingress
kubectl -n authentik describe ingress

# Check certificate
kubectl -n authentik describe certificate authentik-tls

# Port-forward directly
kubectl -n authentik port-forward svc/authentik-server 9000:80
# Access http://localhost:9000
```

### OAuth Not Working

1. **Verify Client Secret**: Must match in both Authentik and Grafana
2. **Check Redirect URI**: Must match exactly (`https://grafana.local/login/generic_oauth`)
3. **Check Scopes**: Should include `openid`, `profile`, `email`
4. **Check Logs**: Look at Grafana logs for OAuth errors

```bash
kubectl -n monitoring logs -l app.kubernetes.io/name=grafana | grep -i oauth
```

### Database Connection Issues

```bash
# Check PostgreSQL service
kubectl -n authentik get svc authentik-postgresql

# Check connection from Authentik pod
kubectl -n authentik exec -it deployment/authentik-server -- \
  sh -c 'pg_isready -h authentik-postgresql -U authentik'
```

## Integration Examples

### Future Services (Phase 6)

When deploying Gitea and Vaultwarden:

**Gitea**: Configure OIDC
```yaml
oauth2:
  enabled: true
  provider: authentik
  client_id: gitea
  client_secret: SECRET
  openid_connect_auto_discovery_url: https://authentik.local/application/o/gitea/.well-known/openid-configuration
```

**Vaultwarden**: Use LDAP
```yaml
ldap:
  enabled: true
  host: authentik-ldap
  port: 389
  bind_dn: cn=ldap,ou=users,dc=ldap,dc=goauthentik,dc=io
  bind_password: PASSWORD
```

## Security Best Practices

1. **Change Default Passwords**: Update `secret_key`, PostgreSQL password
2. **Enable 2FA**: In Authentik settings, require 2FA for admin users
3. **Limit Access**: Use groups to control application access
4. **Regular Backups**: PostgreSQL data is in Longhorn - configure backups
5. **Email Configuration**: Enable for password reset and notifications
6. **Review Logs**: Check Authentik logs regularly for suspicious activity

## Advanced Configuration

### Custom Branding

1. Go to **System** → **Tenants**
2. Edit the default tenant
3. Upload logo and favicon
4. Customize colors and theme

### Password Policies

1. Go to **Customization** → **Policies**
2. Create **Password Policy**
3. Configure:
   - Minimum length
   - Require uppercase, lowercase, digits, symbols
   - Password age
   - Password history

### MFA Configuration

1. Go to **Flows & Stages** → **Stages**
2. Find **default-authentication-mfa-validation**
3. Configure available MFA methods:
   - TOTP (Google Authenticator, etc.)
   - WebAuthn (YubiKey, etc.)
   - Static tokens

## Next Phase

After configuring Authentik, all future services can use SSO!

**Phase 6: Core Applications** will add:
- Gitea (with Authentik SSO)
- Vaultwarden (with Authentik SSO/LDAP)

## Resources

- [Authentik Documentation](https://goauthentik.io/docs/)
- [OAuth2/OIDC Provider](https://goauthentik.io/docs/providers/oauth2/)
- [LDAP Provider](https://goauthentik.io/docs/providers/ldap/)
- [Grafana OAuth Guide](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/generic-oauth/)
