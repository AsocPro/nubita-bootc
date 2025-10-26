# step-certificates (step-ca) Manifests

Phase 3: Internal Certificate Authority for automatic TLS certificates.

## Files

- **step-ca-helmchart.yaml**: k3s HelmChart manifest for step-certificates
  - Auto-generates CA certificates on first run
  - Configures internal CA with sensible defaults
  - Persists CA data to Longhorn storage

- **clusterissuer.yaml**: ClusterIssuer connecting cert-manager to step-ca
  - Enables automatic certificate issuance
  - Cluster-wide scope

## Auto-Deployment

step-ca is automatically deployed by k3s on boot. Manifests are copied to `/var/lib/rancher/k3s/server/manifests/` in the bootc image.

## Configuration

- **Namespace**: `step-ca`
- **Root CA Validity**: 10 years
- **Intermediate CA Validity**: 5 years
- **Certificate Validity**: 24 hours (auto-renewed)
- **Storage**: Longhorn PVC (1Gi)

## Certificate Authority Bootstrap

On first deployment, step-ca automatically:
1. Generates root CA certificate
2. Generates intermediate CA certificate
3. Configures provisioners (JWK admin)
4. Stores CA in Longhorn persistent volume

## Verification

```bash
# Check deployment
kubectl -n step-ca get pods

# Check CA secrets
kubectl -n step-ca get secrets

# Get root CA certificate
kubectl -n step-ca get secret step-certificates-root-ca \
  -o jsonpath='{.data.root_ca\.crt}' | base64 -d

# Check ClusterIssuer
kubectl get clusterissuer step-ca
kubectl describe clusterissuer step-ca
```

## Using step-ca for TLS

Add annotation to your Ingress:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: step-ca
spec:
  tls:
  - hosts:
    - myservice.local
    secretName: myservice-tls
```

cert-manager will automatically request and manage the certificate.

## Documentation

See [../../docs/PHASE3-TLS.md](../../docs/PHASE3-TLS.md) for complete documentation.
