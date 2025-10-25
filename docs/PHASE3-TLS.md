# Phase 3: Networking and Security with TLS

## Overview

Phase 3 adds automatic TLS certificate management using step-ca (internal Certificate Authority) and cert-manager. All services get automatic HTTPS with trusted certificates.

## Components

### cert-manager
- Kubernetes certificate controller
- Automatically issues and renews certificates
- Integrates with various CA backends
- **Auto-deployed** via k3s Helm controller

### step-certificates (step-ca)
- Internal Certificate Authority
- Issues trusted certificates for cluster services
- Automatic certificate rotation
- **Auto-deployed** via k3s Helm controller

### ClusterIssuer
- Connects cert-manager to step-ca
- Enables automatic certificate issuance
- **Auto-deployed** via k3s

## Quick Start

**No manual steps needed!** Everything is automatically deployed when the system boots.

1. Boot the bootc image
2. k3s deploys cert-manager, step-ca, and ClusterIssuer
3. Services automatically get TLS certificates
4. Access services via HTTPS

## How It Works

### Deployment Flow

1. **k3s starts** and scans `/var/lib/rancher/k3s/server/manifests/`
2. **cert-manager deploys** first (with CRDs)
3. **step-ca deploys** and initializes internal CA
4. **ClusterIssuer** connects cert-manager to step-ca
5. **Services** (like Longhorn UI) request certificates
6. **cert-manager** automatically issues certs from step-ca
7. **Traefik** serves HTTPS with automatic certificates

### Certificate Lifecycle

```
Service → Ingress (with cert-manager annotation)
         ↓
cert-manager sees annotation
         ↓
Requests certificate from step-ca ClusterIssuer
         ↓
step-ca issues certificate (24h validity)
         ↓
cert-manager stores cert in Secret
         ↓
Traefik uses cert for HTTPS
         ↓
cert-manager auto-renews before expiry
```

## Accessing Services

### Longhorn UI

After Phase 3 deployment, Longhorn UI is available at:

```
https://longhorn.local
```

**Setup DNS:**

Option 1: Add to `/etc/hosts`:
```bash
echo "192.168.1.x longhorn.local" | sudo tee -a /etc/hosts
```

Option 2: Use local DNS server (dnsmasq, Pi-hole, etc.)

### Trust the CA Certificate

To avoid browser warnings, trust the step-ca root certificate:

```bash
# Get the root CA certificate
kubectl -n step-ca get secret step-certificates-root-ca -o jsonpath='{.data.root_ca\.crt}' | base64 -d > step-ca-root.crt

# Import to system trust store (Fedora/RHEL)
sudo cp step-ca-root.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# Or import to browser (Firefox, Chrome, etc.)
```

## Configuration

### cert-manager Settings

Configured in `manifests/cert-manager/helmchart.yaml`:

- **CRDs**: Installed automatically
- **Resources**: Minimal (suitable for home server)
- **Prometheus**: Metrics enabled for monitoring
- **Namespace**: `cert-manager`

### step-ca Settings

Configured in `manifests/step-ca/helmchart.yaml`:

- **Root CA Validity**: 10 years
- **Intermediate CA Validity**: 5 years
- **Certificate Validity**: 24 hours (auto-renewed)
- **Persistence**: Uses Longhorn (1Gi volume)
- **Namespace**: `step-ca`

### ClusterIssuer

Configured in `manifests/step-ca/clusterissuer.yaml`:

- **Name**: `step-ca`
- **Type**: CA issuer
- **Scope**: Cluster-wide (all namespaces)

## Adding TLS to Services

To enable automatic TLS for any service:

### Option 1: Ingress Annotation

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  annotations:
    cert-manager.io/cluster-issuer: step-ca
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - myservice.local
    secretName: my-service-tls
  rules:
  - host: myservice.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

### Option 2: Certificate Resource

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-cert
  namespace: default
spec:
  secretName: my-cert-tls
  issuerRef:
    name: step-ca
    kind: ClusterIssuer
  dnsNames:
  - myservice.local
  - myservice.example.com
```

## Verification

### Check cert-manager

```bash
# Check pods
kubectl -n cert-manager get pods

# Check CRDs
kubectl get crds | grep cert-manager

# Check logs
kubectl -n cert-manager logs -l app=cert-manager
```

### Check step-ca

```bash
# Check pods
kubectl -n step-ca get pods

# Check CA secrets
kubectl -n step-ca get secrets

# Check CA service
kubectl -n step-ca get svc
```

### Check ClusterIssuer

```bash
# View ClusterIssuer
kubectl get clusterissuer step-ca -o yaml

# Check status
kubectl describe clusterissuer step-ca
```

### Check Certificates

```bash
# List all certificates
kubectl get certificates --all-namespaces

# Check Longhorn UI certificate
kubectl -n longhorn-system get certificate

# Describe certificate
kubectl -n longhorn-system describe certificate longhorn-ui-tls
```

## Troubleshooting

### cert-manager Not Installing CRDs

```bash
# Manually install CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
```

### step-ca Pod Not Starting

```bash
# Check logs
kubectl -n step-ca logs -l app.kubernetes.io/name=step-certificates

# Check PVC
kubectl -n step-ca get pvc

# Ensure Longhorn is ready
kubectl -n longhorn-system get pods
```

### Certificates Not Issuing

```bash
# Check cert-manager logs
kubectl -n cert-manager logs -l app=cert-manager

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check certificaterequest
kubectl get certificaterequest --all-namespaces

# Check order and challenge (if using ACME)
kubectl get orders,challenges --all-namespaces
```

### Browser Certificate Warnings

This is normal if you haven't imported the step-ca root certificate. Either:

1. Import the root CA to your system/browser trust store
2. Accept the browser warning (for local development)
3. Use a public CA (Let's Encrypt) for external access

## Future Phases

### Phase 4: Monitoring
- Grafana with step-ca TLS
- Prometheus with step-ca TLS

### Phase 5: Authentication
- Authentik with step-ca TLS

### Phase 6: Applications
- Gitea with step-ca TLS
- Vaultwarden with step-ca TLS

All services will automatically get HTTPS!

## External Access (Optional)

For external access with public certificates:

### Option 1: Use Let's Encrypt

Create an ACME ClusterIssuer:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
    - http01:
        ingress:
          class: traefik
```

Then use `cert-manager.io/cluster-issuer: letsencrypt` in ingress annotations.

### Option 2: Use Cloudflare Tunnel

Expose services without opening ports:

```bash
# Deploy cloudflared
kubectl create secret generic cloudflare-tunnel \
  --from-literal=token=YOUR_TUNNEL_TOKEN \
  -n default

# Still use step-ca for internal TLS
# Cloudflare handles external TLS
```

## Resources

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [step-ca Documentation](https://smallstep.com/docs/step-ca)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
