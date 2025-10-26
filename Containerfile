# Nubita Bootc - k3s Home Server Platform
# Modular bootc image with k3s for x86_64 (ARM compatible)

# Base image - swappable via build arg
ARG BASE_IMAGE=ghcr.io/ublue-os/base-main:latest
FROM ${BASE_IMAGE}

# Version pinning for reproducibility
ARG K3S_VERSION=v1.31.4+k3s1
ARG K3S_INSTALL_SCRIPT_URL=https://get.k3s.io
ARG GOSS_VERSION=0.4.8

# Metadata
LABEL org.opencontainers.image.title="Nubita Bootc k3s"
LABEL org.opencontainers.image.description="Immutable bootc image with k3s for home server platform"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/yourusername/nubita-bootc"

# Install dependencies required for k3s
RUN rpm-ostree install \
    curl \
    iptables \
    container-selinux \
    policycoreutils-python-utils \
    && rpm-ostree cleanup -m

# Install k3s-selinux policy for proper SELinux contexts
RUN curl -fsSL https://rpm.rancher.io/k3s/stable/common/coreos/noarch/k3s-selinux-1.6-1.coreos.noarch.rpm \
    -o /tmp/k3s-selinux.rpm && \
    rpm-ostree install /tmp/k3s-selinux.rpm && \
    rm -f /tmp/k3s-selinux.rpm && \
    rpm-ostree cleanup -m

# Create directory structure for k3s
RUN mkdir -p /etc/rancher/k3s \
    && mkdir -p /var/lib/rancher/k3s \
    && mkdir -p /var/lib/longhorn

# Download and install k3s binary
# In ostree systems, install to /usr/bin instead of /usr/local/bin
# Skip SELinux during build - contexts will be applied at boot via k3s-selinux package
RUN curl -sfL ${K3S_INSTALL_SCRIPT_URL} | \
    INSTALL_K3S_VERSION=${K3S_VERSION} \
    INSTALL_K3S_SKIP_START=true \
    INSTALL_K3S_SKIP_ENABLE=true \
    INSTALL_K3S_SKIP_SELINUX_RPM=true \
    INSTALL_K3S_BIN_DIR=/usr/bin \
    sh -

# Download and install goss for health checks
# Install to /usr/bin for ostree compatibility
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -fsSL https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-linux-${ARCH} \
        -o /usr/bin/goss && \
    chmod +x /usr/bin/goss

# Optional: Custom CA certificate support layer
# Uncomment and add your custom CA certificates to the build context
# COPY custom-ca/*.crt /etc/pki/ca-trust/source/anchors/
# RUN update-ca-trust

# Copy k3s configuration
COPY config/k3s-config.yaml /etc/rancher/k3s/config.yaml

# Copy k3s auto-deploy manifests (Helm charts, etc.)
# k3s will automatically deploy these on startup
RUN mkdir -p /var/lib/rancher/k3s/server/manifests

# Phase 2: Longhorn storage
COPY manifests/longhorn/longhorn-helmchart.yaml /var/lib/rancher/k3s/server/manifests/longhorn.yaml
COPY manifests/longhorn/backup-secret.yaml.example /etc/longhorn/backup-secret.yaml.example

# Phase 3: cert-manager and step-ca for TLS
COPY manifests/cert-manager/cert-manager-helmchart.yaml /var/lib/rancher/k3s/server/manifests/cert-manager.yaml
COPY manifests/step-ca/step-ca-helmchart.yaml /var/lib/rancher/k3s/server/manifests/step-ca.yaml
COPY manifests/step-ca/clusterissuer.yaml /var/lib/rancher/k3s/server/manifests/step-ca-clusterissuer.yaml

# Phase 4: Prometheus and Grafana for monitoring
COPY manifests/kube-prometheus-stack/kube-prometheus-stack-helmchart.yaml /var/lib/rancher/k3s/server/manifests/kube-prometheus-stack.yaml

# Phase 5: Authentik for SSO/LDAP authentication
COPY manifests/authentik/blueprint-configmap.yaml /var/lib/rancher/k3s/server/manifests/authentik-blueprints.yaml
COPY manifests/authentik/authentik-helmchart.yaml /var/lib/rancher/k3s/server/manifests/authentik.yaml

# Phase 6: Core applications with SSO
COPY manifests/gitea/gitea-helmchart.yaml /var/lib/rancher/k3s/server/manifests/gitea.yaml
COPY manifests/vaultwarden/vaultwarden-helmchart.yaml /var/lib/rancher/k3s/server/manifests/vaultwarden.yaml

# Copy systemd service file for k3s
COPY systemd/k3s.service /etc/systemd/system/k3s.service

# Enable k3s service
RUN systemctl enable k3s.service

# Optional: NVIDIA GPU support layer (uncomment for LLM/GPU workloads)
# RUN rpm-ostree install \
#     akmod-nvidia \
#     xorg-x11-drv-nvidia \
#     xorg-x11-drv-nvidia-cuda \
#     && rpm-ostree cleanup -m

# Ostree commit
RUN ostree container commit

# Copy goss health check configuration
COPY config/goss.yaml /etc/goss/goss.yaml

# Copy health check script wrapper for goss
COPY scripts/healthcheck.sh /usr/bin/healthcheck.sh
RUN chmod +x /usr/bin/healthcheck.sh

# Default k3s environment variables
ENV KUBECONFIG=/etc/rancher/k3s/k3s.yaml

RUN useradd  -p '$6$1THFQvSW9SO6Jj/a$.qI45pzj6WG6qyFC/PrUVqglOFWUivGNaF7ar7xHmKWWEjeSvgxXky5cRpZk3bH/qlYUiqisK8fioptcMOima0' nubita && \
    usermod -a -G wheel nubita 
