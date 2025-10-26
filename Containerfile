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

# Install dependencies required for k3s and Longhorn
RUN rpm-ostree install \
    curl \
    iptables \
    container-selinux \
    policycoreutils-python-utils \
    iscsi-initiator-utils \
    nfs-utils \
    cryptsetup \
    device-mapper \
    util-linux \
    && rpm-ostree cleanup -m

# Install k3s-selinux policy for proper SELinux contexts
RUN curl -fsSL https://rpm.rancher.io/k3s/stable/common/coreos/noarch/k3s-selinux-1.6-1.coreos.noarch.rpm \
    -o /tmp/k3s-selinux.rpm && \
    rpm-ostree install /tmp/k3s-selinux.rpm && \
    rm -f /tmp/k3s-selinux.rpm && \
    rpm-ostree cleanup -m

# Create directory structure for k3s and Longhorn
# Consolidated to reduce layer count
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

# Create additional directories needed for configuration
RUN mkdir -p /etc/longhorn && mkdir -p /etc/goss

# Copy all k3s configuration and manifests in a single layer
# k3s supports nested directories - copy entire manifests/ directory
# Non-YAML files (README.md, etc.) are ignored by k3s
COPY config/k3s-config.yaml /etc/rancher/k3s/config.yaml
COPY systemd/k3s.service /etc/systemd/system/k3s.service
COPY manifests/ /var/lib/rancher/k3s/server/manifests/
COPY manifests/longhorn/backup-secret.yaml.example /etc/longhorn/backup-secret.yaml.example

# Enable k3s and iscsid services
RUN systemctl enable k3s.service && \
    systemctl enable iscsid.service

# Optional: NVIDIA GPU support layer (uncomment for LLM/GPU workloads)
# RUN rpm-ostree install \
#     akmod-nvidia \
#     xorg-x11-drv-nvidia \
#     xorg-x11-drv-nvidia-cuda \
#     && rpm-ostree cleanup -m

# Create nubita user before ostree commit
RUN useradd -p '$6$1THFQvSW9SO6Jj/a$.qI45pzj6WG6qyFC/PrUVqglOFWUivGNaF7ar7xHmKWWEjeSvgxXky5cRpZk3bH/qlYUiqisK8fioptcMOima0' nubita && \
    usermod -a -G wheel nubita

# Copy health check files and set permissions in one layer
COPY config/goss.yaml /etc/goss/goss.yaml
COPY scripts/healthcheck.sh /usr/bin/healthcheck.sh
RUN chmod +x /usr/bin/healthcheck.sh

# Ostree commit (must be after all file operations)
RUN ostree container commit

# Default k3s environment variables
ENV KUBECONFIG=/etc/rancher/k3s/k3s.yaml 
