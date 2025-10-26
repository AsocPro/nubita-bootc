# Nubita Bootc - Project Reference Guide

> **Purpose**: This document serves as a reference for AI assistants and developers working on this project. It outlines the project structure, architectural decisions, established patterns, and guidance for making consistent changes.

## Project Overview

**Nubita Bootc** is an immutable, bootc-based OS image hosting a k3s Kubernetes cluster for home server use. The platform emphasizes:
- **GitOps**: All services auto-deploy via k3s Helm controller
- **Immutability**: Atomic updates and rollbacks via ostree
- **Modularity**: Swappable base images and optional components
- **Automation**: Automatic TLS, OAuth configuration, and deployment

**Base Specification**: See [docs/initialSpec.md](docs/initialSpec.md) for complete requirements.

---

## Project Status

### Completed Phases (1-6)

All core infrastructure is complete and ready for deployment:

| Phase | Component | Status | Key Files |
|-------|-----------|--------|-----------|
| **1** | k3s Cluster | ✅ Complete | `Containerfile`, `config/k3s-config.yaml` |
| **2** | Longhorn Storage | ✅ Complete | `manifests/longhorn/longhorn-helmchart.yaml` |
| **3** | TLS (cert-manager + step-ca) | ✅ Complete | `manifests/cert-manager/`, `manifests/step-ca/` |
| **4** | Monitoring (Prometheus/Grafana) | ✅ Complete | `manifests/kube-prometheus-stack/` |
| **5** | SSO/LDAP (Authentik) | ✅ Complete | `manifests/authentik/` |
| **6** | Applications (Gitea/Vaultwarden) | ✅ Complete | `manifests/gitea/`, `manifests/vaultwarden/` |

### Phase 7: Advanced Features (Future)

Planned but not yet implemented:
- Home Assistant deployment
- Backup finalization and automation
- Multi-node k3s cluster documentation
- NVIDIA/LLM GPU support
- ARM architecture support

---

## Architecture & Design Decisions

### 1. GitOps-Based Deployment

**Decision**: Use k3s Helm controller for automatic deployment instead of manual scripts.

**Pattern**:
```dockerfile
# Containerfile
COPY manifests/<service>/<service>-helmchart.yaml /var/lib/rancher/k3s/server/manifests/<service>.yaml
```

**Benefits**:
- Services deploy automatically on first boot
- Declarative configuration
- No manual intervention needed
- Consistent deployment process

**Files**: All services use HelmChart CRDs in `/var/lib/rancher/k3s/server/manifests/`

### 2. Automatic OAuth Configuration via Blueprints

**Decision**: Use Authentik blueprints to auto-create OAuth providers instead of manual setup.

**Pattern**:
```yaml
# manifests/authentik/blueprint-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: authentik-blueprints
  namespace: authentik
data:
  <service>-oauth.yaml: |
    version: 1
    metadata:
      labels:
        blueprints.goauthentik.io/instantiate: "true"
    entries:
      - model: authentik_providers_oauth2.oauth2provider
        identifiers:
          name: <Service>
        attrs:
          client_id: <service>
          # Client secret auto-generated
```

**Current Providers**: Grafana, Gitea, Vaultwarden (auto-created on first boot)

**User Workflow**:
1. Boot system → Authentik creates OAuth providers automatically
2. Retrieve auto-generated client secrets from Authentik UI
3. Update service configurations with secrets
4. SSO works!

### 3. Automatic TLS for All Services

**Decision**: Use cert-manager + step-ca for automatic certificate issuance.

**Pattern**:
```yaml
# In any service's ingress configuration
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: step-ca
  tls:
    - secretName: <service>-tls
      hosts:
        - <service>.local
```

**Benefits**:
- All services get HTTPS automatically
- Certificates auto-renew (24-hour validity)
- Internal CA (step-ca) for home use
- No manual certificate management

### 4. Ostree Filesystem Compatibility

**Critical Decision**: Install binaries to `/usr/bin` instead of `/usr/local/bin`.

**Reason**: In ostree systems, `/usr/local` is a symlink to `/var/usrlocal`, causing issues with directory creation.

**Pattern**:
```dockerfile
# Containerfile
# ✅ Correct
INSTALL_K3S_BIN_DIR=/usr/bin

# ❌ Wrong (fails in ostree)
INSTALL_K3S_BIN_DIR=/usr/local/bin
```

**Applies to**: k3s, goss, custom scripts

### 5. SELinux in Container Builds

**Decision**: Skip SELinux operations during container build; let systemd handle at runtime.

**Pattern**:
```dockerfile
# Containerfile
RUN curl -sfL ${K3S_INSTALL_SCRIPT_URL} | \
    INSTALL_K3S_SKIP_SELINUX_RPM=true \
    sh -
```

**Reason**: SELinux contexts cannot be applied inside container builds; they're applied at boot time by systemd.

### 6. File Naming Convention

**Decision**: Use descriptive, unique names for all HelmChart manifests.

**Pattern**:
- ✅ `<service>-helmchart.yaml` (e.g., `gitea-helmchart.yaml`)
- ❌ `helmchart.yaml` (generic, causes conflicts)

**Benefit**: All manifests can coexist in one directory without name collisions.

---

## Project Structure

```
nubita-bootc/
├── Containerfile                    # Main bootc image definition
├── config/
│   ├── k3s-config.yaml             # k3s server configuration
│   └── goss.yaml                   # Health check definitions (60+ tests)
├── scripts/
│   ├── build.sh                    # Build automation
│   └── healthcheck.sh              # Goss wrapper with retry logic
├── systemd/
│   └── k3s.service                 # k3s systemd unit
├── manifests/
│   ├── longhorn/
│   │   ├── longhorn-helmchart.yaml           # Phase 2: Storage
│   │   ├── backup-secret.yaml.example
│   │   └── README.md
│   ├── cert-manager/
│   │   ├── cert-manager-helmchart.yaml       # Phase 3: TLS
│   │   └── README.md
│   ├── step-ca/
│   │   ├── step-ca-helmchart.yaml            # Phase 3: CA
│   │   ├── clusterissuer.yaml
│   │   └── README.md
│   ├── kube-prometheus-stack/
│   │   ├── kube-prometheus-stack-helmchart.yaml  # Phase 4: Monitoring
│   │   └── README.md
│   ├── authentik/
│   │   ├── authentik-helmchart.yaml          # Phase 5: SSO
│   │   ├── blueprint-configmap.yaml          # OAuth auto-config
│   │   ├── blueprint-grafana.yaml            # Reference copy
│   │   └── README.md
│   ├── gitea/
│   │   ├── gitea-helmchart.yaml              # Phase 6: Git hosting
│   │   └── README.md
│   └── vaultwarden/
│       ├── vaultwarden-helmchart.yaml        # Phase 6: Password manager
│       └── README.md
└── docs/
    ├── BUILD.md                    # Build and deployment guide
    ├── HEALTH-CHECKS.md            # Health check system documentation
    ├── PHASE2-LONGHORN.md          # Storage setup
    ├── PHASE3-TLS.md               # TLS configuration
    ├── PHASE4-MONITORING.md        # Monitoring setup
    ├── PHASE5-AUTHENTIK.md         # SSO/LDAP setup
    ├── PHASE6-APPLICATIONS.md      # Gitea and Vaultwarden
    └── initialSpec.md              # Original specification
```

---

## Established Patterns

### Adding a New Service

When adding new applications to the platform, follow this pattern:

1. **Create HelmChart Manifest**:
   ```bash
   mkdir -p manifests/<service>
   touch manifests/<service>/<service>-helmchart.yaml
   ```

2. **Configure Automatic TLS**:
   ```yaml
   ingress:
     enabled: true
     annotations:
       cert-manager.io/cluster-issuer: step-ca
     hosts:
       - <service>.local
     tls:
       - secretName: <service>-tls
         hosts:
           - <service>.local
   ```

3. **Add Longhorn Storage** (if needed):
   ```yaml
   persistence:
     enabled: true
     storageClass: longhorn
     size: <size>Gi
   ```

4. **Create OAuth Blueprint** (if SSO needed):
   - Add entry to `manifests/authentik/blueprint-configmap.yaml`
   - Follow pattern from existing providers (Grafana, Gitea, Vaultwarden)

5. **Update Containerfile**:
   ```dockerfile
   COPY manifests/<service>/<service>-helmchart.yaml /var/lib/rancher/k3s/server/manifests/<service>.yaml
   ```

6. **Add Health Checks**:
   - Update `config/goss.yaml` with service validation tests
   - Follow pattern: namespace, pods, PVCs, ingress, certificates

7. **Create Documentation**:
   - `manifests/<service>/README.md` - Quick reference
   - `docs/PHASE<N>-<SERVICE>.md` - Complete guide

### Modifying Existing Services

**Pattern**: Edit the HelmChart file, then rebuild or update:

```bash
# Option 1: Rebuild bootc image (immutable approach)
./scripts/build.sh
sudo bootc switch --transport=oci localhost/nubita-bootc:latest
sudo systemctl reboot

# Option 2: Hot-update (testing only)
kubectl edit helmchart <service> -n kube-system
```

**Important**: Always update documentation when changing configurations.

---

## Key Technologies & Versions

| Component | Version | Pin Location |
|-----------|---------|--------------|
| k3s | v1.31.4+k3s1 | `Containerfile` (ARG K3S_VERSION) |
| goss | v0.4.8 | `Containerfile` (ARG GOSS_VERSION) |
| Base Image | latest | `Containerfile` (ARG BASE_IMAGE) |
| Longhorn | latest (Helm) | `manifests/longhorn/longhorn-helmchart.yaml` |
| cert-manager | latest (Helm) | `manifests/cert-manager/cert-manager-helmchart.yaml` |
| step-ca | latest (Helm) | `manifests/step-ca/step-ca-helmchart.yaml` |
| kube-prometheus-stack | latest (Helm) | `manifests/kube-prometheus-stack/kube-prometheus-stack-helmchart.yaml` |
| Authentik | latest (Helm) | `manifests/authentik/authentik-helmchart.yaml` |
| Gitea | latest (Helm) | `manifests/gitea/gitea-helmchart.yaml` |
| Vaultwarden | latest (Helm) | `manifests/vaultwarden/vaultwarden-helmchart.yaml` |

**Version Pinning**: k3s and goss are pinned. Helm charts use latest (can be pinned in HelmChart spec if needed).

---

## Important Configuration Files

### Containerfile

**Purpose**: Defines the bootc image layers and deployment.

**Key Sections**:
- Base image selection (swappable)
- k3s installation (pinned version, ostree-compatible)
- Goss installation for health checks
- HelmChart manifest copying (GitOps deployment)
- systemd service enablement

**Customization Points**:
- `ARG BASE_IMAGE`: Change base (ublue-os, AlmaLinux, etc.)
- `ARG K3S_VERSION`: Pin k3s version
- NVIDIA support: Uncomment GPU layers
- Custom CA: Uncomment CA certificate layer

### config/k3s-config.yaml

**Purpose**: k3s server configuration.

**Current Settings**:
- Cluster CIDR: 10.42.0.0/16
- Service CIDR: 10.43.0.0/16
- Traefik disabled (using default)
- Metrics server enabled

### config/goss.yaml

**Purpose**: Comprehensive health validation (60+ tests).

**Coverage**:
- Phase 1: k3s cluster, API, nodes, DNS
- Phase 2: Longhorn storage, PVCs
- Phase 3: cert-manager, step-ca, certificates
- Phase 4: Prometheus, Grafana, Alertmanager
- Phase 5: Authentik, PostgreSQL, Redis, blueprints
- Phase 6: Gitea, Vaultwarden, databases
- Infrastructure: All ingresses, HelmCharts

**Usage**:
```bash
/usr/bin/healthcheck.sh                 # Standard check
/usr/bin/healthcheck.sh --verbose       # Detailed output
/usr/bin/healthcheck.sh --format json   # For monitoring
/usr/bin/healthcheck.sh --retries 5     # With retry logic
```

---

## Common Tasks

### Build the Image

```bash
./scripts/build.sh

# With custom version
K3S_VERSION=v1.32.0+k3s1 ./scripts/build.sh

# With custom base
BASE_IMAGE=quay.io/fedora/fedora-bootc:41 ./scripts/build.sh
```

### Run Health Checks

```bash
# After boot, wait 5-10 minutes for services to start
/usr/bin/healthcheck.sh --retries 5 --retry-delay 30
```

### Update a Service Configuration

```bash
# 1. Edit the HelmChart
vim manifests/<service>/<service>-helmchart.yaml

# 2. Rebuild image
./scripts/build.sh

# 3. Deploy new image
sudo bootc switch --transport=oci localhost/nubita-bootc:latest
sudo systemctl reboot
```

### Add OAuth for New Service

```bash
# 1. Edit blueprint ConfigMap
vim manifests/authentik/blueprint-configmap.yaml

# 2. Add new OAuth provider entry (copy existing pattern)

# 3. Rebuild and deploy

# 4. Retrieve client secret from Authentik UI after boot

# 5. Update service configuration with secret
```

### Verify Deployment

```bash
# Check all namespaces
kubectl get ns

# Check all pods
kubectl get pods -A

# Check HelmCharts
kubectl get helmchart -n kube-system

# Check certificates
kubectl get certificate -A

# Check ingresses
kubectl get ingress -A
```

---

## Security Considerations

### Default Passwords (MUST CHANGE)

These files contain default passwords that **must be changed** before production:

1. **Grafana**: `manifests/kube-prometheus-stack/kube-prometheus-stack-helmchart.yaml`
   - `adminPassword: admin`

2. **Authentik**: `manifests/authentik/authentik-helmchart.yaml`
   - `secret_key: "change-me..."`
   - PostgreSQL password: `authentik`

3. **Gitea**: `manifests/gitea/gitea-helmchart.yaml`
   - Admin password: `changeme`
   - PostgreSQL password: `gitea`
   - SECRET_KEY and INTERNAL_TOKEN

4. **Vaultwarden**: `manifests/vaultwarden/vaultwarden-helmchart.yaml`
   - `adminToken: "CHANGE-ME..."`

**Generate Secure Values**:
```bash
openssl rand -base64 48  # For SECRET_KEY, tokens
openssl rand -base64 32  # For passwords
```

### OAuth Client Secrets

OAuth client secrets are **auto-generated** by Authentik blueprints. Retrieve them from:
- Authentik UI → Applications → Providers → [Service] → View Details

These need to be manually added to service configurations (Grafana, Gitea, Vaultwarden).

---

## Deployment Endpoints

After successful deployment, these services are accessible:

| Service | URL | Purpose |
|---------|-----|---------|
| Longhorn | https://longhorn.local | Storage management |
| Grafana | https://grafana.local | Monitoring dashboards |
| Prometheus | https://prometheus.local | Metrics database |
| Alertmanager | https://alertmanager.local | Alert management |
| Authentik | https://authentik.local | SSO/LDAP provider |
| Gitea | https://gitea.local | Git hosting |
| Vaultwarden | https://vaultwarden.local | Password manager |

**DNS Setup**:
```bash
# Add to /etc/hosts
echo "192.168.1.x longhorn.local" | sudo tee -a /etc/hosts
echo "192.168.1.x grafana.local" | sudo tee -a /etc/hosts
echo "192.168.1.x prometheus.local" | sudo tee -a /etc/hosts
echo "192.168.1.x alertmanager.local" | sudo tee -a /etc/hosts
echo "192.168.1.x authentik.local" | sudo tee -a /etc/hosts
echo "192.168.1.x gitea.local" | sudo tee -a /etc/hosts
echo "192.168.1.x vaultwarden.local" | sudo tee -a /etc/hosts
```

---

## Troubleshooting Patterns

### Service Not Starting

```bash
# 1. Check pod status
kubectl -n <namespace> get pods

# 2. Check pod logs
kubectl -n <namespace> logs -l app.kubernetes.io/name=<service>

# 3. Check HelmChart status
kubectl -n kube-system get helmchart <service> -o yaml

# 4. Check events
kubectl -n <namespace> get events --sort-by='.lastTimestamp'
```

### Certificate Not Issuing

```bash
# Check certificate status
kubectl -n <namespace> describe certificate <service>-tls

# Check cert-manager logs
kubectl -n cert-manager logs -l app=cert-manager

# Check ClusterIssuer
kubectl get clusterissuer step-ca -o yaml
```

### PVC Not Binding

```bash
# Check PVC status
kubectl -n <namespace> get pvc

# Check Longhorn status
kubectl -n longhorn-system get pods

# Check Longhorn UI
open https://longhorn.local
```

---

## Future Considerations

### Multi-Node Expansion

The platform is designed for single-node but can expand to multi-node:

1. Deploy additional nodes with k3s agent mode
2. Update Longhorn replica count (currently 1)
3. Configure pod affinity/anti-affinity
4. Update resource requests/limits

### NVIDIA/LLM Support

Uncomment NVIDIA section in Containerfile:
```dockerfile
# Optional: NVIDIA GPU support layer
RUN rpm-ostree install \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    && rpm-ostree cleanup -m
```

### ARM Support

The Containerfile is designed for x86_64 but can support ARM:
- Change base image to ARM-compatible
- Adjust binary downloads (k3s, goss) for ARM architecture
- Test on ARM hardware (e.g., Raspberry Pi 4+)

---

## Documentation Index

Complete documentation available in `docs/`:

- **BUILD.md**: Building and deploying the image
- **HEALTH-CHECKS.md**: Comprehensive health check system
- **PHASE2-LONGHORN.md**: Storage configuration and backup
- **PHASE3-TLS.md**: TLS setup with cert-manager and step-ca
- **PHASE4-MONITORING.md**: Prometheus and Grafana configuration
- **PHASE5-AUTHENTIK.md**: SSO/LDAP setup and OAuth integration
- **PHASE6-APPLICATIONS.md**: Gitea and Vaultwarden setup
- **initialSpec.md**: Original project specification

---

## Project Principles

When working on this project, follow these principles:

1. **GitOps First**: Always use HelmChart CRDs, never manual kubectl apply
2. **Automation Over Manual**: Prefer blueprints and auto-configuration
3. **Documentation Required**: Every change needs corresponding docs
4. **Immutability**: Changes go through bootc image rebuild
5. **Security Conscious**: No hardcoded secrets in git
6. **Health Checks**: Add goss tests for new components
7. **Consistency**: Follow established naming and structure patterns

---

**Last Updated**: 2025-10-25
**Project Version**: Phase 6 Complete
