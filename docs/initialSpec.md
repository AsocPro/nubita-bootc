# Home Server Platform Spec: k3s-Based Bootc Image Development

## Introduction

This document finalizes the plan and scope for developing a bootc image for a k3s-based home server platform, incorporating all user inputs. The focus is an immutable, containerized OS using bootc, hosting a k3s Kubernetes cluster on x86_64 hardware (older desktops/laptops with ample RAM), with ARM compatibility planned for later. We’ll leverage AI for tasks like generating minimal manifests, scripts, and troubleshooting, ensuring lean and maintainable configurations.

Priorities:
- Start with a single-node k3s cluster, expandable to multi-node with NVIDIA support for basic LLM hosting.
- Use minimal Helm `values.yaml` (only required overrides, e.g., persistence, ingress) and operators for simplicity.
- Core infrastructure first (cluster, storage, networking/security, monitoring), then auth and apps, followed by extras (e.g., Home Assistant, backups).
- Modular image design: Build on `ublue-os/base-main` with swappable base images (e.g., AlmaLinux, other Ublue variants) and layered additions (e.g., custom CA certs).
- Pin versions for stability (k3s, components) but allow easy updates/rollbacks.
- Document best practices for extensions (e.g., Minecraft) and future overlays for AI use cases.

## Goals and Non-Goals

### Goals
- Build a bootc image booting into a single-node k3s cluster, expandable to multi-node.
- Use `ublue-os/base-main` as the base, with modular layers for swapping (e.g., custom CA certs, other bases like AlmaLinux).
- Deploy components via operators/Helm with minimal configs for low maintenance.
- Enable encrypted remote backups to AWS/Backblaze via Longhorn (add early if simple).
- Pin k3s and components to latest major versions, with easy update/rollback.
- Prepare for future NVIDIA/LLM hosting via modular image layers.
- Provide best-practice docs for adding apps (e.g., Minecraft).

### Non-Goals
- Immediate multi-node or NVIDIA setup (phase in later).
- Complex Helm overrides or custom configs.
- Specific Home Assistant integrations (handle manually).
- External cloud dependencies beyond backups.
- Full hardening (e.g., NetworkPolicies) in initial phases.

## High-Level Architecture

- **Base OS**: Bootc image from `ublue-os/base-main` (x86_64), with layered Containerfile for customizations (e.g., CA certs). Designed to swap bases (e.g., AlmaLinux bootc) via build scripts.
- **Kubernetes**: k3s (pinned to latest stable, e.g., v1.31.x as of Oct 2025) with all defaults (Klipper Helm, Traefik, servicelb, local-path storage). Single-node initially; multi-node via agent joins.
- **Operators/Helm**: Minimal `values.yaml` for Longhorn, Authentik, etc., relying on chart defaults.
- **Networking/Security**: Traefik (k3s default) for ingress, step-ca for internal CA, cert-manager for auto-TLS.
- **Storage**: Longhorn on `/var/lib/longhorn` (local disk); encrypted backups to AWS/Backblaze (Longhorn-native encryption).
- **Monitoring**: Prometheus Operator and Grafana with default dashboards.
- **Auth**: Authentik for SSO/LDAP, integrated via OIDC.
- **Apps**: Gitea (in-cluster Actions runner), Vaultwarden, Home Assistant—all with Longhorn persistence and SSO.
- **Extensibility**: Docs for apps (e.g., Minecraft) and image overlays (e.g., NVIDIA drivers, LLM deps).

Data flow:
- Traefik handles ingress with step-ca TLS.
- Apps use Longhorn PVCs; encrypted backups to AWS/Backblaze.
- Prometheus scrapes metrics; Grafana visualizes; Authentik secures access.
- Gitea Actions (in-cluster) for CI/CD, including future bootc builds.

## Phased Implementation Plan

Phases are incremental, with AI-assisted tasks for minimal YAML/Helm configs. Emphasis on simplicity and version control for updates/rollbacks.

### Phase 1: Base Cluster Setup (Core Infrastructure)
Focus: Bootable image with k3s on x86_64.

- **Components**:
  - Bootc image: Build from `ublue-os/base-main`. Layer k3s (latest, e.g., v1.31.x) via Containerfile. Add custom CA certs as a layer (e.g., copy to `/etc/pki/ca-trust/source/anchors`).
  - k3s: Install via `curl -sfL https://get.k3s.io | sh -`. Enable defaults (Traefik, Klipper, etc.). Pin version in build script.
  - Modular design: Use a `Containerfile` with multi-stage or commented sections to swap bases (e.g., `almalinux:9`).
- **Criteria**:
  - Immutable: ostree for updates/rollbacks (`rpm-ostree`).
  - Systemd unit for k3s (`k3s.service`).
  - Validation: `kubectl get nodes`; deploy test pod.
  - Lean: Minimal packages; no extra tools.
  - Versioning: Pin k3s in Containerfile (e.g., `ENV K3S_VERSION=v1.31.x`); allow override via build arg.
- **AI Assistance**: Generate Containerfile with swappable base, k3s install script, CA cert layer.
- **Milestone**: Boot on x86 hardware; cluster ready in ~10 mins.

**Sample Containerfile** (AI-generated, minimal):
```dockerfile
FROM ghcr.io/ublue-os/base-main:latest
# Allow base swap, e.g., FROM almalinux:9
ENV K3S_VERSION=v1.31.x
RUN curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh - \
    && mkdir -p /etc/pki/ca-trust/source/anchors \
    && cp /path/to/custom-ca.crt /etc/pki/ca-trust/source/anchors/ \
    && update-ca-trust
COPY k3s.service /etc/systemd/system/k3s.service
RUN systemctl enable k3s.service
```

### Phase 2: Storage and Persistence (Core Infrastructure)
Focus: Longhorn for storage; add encrypted backups if simple.

- **Components**:
  - Longhorn: Deploy via Helm (`rancher/longhorn`, latest). Minimal `values.yaml`: Enable persistence, set storage path to `/var/lib/longhorn`, enable backup if target ready.
  - Backups: Configure Longhorn for AWS/Backblaze with encryption (secret for access key, encryption passphrase).
- **Criteria**:
  - Storage on `/var/lib/longhorn` (configurable via Helm for future dedicated disk).
  - Backups: If AWS/Backblaze endpoint ready, set `backupTarget: s3://bucket@region/` with encryption enabled. Else, defer to Phase 7.
  - Single-node: Set replicas=1.
  - Versioning: Use latest Longhorn; pin via Helm `--version` if needed.
- **AI Assistance**: Generate `values.yaml`, secret for backup creds.
- **Milestone**: Test PVC; if backups enabled, verify encrypted snapshot.

**Sample values.yaml** (minimal):
```yaml
persistence:
  defaultClass: true
  defaultClassReplicaCount: 1
defaultSettings:
  storagePath: /var/lib/longhorn
  backupTarget: s3://bucket@region/  # If ready
  backupTargetCredentialSecret: longhorn-backup-secret
```

### Phase 3: Networking and Security Basics (Core Infrastructure)
Focus: Secure ingress with Traefik and step-ca.

- **Components**:
  - Step-ca: Helm (`smallstep/step-certificates`, latest). Minimal `values.yaml`: Set admin password.
  - Cert-manager: Helm (`jetstack/cert-manager`, latest). Install CRDs.
  - Traefik: Use k3s default; add IngressClass if needed.
  - ClusterIssuer: Point to step-ca for auto-TLS.
- **Criteria**:
  - Auto-TLS for ingresses.
  - Local access only.
  - Versioning: Latest step-ca/cert-manager; pin if needed.
- **AI Assistance**: Generate ClusterIssuer YAML, minimal Helm values.
- **Milestone**: HTTPS test service with step-ca cert.

**Sample ClusterIssuer** (AI-generated):
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: step-ca
spec:
  ca:
    secretName: step-ca-tls
```

### Phase 4: Monitoring and Observability (Core Infrastructure)
Focus: Basic monitoring.

- **Components**:
  - Prometheus Operator: Helm (`prometheus-community/kube-prometheus-stack`, latest). Minimal `values.yaml`: Enable Grafana, default alerts.
  - Grafana: Included in stack; default Prometheus datasource.
- **Criteria**:
  - Default dashboards (CPU, memory, pods).
  - Ingress with TLS/SSO (later).
  - Versioning: Latest; pin via Helm if needed.
- **AI Assistance**: Generate alert rules.
- **Milestone**: View metrics in Grafana.

**Sample values.yaml** (minimal):
```yaml
grafana:
  enabled: true
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
```

### Phase 5: Authentication and Access Control (Essential for Apps)
Focus: Authentik for SSO/LDAP.

- **Components**:
  - Authentik: Helm (`goauthentik/helm`, latest). Minimal `values.yaml`: Longhorn PVC, OIDC/LDAP providers.
- **Criteria**:
  - Integrate with Traefik via OIDC.
  - Versioning: Latest; pin if needed.
- **AI Assistance**: Generate OIDC provider YAML.
- **Milestone**: Test SSO login.

**Sample values.yaml** (minimal):
```yaml
postgresql:
  enabled: true
  persistence:
    enabled: true
    storageClass: longhorn
authentik:
  ldap:
    enabled: true
```

### Phase 6: Core Applications (Build on Infrastructure)
Focus: Gitea, Vaultwarden.

- **Components**:
  - Gitea: Helm (`gitea/gitea`, latest). Minimal `values.yaml`: Longhorn PVC, Authentik OIDC, in-cluster Actions runner.
  - Vaultwarden: Helm (`k8s-at-home/vaultwarden`, latest). Minimal `values.yaml`: Longhorn PVC, Authentik SSO.
- **Criteria**:
  - Gitea: Repo, registry, CI/CD with self-hosted runner.
  - Versioning: Latest; pin if needed.
- **AI Assistance**: Generate Gitea Actions workflow.
- **Milestone**: Push code to Gitea; store password in Vaultwarden.

**Sample Gitea values.yaml** (minimal):
```yaml
persistence:
  enabled: true
  storageClass: longhorn
gitea:
  config:
    oauth2:
      enabled: true
      provider: authentik
actions:
  enabled: true
  runner:
    enabled: true
```

### Phase 7: Advanced Applications and Features (Extras)
Focus: Home Assistant, backups, multi-node prep.

- **Components**:
  - Home Assistant: Helm (`k8s-at-home/home-assistant`, latest). Minimal `values.yaml`: Longhorn PVC, SSO.
  - Backups: If not in Phase 2, add Longhorn encrypted S3 target.
  - Multi-node: Docs for k3s agent join (`k3s agent --server`).
  - NVIDIA/LLM: Docs for overlaying drivers (e.g., `nvidia-driver` layer in Containerfile).
- **Criteria**:
  - Manual Home Assistant integrations.
  - Versioning: Latest; pin if needed.
- **AI Assistance**: Generate join scripts, NVIDIA layer.
- **Milestone**: Run Home Assistant; prep multi-node.

## Best Practices for Extensions

For apps like Minecraft:
- Use Helm (e.g., `itzg/minecraft-server`, latest).
- Minimal `values.yaml`: Longhorn PVC, Traefik ingress, Authentik SSO, low resources (e.g., 1GB RAM).
- AI prompt: “Generate minimal Helm values for Minecraft with Longhorn, Traefik, Authentik.”
- Steps: `helm repo add itzg https://itzg.github.io/minecraft-server-charts`, `helm install` with values.
- Docs: Store in Gitea wiki with rollback steps (e.g., `helm rollback`).

**Sample Minecraft values.yaml** (minimal):
```yaml
minecraftServer:
  eula: true
persistence:
  enabled: true
  storageClass: longhorn
ingress:
  enabled: true
  ingressClassName: traefik
  annotations:
    cert-manager.io/cluster-issuer: step-ca
  hosts:
    - host: minecraft.local
```

## Image Modularity for Future Use Cases

To support base swapping and overlays (e.g., NVIDIA, ARM):
- **Containerfile structure**: Use multi-stage builds or comments to swap bases (e.g., `FROM almalinux:9` or `ublue-os/aurora`).
- **CA certs layer**: Add as separate `COPY` step; reusable across bases.
- **NVIDIA/LLM**: Add optional layer (e.g., `RUN rpm-ostree install nvidia-driver` or containerized NVIDIA operator).
- **ARM**: Test same Containerfile with ARM base (e.g., `ublue-os/base-main:arm64` when available).
- **Versioning**: Use build args (e.g., `ARG BASE_IMAGE`, `ARG K3S_VERSION`) and Gitea Actions to build variants.
- **AI Assistance**: Generate variant Containerfiles, test scripts.

**Sample Containerfile with modularity**:
```dockerfile
ARG BASE_IMAGE=ghcr.io/ublue-os/base-main:latest
FROM ${BASE_IMAGE}
ARG K3S_VERSION=v1.31.x
RUN curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh - \
    && mkdir -p /etc/pki/ca-trust/source/anchors \
    && cp /path/to/custom-ca.crt /etc/pki/ca-trust/source/anchors/ \
    && update-ca-trust
# Optional NVIDIA layer
# RUN rpm-ostree install nvidia-driver
COPY k3s.service /etc/systemd/system/k3s.service
RUN systemctl enable k3s.service
```
