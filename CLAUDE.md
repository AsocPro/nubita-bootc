# Nubita Bootc - Project Status and Progress

## Project Overview
Building a bootc-based immutable OS image hosting a k3s Kubernetes cluster for home server use. The platform is designed to be modular, maintainable, and expandable from single-node to multi-node with future NVIDIA/LLM support.

**Base Specification**: See [docs/initialSpec.md](docs/initialSpec.md)

## Current Status

**Last Updated**: 2025-10-25
**Current Phase**: Phase 5 - Authentication and Access Control
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
**Status**: ✅ Complete (ready for deployment)
**Goal**: Authentik for SSO/LDAP with automatic OAuth configuration
**Completed**: 2025-10-25
**Updated**: 2025-10-25 (OAuth automation)

**Tasks**:
- [x] Create Authentik HelmChart with PostgreSQL and Redis
- [x] Configure PostgreSQL with Longhorn persistence (5Gi)
- [x] Configure Redis with Longhorn persistence (1Gi)
- [x] Configure Authentik ingress with automatic HTTPS
- [x] Create Authentik blueprint for automatic Grafana OAuth provider
- [x] Enable Grafana OAuth configuration (with placeholder secret)
- [x] Enable Prometheus metrics via ServiceMonitor
- [x] Comprehensive documentation (PHASE5-AUTHENTIK.md)

**Files Created**:
- manifests/authentik/helmchart.yaml (k3s HelmChart CRD)
- manifests/authentik/blueprint-configmap.yaml (auto-configures OAuth)
- manifests/authentik/blueprint-grafana.yaml (reference/standalone version)
- manifests/authentik/README.md
- docs/PHASE5-AUTHENTIK.md

**Containerfile Updated**:
- Copies Phase 5 manifests to /var/lib/rancher/k3s/server/manifests/
- Auto-deployed by k3s on boot
- Authentik accessible at https://authentik.local

**Grafana Integration - AUTOMATED**:
- OAuth provider auto-created via Authentik blueprint on first boot
- OAuth configuration enabled in Grafana HelmChart
- User only needs to retrieve auto-generated client secret from Authentik UI
- Role mapping configured (admins group → Admin, others → Viewer)

**How OAuth Automation Works**:
1. Blueprint ConfigMap deploys before Authentik starts
2. Authentik reads blueprint and creates Grafana OAuth provider
3. Client ID set to `grafana`, secret auto-generated
4. User retrieves secret from Authentik UI and updates Grafana config

---

### Phase 6: Core Applications
**Status**: ✅ Complete (ready for deployment)
**Goal**: Deploy Gitea and Vaultwarden with automatic SSO
**Completed**: 2025-10-25

**Tasks**:
- [x] Create Gitea HelmChart with PostgreSQL and Longhorn persistence (20Gi repos, 10Gi DB)
- [x] Configure Gitea ingress with automatic HTTPS
- [x] Enable Gitea Actions (GitHub Actions compatible CI/CD)
- [x] Create Gitea OAuth blueprint for automatic Authentik integration
- [x] Create Vaultwarden HelmChart with SQLite and Longhorn persistence (5Gi)
- [x] Configure Vaultwarden ingress with automatic HTTPS
- [x] Enable Vaultwarden SSO with pre-configured Authentik OAuth
- [x] Create Vaultwarden OAuth blueprint for automatic Authentik integration
- [x] Update Authentik blueprints ConfigMap with Gitea and Vaultwarden
- [x] Comprehensive documentation (PHASE6-APPLICATIONS.md)

**Files Created**:
- manifests/gitea/helmchart.yaml (k3s HelmChart CRD)
- manifests/gitea/README.md
- manifests/vaultwarden/helmchart.yaml (k3s HelmChart CRD)
- manifests/vaultwarden/README.md
- docs/PHASE6-APPLICATIONS.md

**Files Modified**:
- manifests/authentik/blueprint-configmap.yaml (added Gitea and Vaultwarden OAuth)
- Containerfile (added Phase 6 manifests to auto-deploy directory)

**Containerfile Updated**:
- Copies Phase 6 manifests to /var/lib/rancher/k3s/server/manifests/
- Auto-deployed by k3s on boot
- Gitea accessible at https://gitea.local
- Vaultwarden accessible at https://vaultwarden.local

**SSO Integration - AUTOMATED**:
- OAuth providers auto-created via Authentik blueprints on first boot
- Gitea: OAuth configured via admin UI after retrieving client secret
- Vaultwarden: OAuth pre-configured in HelmChart (needs client secret update)
- Both use same blueprint pattern as Grafana

**Features**:
- **Gitea**: Self-hosted Git with Actions, PostgreSQL, SSH support
- **Vaultwarden**: Bitwarden-compatible password manager with browser/mobile app support
- Both with automatic HTTPS, Longhorn storage, and SSO ready
- Compatible with official Bitwarden clients (browser extensions, mobile apps)

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
- [x] Phase 5: Authentik HelmChart with PostgreSQL and Redis, OAuth blueprints
- [x] Phase 6: Gitea HelmChart, Vaultwarden HelmChart, OAuth blueprints
- [ ] Phase 7: Home Assistant HelmChart

### Documentation
- [x] Build and deployment guide (BUILD.md)
- [x] Validation checklist (VALIDATION.md)
- [x] Base image swapping instructions (in BUILD.md)
- [x] Project README
- [x] Phase 2: Longhorn storage (PHASE2-LONGHORN.md)
- [x] Phase 3: TLS with step-ca (PHASE3-TLS.md)
- [x] Phase 4: Monitoring (PHASE4-MONITORING.md)
- [x] Phase 5: Authentik SSO/LDAP (PHASE5-AUTHENTIK.md)
- [x] Phase 6: Gitea and Vaultwarden (PHASE6-APPLICATIONS.md)
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
5. ✅ Complete Phase 5: Authentik for SSO/LDAP authentication (GitOps auto-deploy with OAuth blueprints)
6. ✅ Complete Phase 6: Gitea and Vaultwarden (GitOps auto-deploy with OAuth blueprints)
7. Build and deploy bootc image to validate Phases 1-6 (see docs/VALIDATION.md)
8. Verify automatic deployment of all services
9. Test UIs with automatic HTTPS:
   - https://longhorn.local
   - https://grafana.local
   - https://prometheus.local
   - https://alertmanager.local
   - https://authentik.local
   - https://gitea.local
   - https://vaultwarden.local
10. Configure OAuth client secrets for Grafana, Gitea, and Vaultwarden
11. Test SSO login for all applications
12. Test immutable OS update/rollback with ostree
13. Begin Phase 7: Home Assistant and advanced features

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
- **Phase 5 Complete** (GitOps Approach):
  - Created Authentik HelmChart for SSO/LDAP authentication
  - PostgreSQL database with Longhorn storage (5Gi)
  - Redis cache with Longhorn storage (1Gi)
  - Authentik with automatic HTTPS at https://authentik.local
  - OIDC/OAuth2 support for modern applications
  - LDAP support for legacy applications
  - Grafana OAuth configuration ready (commented in HelmChart)
  - User and group management with web UI
  - Prometheus metrics via ServiceMonitor
  - Minimal resource requests optimized for home server
  - Comprehensive documentation (PHASE5-AUTHENTIK.md)
  - Security recommendations for production deployment
- **OAuth Automation Enhancement**:
  - Created Authentik blueprint system for automatic OAuth provider configuration
  - Grafana OAuth provider auto-created on first boot
  - Eliminates 5+ manual configuration steps
  - Client secrets auto-generated securely
  - User only needs to retrieve secret and update application config
- **Phase 6 Complete** (GitOps Approach):
  - Created Gitea HelmChart for self-hosted Git service
  - PostgreSQL database with Longhorn storage (10Gi)
  - Repository storage with Longhorn (20Gi)
  - Gitea Actions enabled (GitHub Actions compatible CI/CD)
  - SSH support enabled for Git operations
  - Gitea OAuth blueprint for automatic Authentik integration
  - Created Vaultwarden HelmChart for password management
  - SQLite database with Longhorn storage (5Gi)
  - Bitwarden-compatible (works with official browser extensions and mobile apps)
  - Vaultwarden OAuth blueprint for automatic Authentik integration
  - Updated Authentik blueprints ConfigMap with Gitea and Vaultwarden
  - Both applications with automatic HTTPS
  - Comprehensive documentation (PHASE6-APPLICATIONS.md)
  - Security recommendations for production deployment
- All core infrastructure and applications complete (Phases 1-6)
