# Nubita Bootc - Project Status and Progress

## Project Overview
Building a bootc-based immutable OS image hosting a k3s Kubernetes cluster for home server use. The platform is designed to be modular, maintainable, and expandable from single-node to multi-node with future NVIDIA/LLM support.

**Base Specification**: See [docs/initialSpec.md](docs/initialSpec.md)

## Current Status

**Last Updated**: 2025-10-25
**Current Phase**: Phase 4 - Monitoring and Observability
**Status**: ✅ Complete (ready for deployment)

## Implementation Progress

### Phase 1: Base Cluster Setup (Core Infrastructure)
**Status**: ✅ Complete (awaiting deployment validation)
**Goal**: Bootable image with k3s on x86_64
**Completed**: 2025-10-25

- [x] Create modular Containerfile with swappable base (`ublue-os/base-main`)
- [x] Layer k3s installation (pinned to v1.31.4+k3s1)
- [x] Add custom CA certificate support layer
- [x] Create k3s systemd service unit
- [x] Implement build scripts with version pinning
- [x] Document build and deployment process (BUILD.md, VALIDATION.md)
- [ ] Validate: `kubectl get nodes` works, test pod deployment (requires deployment)
- [ ] Milestone: Boot on x86 hardware; cluster ready in ~10 mins (requires deployment)

**Components**:
- Base: `ghcr.io/ublue-os/base-main:latest`
- k3s: v1.31.x (latest stable)
- k3s defaults: Traefik, Klipper Helm, servicelb, local-path storage

---

### Phase 2: Storage and Persistence (Core Infrastructure)
**Status**: ✅ Complete (ready for deployment)
**Goal**: Longhorn for storage with optional encrypted backups
**Completed**: 2025-10-25

**Tasks**:
- [x] Create Longhorn Helm values.yaml with minimal configuration
- [x] Configure storage path to `/var/lib/longhorn`
- [x] Set single-node replica count (1 replica)
- [x] Create backup secret template for S3/Backblaze
- [x] Create deployment script (manifests/longhorn/deploy.sh)
- [x] Create test PVC manifest for validation
- [x] Comprehensive documentation (PHASE2-LONGHORN.md)

**Files Created**:
- manifests/longhorn/helmchart.yaml (k3s HelmChart CRD)
- manifests/longhorn/values.yaml (reference only)
- manifests/longhorn/backup-secret.yaml.example
- manifests/longhorn/test-pvc.yaml
- manifests/longhorn/README.md
- docs/PHASE2-LONGHORN.md

**Containerfile Updated**:
- Copies helmchart.yaml to /var/lib/rancher/k3s/server/manifests/longhorn.yaml
- k3s Helm controller auto-deploys on boot

---

### Phase 3: Networking and Security Basics (Core Infrastructure)
**Status**: ✅ Complete (ready for deployment)
**Goal**: Secure ingress with Traefik and step-ca
**Completed**: 2025-10-25

**Tasks**:
- [x] Create cert-manager HelmChart with CRDs
- [x] Create step-ca HelmChart with auto-bootstrap
- [x] Create ClusterIssuer for step-ca integration
- [x] Update Longhorn ingress to use step-ca TLS
- [x] Configure automatic certificate issuance and renewal
- [x] Comprehensive documentation (PHASE3-TLS.md)

**Files Created**:
- manifests/cert-manager/helmchart.yaml (k3s HelmChart CRD)
- manifests/cert-manager/README.md
- manifests/step-ca/helmchart.yaml (k3s HelmChart CRD)
- manifests/step-ca/clusterissuer.yaml (connects cert-manager to step-ca)
- manifests/step-ca/README.md
- docs/PHASE3-TLS.md

**Containerfile Updated**:
- Copies all Phase 3 manifests to /var/lib/rancher/k3s/server/manifests/
- Auto-deployed by k3s on boot
- Longhorn UI now has automatic HTTPS

---

### Phase 4: Monitoring and Observability (Core Infrastructure)
**Status**: ✅ Complete (ready for deployment)
**Goal**: Basic monitoring with Prometheus and Grafana
**Completed**: 2025-10-25

**Tasks**:
- [x] Create kube-prometheus-stack HelmChart
- [x] Configure Grafana with automatic HTTPS and persistence
- [x] Configure Prometheus with 15-day retention and Longhorn storage
- [x] Configure Alertmanager with persistence
- [x] Enable default dashboards and alert rules
- [x] Configure automatic metric discovery (ServiceMonitors)
- [x] Comprehensive documentation (PHASE4-MONITORING.md)

**Files Created**:
- manifests/kube-prometheus-stack/helmchart.yaml (k3s HelmChart CRD)
- manifests/kube-prometheus-stack/README.md
- docs/PHASE4-MONITORING.md

**Containerfile Updated**:
- Copies Phase 4 manifests to /var/lib/rancher/k3s/server/manifests/
- Auto-deployed by k3s on boot
- Grafana accessible at https://grafana.local
- Prometheus accessible at https://prometheus.local
- Alertmanager accessible at https://alertmanager.local

---

### Phase 5: Authentication and Access Control
**Status**: ⚪ Not Started
**Goal**: Authentik for SSO/LDAP

**Tasks**:
- [ ] Deploy Authentik via Helm
- [ ] Configure PostgreSQL with Longhorn persistence
- [ ] Set up OIDC providers
- [ ] Enable LDAP support
- [ ] Integrate with Traefik
- [ ] Test SSO login flow

---

### Phase 6: Core Applications
**Status**: ⚪ Not Started
**Goal**: Deploy Gitea and Vaultwarden

**Tasks**:
- [ ] Deploy Gitea with Longhorn persistence
- [ ] Configure Gitea Actions with in-cluster runner
- [ ] Integrate Gitea with Authentik OIDC
- [ ] Deploy Vaultwarden with Longhorn persistence
- [ ] Configure Vaultwarden SSO with Authentik
- [ ] Test repository operations and CI/CD
- [ ] Test password storage in Vaultwarden

---

### Phase 7: Advanced Applications and Features
**Status**: ⚪ Not Started
**Goal**: Home Assistant, backups finalization, multi-node prep

**Tasks**:
- [ ] Deploy Home Assistant with Longhorn persistence
- [ ] Finalize backup configuration if not in Phase 2
- [ ] Document multi-node k3s agent join process
- [ ] Document NVIDIA driver overlay for future LLM use
- [ ] Create ARM compatibility documentation
- [ ] Test Home Assistant deployment

---

## Build Artifacts

### Containerfiles
- [x] `Containerfile` - Main bootc image definition
- [x] Build argument support for base image swapping
- [x] Version pinning for k3s and components

### Scripts
- [x] Build script with version management (`scripts/build.sh`)
- [x] Health check script (`scripts/healthcheck.sh`)
- [x] Update/rollback procedures (documented in BUILD.md)

### Kubernetes Manifests
- [x] Phase 2: Longhorn HelmChart, backup secret template
- [x] Phase 3: cert-manager HelmChart, step-ca HelmChart, ClusterIssuer
- [x] Phase 4: kube-prometheus-stack HelmChart
- [ ] Phase 5: Authentik Helm values.yaml
- [ ] Phase 6: Gitea, Vaultwarden Helm values.yaml
- [ ] Phase 7: Home Assistant Helm values.yaml

### Documentation
- [x] Build and deployment guide (BUILD.md)
- [x] Validation checklist (VALIDATION.md)
- [x] Base image swapping instructions (in BUILD.md)
- [x] Project README
- [ ] Extension best practices (e.g., Minecraft example) - in spec
- [ ] Multi-node setup guide (Phase 7)
- [ ] NVIDIA/LLM overlay guide (Phase 7)
- [ ] Backup configuration guide (Phase 2/7)

---

## Version Pins

| Component | Version | Notes |
|-----------|---------|-------|
| k3s | v1.31.4+k3s1 | Pinned in Containerfile |
| Longhorn | latest | Pin if stability issues arise |
| step-ca | latest | Pin if stability issues arise |
| cert-manager | latest | Pin if stability issues arise |
| kube-prometheus-stack | latest | Pin if stability issues arise |
| Authentik | latest | Pin if stability issues arise |
| Gitea | latest | Pin if stability issues arise |
| Vaultwarden | latest | Pin if stability issues arise |

---

## Known Issues and Blockers

_None at this time_

---

## Next Steps

1. ✅ Complete Phase 1: Base cluster setup (code complete)
2. ✅ Complete Phase 2: Longhorn storage manifests (GitOps auto-deploy)
3. ✅ Complete Phase 3: TLS with cert-manager and step-ca (GitOps auto-deploy)
4. ✅ Complete Phase 4: Monitoring with Prometheus and Grafana (GitOps auto-deploy)
5. Build and deploy bootc image to validate Phases 1-4 (see docs/VALIDATION.md)
6. Verify automatic deployment of all services
7. Test UIs with automatic HTTPS:
   - https://longhorn.local
   - https://grafana.local
   - https://prometheus.local
8. Begin Phase 5: Authentik for SSO/LDAP authentication
9. Test immutable OS update/rollback with ostree

---

## Session Notes

### 2025-10-25 - Session 1: Phase 1 Implementation
- Project initialization from docs/initialSpec.md
- Created CLAUDE.md for progress tracking
- **Phase 1 Complete**:
  - Created modular Containerfile with swappable base images
  - Implemented k3s v1.31.4+k3s1 installation layer
  - Added custom CA certificate support (optional layer)
  - Created k3s systemd service unit
  - Built automated build script with version pinning
  - Created health check script for validation
  - Comprehensive documentation (BUILD.md, VALIDATION.md, README.md)
  - Project structure and configuration files
- Phase 1 is code-complete, awaiting deployment validation
- **Goss Integration Enhancement**:
  - Added goss v0.4.8 for comprehensive health validation
  - Created detailed goss.yaml with tests for services, processes, files, ports, HTTP, commands, kernel modules, and DNS
  - Updated healthcheck.sh as a feature-rich goss wrapper with retry logic, multiple output formats, and verbose mode
  - Updated all documentation to reflect goss-based health checks
  - Health checks now provide comprehensive cluster validation beyond basic scripts
- **Build Fixes**:
  - Fixed ostree /usr/local symlink issue
  - In ostree systems, /usr/local is a symlink to /var/usrlocal
  - Changed all binaries to install to /usr/bin (proper location for ostree)
  - Updated k3s, goss, and healthcheck.sh installation paths
  - Updated systemd service, goss config, and all documentation
  - Added k3s-selinux package for proper SELinux contexts
  - Added policycoreutils-python-utils for SELinux management
  - Skip SELinux context application during build (INSTALL_K3S_SKIP_SELINUX_RPM=true)
  - SELinux contexts applied at boot time by systemd, not during image build
  - Build now compatible with immutable/ostree filesystem layout
- **Phase 2 Complete** (GitOps Approach):
  - Created Longhorn HelmChart manifest for k3s Helm controller
  - Automatic deployment via k3s on first boot (no manual steps)
  - HelmChart baked into bootc image at /var/lib/rancher/k3s/server/manifests/
  - Configured storage path to /var/lib/longhorn (created in Containerfile)
  - Single replica configuration for single-node cluster
  - Created backup secret template for S3/Backblaze encrypted backups
  - Test PVC manifest for validation
  - Comprehensive documentation (PHASE2-LONGHORN.md)
  - Multi-node expansion documented for future scaling
  - Fully declarative and immutable deployment
- **Phase 3 Complete** (GitOps Approach):
  - Created cert-manager HelmChart for automatic certificate management
  - Created step-ca HelmChart for internal Certificate Authority
  - Auto-bootstrap CA certificates on first deployment
  - ClusterIssuer connects cert-manager to step-ca
  - Updated Longhorn ingress to use automatic TLS
  - All services can now get automatic HTTPS certificates
  - Certificate validity: 24 hours with auto-renewal
  - Root CA: 10 years, Intermediate CA: 5 years
  - Comprehensive documentation (PHASE3-TLS.md)
  - All manifests baked into bootc image for GitOps deployment
- **Phase 4 Complete** (GitOps Approach):
  - Created kube-prometheus-stack HelmChart with Prometheus, Grafana, Alertmanager
  - Grafana with automatic HTTPS at https://grafana.local
  - Prometheus with 15-day retention and Longhorn storage (15Gi)
  - Alertmanager for alert routing and notifications
  - Default Kubernetes dashboards pre-loaded
  - Default alert rules for common issues
  - Node Exporter and kube-state-metrics for comprehensive metrics
  - Automatic ServiceMonitor discovery
  - All components use Longhorn for persistence
  - Minimal resource requests optimized for home server
  - Comprehensive documentation (PHASE4-MONITORING.md)
- Ready for Phase 5 (Authentik SSO/LDAP authentication)
