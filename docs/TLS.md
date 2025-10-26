# TLS Configuration - Future Implementation

> **Status**: TLS is currently **disabled** for all services. All services are accessible over HTTP only.
>
> **Reason**: The `.local` domain used for services cannot be reliably resolved inside the Kubernetes cluster, causing cert-manager's HTTP-01 ACME challenges to fail. This needs to be addressed before TLS can be enabled.

---

## Current State

All services are accessible over HTTP without encryption:
- http://longhorn.local
- http://grafana.local
- http://prometheus.local
- http://alertmanager.local
- http://authentik.local
- http://gitea.local
- http://vaultwarden.local

**Security Note**: This is acceptable for a home lab environment behind a local network, but TLS should be enabled before exposing any services to the internet or for production use.

---

## The Problem

The current setup uses:
- **Domain**: `.local` TLD (e.g., `longhorn.local`, `gitea.local`)
- **Certificate Manager**: cert-manager with step-ca ACME provisioner
- **Challenge Type**: HTTP-01 ACME challenges

**Why it fails**:
1. `.local` domains are meant for mDNS (Multicast DNS / Bonjour), not traditional DNS
2. The domains are only in `/etc/hosts` on the host machine
3. cert-manager running inside the cluster cannot resolve `.local` domains via CoreDNS
4. HTTP-01 challenges require cert-manager to perform a self-check by resolving and fetching the challenge URL
5. DNS lookup fails: `dial tcp: lookup longhorn.local on 10.43.0.10:53: no such host`

**What we tried**:
- Adding custom CoreDNS configuration for `.local` domains
  - Failed: Conflicts with the existing `hosts` plugin in CoreDNS
  - Failed: Creating a separate `.local` zone breaks cluster DNS (`.svc.cluster.local`)
- step-ca with ACME provisioner is working correctly
- ClusterIssuer is registered and ready
- The issue is purely DNS resolution during HTTP-01 challenge validation

---

## Future Solutions

### Option 1: Use a Real Domain with DNS-01 Challenges (RECOMMENDED)

**Best practice for production-like home labs**

**Setup**:
1. Register a real domain (e.g., `yourhomelab.com`, `home.example.com`)
   - Can use free services like FreeDNS, DuckDNS, or cheap registrars
2. Configure cert-manager to use DNS-01 challenges instead of HTTP-01
3. Set up DNS provider credentials (Cloudflare, Route53, etc.)
4. Point DNS records to your home IP or use split-horizon DNS

**Pros**:
- Works perfectly with internal `.local` hostnames
- No DNS resolution issues in the cluster
- Can use wildcard certificates (`*.yourhomelab.com`)
- Can expose services externally with proper DNS
- Industry best practice

**Cons**:
- Requires registering a domain (cost: $0-15/year)
- Slightly more complex DNS provider setup
- Need to manage external DNS records

**Implementation**:
```yaml
# Example ClusterIssuer with DNS-01
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: step-ca
spec:
  acme:
    server: https://step-certificates.step-ca.svc.cluster.local/acme/acme/directory
    email: admin@yourhomelab.com
    privateKeySecretRef:
      name: step-ca-acme-account
    skipTLSVerify: true
    solvers:
    - dns01:
        cloudflare:  # or route53, digitalocean, etc.
          email: your-email@example.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

---

### Option 2: Use `.home.arpa` Domain (RFC 8375 Compliant)

**Proper standard for home networks**

**Setup**:
1. Change all service domains from `.local` to `.home.arpa`
   - `longhorn.local` → `longhorn.home.arpa`
   - `gitea.local` → `gitea.home.arpa`
2. Add `.home.arpa` DNS entries to CoreDNS
3. Update `/etc/hosts` on client machines

**Pros**:
- RFC 8375 standard for home networks
- Doesn't conflict with mDNS like `.local`
- Easier to configure in CoreDNS without conflicts
- Still fully internal, no external domain needed

**Cons**:
- Requires changing all existing configurations
- Less familiar than `.local` to users
- Still need to solve CoreDNS configuration

**Implementation**:
```yaml
# CoreDNS ConfigMap addition
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  home-arpa.server: |
    home.arpa:53 {
        errors
        cache 30
        hosts {
            192.168.1.181 longhorn.home.arpa
            192.168.1.181 grafana.home.arpa
            192.168.1.181 prometheus.home.arpa
            192.168.1.181 alertmanager.home.arpa
            192.168.1.181 authentik.home.arpa
            192.168.1.181 gitea.home.arpa
            192.168.1.181 vaultwarden.home.arpa
            fallthrough
        }
    }
```

---

### Option 3: External DNS Server + ExternalDNS Controller

**Automated DNS management for home labs**

**Setup**:
1. Run a DNS server on your network (Pi-hole, AdGuard Home, Bind9, CoreDNS)
2. Deploy ExternalDNS controller in the cluster
3. ExternalDNS automatically creates DNS records from Ingress resources
4. Point cluster nodes to use your DNS server

**Pros**:
- Fully automated DNS record management
- Works with existing `.local` domains
- Services automatically get DNS entries
- Scales to many services easily
- Can integrate with home network DNS (Pi-hole, etc.)

**Cons**:
- Requires running additional infrastructure (DNS server)
- More complex initial setup
- Need to configure DNS server API access

**Implementation**:
```yaml
# ExternalDNS deployment example
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  template:
    spec:
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.14.0
        args:
        - --source=ingress
        - --provider=coredns
        - --domain-filter=local  # Only manage .local domains
        - --coredns-prefix=/skydns/
```

**Recommended DNS Servers**:
- **Pi-hole**: Popular ad-blocking DNS with web UI
- **AdGuard Home**: Modern alternative to Pi-hole
- **CoreDNS**: Lightweight, Kubernetes-native
- **Bind9**: Traditional, powerful DNS server

---

### Option 4: Cluster-Internal Certificates Only

**Simplest, but limited**

**Setup**:
1. Access services via `servicename.namespace.svc.cluster.local`
2. Use port-forwarding: `kubectl port-forward -n gitea svc/gitea 3000:3000`
3. Or use ingress without custom domains

**Pros**:
- No DNS configuration needed
- Certificates work perfectly
- Simple to set up

**Cons**:
- No friendly domain names
- Requires port-forwarding or ingress configuration
- Less convenient for daily use
- Doesn't work well with OAuth redirects

---

### Option 5: Self-Signed Certificates Without ACME

**Skip ACME entirely**

**Setup**:
1. Generate self-signed certificates manually
2. Create Kubernetes TLS secrets
3. Trust the CA certificate on client machines
4. Skip cert-manager HTTP-01 challenges

**Pros**:
- No DNS required
- Full control over certificates
- Works with any domain

**Cons**:
- Manual certificate management
- Browser warnings (need to trust CA)
- Certificates don't auto-renew
- Not suitable for external access

---

## Recommended Approach

For this home lab, I recommend **Option 1 (Real Domain with DNS-01)** for the following reasons:

1. **Future-proof**: Works now and scales to external access later
2. **Industry standard**: Same setup used in production environments
3. **Automatic renewal**: cert-manager handles everything
4. **Clean URLs**: Can use `gitea.home.example.com` instead of `gitea.local`
5. **Low cost**: Domains are $10-15/year, or free with some providers

**Quick Start**:
- Register a domain from Cloudflare, Namecheap, or use DuckDNS (free)
- Use Cloudflare DNS with API tokens (easy cert-manager integration)
- Configure DNS-01 challenges in ClusterIssuer
- Enjoy automatic TLS for all services!

---

## Migration Plan (When Ready)

When you're ready to enable TLS, follow these steps:

1. **Choose a solution** from the options above
2. **Set up DNS** (if using external domain or DNS server)
3. **Update ClusterIssuer** with new challenge type
4. **Update HelmChart values** to re-enable TLS:
   - Uncomment `ingress.tls` sections
   - Add `cert-manager.io/cluster-issuer: step-ca` annotations
5. **Test one service** (start with Longhorn)
6. **Roll out to all services** once verified
7. **Update CLAUDE.md** with the TLS solution

---

## Files to Modify When Enabling TLS

All HelmChart files in `manifests/`:
- `longhorn/longhorn-helmchart.yaml`
- `kube-prometheus-stack/kube-prometheus-stack-helmchart.yaml` (Grafana, Prometheus, Alertmanager)
- `gitea/gitea-helmchart.yaml`
- `vaultwarden/vaultwarden-helmchart.yaml`
- Any future services added

**Pattern to re-enable**:
```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: step-ca  # Add this back
  hosts:
    - host: service.local  # Or new domain
      paths:
        - path: /
  tls:  # Uncomment this section
    - secretName: service-tls
      hosts:
        - service.local
```

---

## Resources

- [cert-manager DNS-01 challenges](https://cert-manager.io/docs/configuration/acme/dns01/)
- [RFC 8375 - Special-Use Domain 'home.arpa'](https://www.rfc-editor.org/rfc/rfc8375.html)
- [ExternalDNS Documentation](https://github.com/kubernetes-sigs/external-dns)
- [Cloudflare + cert-manager Guide](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/)
- [Pi-hole + ExternalDNS](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/pihole.md)

---

**Last Updated**: 2025-10-26
**Status**: TLS disabled, pending future implementation
