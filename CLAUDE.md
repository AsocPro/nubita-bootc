# Nubita Bootc - Project Status and Progress

## Project Overview
Building a bootc-based immutable OS image hosting a k3s Kubernetes cluster for home server use. The platform is designed to be modular, maintainable, and expandable from single-node to multi-node with future NVIDIA/LLM support.

**Base Specification**: See [docs/initialSpec.md](docs/initialSpec.md)

## Current Status

**Last Updated**: 2025-10-25
**Current Phase**: Phase 1 - Base Cluster Setup
**Status**: ✅ Complete (awaiting deployment validation)

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
**Status**: ⚪ Not Started
**Goal**: Longhorn for storage with optional encrypted backups

**Tasks**:
- [ ] Deploy Longhorn via Helm with minimal values.yaml
- [ ] Configure storage path to `/var/lib/longhorn`
- [ ] Set single-node replica count
- [ ] (Optional) Configure encrypted backups to AWS/Backblaze
- [ ] Test PVC creation and persistence
- [ ] Validate encrypted backup if configured

---

### Phase 3: Networking and Security Basics (Core Infrastructure)
**Status**: ⚪ Not Started
**Goal**: Secure ingress with Traefik and step-ca

**Tasks**:
- [ ] Deploy step-ca via Helm
- [ ] Deploy cert-manager with CRDs
- [ ] Configure Traefik (k3s default) with IngressClass
- [ ] Create ClusterIssuer for step-ca integration
- [ ] Test HTTPS service with auto-TLS

---

### Phase 4: Monitoring and Observability (Core Infrastructure)
**Status**: ⚪ Not Started
**Goal**: Basic monitoring with Prometheus and Grafana

**Tasks**:
- [ ] Deploy kube-prometheus-stack via Helm
- [ ] Enable Grafana with default dashboards
- [ ] Configure Prometheus service monitors
- [ ] Set up basic alerts
- [ ] Test metrics collection and visualization

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
- [ ] Phase 2: Longhorn Helm values.yaml
- [ ] Phase 3: step-ca, cert-manager, ClusterIssuer configs
- [ ] Phase 4: kube-prometheus-stack values.yaml
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
2. Build and deploy image to validate Phase 1 (see docs/VALIDATION.md)
3. Begin Phase 2: Longhorn storage deployment
4. Test immutable OS update/rollback with ostree

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
  - Build now compatible with immutable/ostree filesystem layout
- Ready for Phase 2
