# Nubita Bootc - k3s Home Server Platform

An immutable, bootc-based OS image hosting a k3s Kubernetes cluster for home server use. Designed to be modular, maintainable, and expandable from single-node to multi-node with future NVIDIA/LLM support.

## Features

- **Immutable OS**: Based on bootc with ostree for atomic updates and rollbacks
- **Kubernetes**: k3s single-node cluster (expandable to multi-node)
- **Modular Design**: Swappable base images (ublue-os, AlmaLinux, etc.)
- **Version Pinning**: Reproducible builds with pinned component versions
- **Storage**: Longhorn for persistent storage with encrypted backups
- **Security**: step-ca internal CA with cert-manager for auto-TLS
- **Monitoring**: Prometheus and Grafana with default dashboards
- **Authentication**: Authentik for SSO/LDAP
- **Core Apps**: Gitea (with Actions), Vaultwarden, Home Assistant

## Quick Start

### Prerequisites

- x86_64 hardware with 8GB+ RAM
- Podman or Docker installed
- Bootc-compatible system (Fedora/RHEL-based)

### Build

```bash
git clone https://github.com/yourusername/nubita-bootc.git
cd nubita-bootc
./scripts/build.sh
```

### Deploy

See [docs/BUILD.md](docs/BUILD.md) for detailed deployment options.

## Project Status

See [CLAUDE.md](CLAUDE.md) for current implementation status and progress.

## Architecture

- **Base OS**: Bootc image from `ublue-os/base-main` (x86_64)
- **Kubernetes**: k3s v1.31.x with defaults (Traefik, Klipper, servicelb, local-path)
- **Storage**: Longhorn on `/var/lib/longhorn`
- **Networking**: Traefik ingress with step-ca TLS
- **Monitoring**: Prometheus Operator + Grafana
- **Auth**: Authentik SSO/LDAP

## Documentation

- [Build Guide](docs/BUILD.md) - Building and deploying the image
- [Health Checks](docs/HEALTH-CHECKS.md) - Comprehensive validation system
- [Phase 2: Longhorn](docs/PHASE2-LONGHORN.md) - Storage configuration
- [Phase 3: TLS](docs/PHASE3-TLS.md) - Certificate management
- [Phase 4: Monitoring](docs/PHASE4-MONITORING.md) - Prometheus and Grafana
- [Phase 5: Authentik](docs/PHASE5-AUTHENTIK.md) - SSO/LDAP authentication
- [Phase 6: Applications](docs/PHASE6-APPLICATIONS.md) - Gitea and Vaultwarden
- [Initial Specification](docs/initialSpec.md) - Complete project specification
- [Project Status](CLAUDE.md) - Implementation progress tracking

## Phased Implementation

1. **Phase 1** ✅: Base Cluster Setup (k3s on bootc)
2. **Phase 2**: Storage and Persistence (Longhorn)
3. **Phase 3**: Networking and Security (step-ca, cert-manager)
4. **Phase 4**: Monitoring (Prometheus, Grafana)
5. **Phase 5**: Authentication (Authentik)
6. **Phase 6**: Core Applications (Gitea, Vaultwarden)
7. **Phase 7**: Advanced Features (Home Assistant, multi-node, NVIDIA)

## Configuration

### k3s Configuration

See [config/k3s-config.yaml](config/k3s-config.yaml) for k3s server configuration.

### Custom CA Certificates

Place certificates in `custom-ca/` directory and uncomment the CA section in the Containerfile.

### Version Pinning

Set environment variables when building:

```bash
K3S_VERSION=v1.31.4+k3s1 ./scripts/build.sh
```

## Extending the Platform

### Adding Applications

Use Helm with minimal `values.yaml` files. See [docs/initialSpec.md](docs/initialSpec.md) for best practices (e.g., Minecraft example).

### NVIDIA/LLM Support

Uncomment the NVIDIA section in the Containerfile and rebuild. See Phase 7 documentation (coming soon).

### Multi-Node Cluster

Deploy additional nodes with k3s agent mode. See Phase 7 documentation (coming soon).

## Updates and Rollbacks

### Update

```bash
# Rebuild with new versions
K3S_VERSION=v1.32.0+k3s1 ./scripts/build.sh

# Switch to new image
sudo bootc switch --transport=oci localhost/nubita-bootc:latest
sudo systemctl reboot
```

### Rollback

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Health Checks

Built-in goss-based health validation for comprehensive cluster testing. The system validates **60+ tests** across all platform components:

```bash
# Comprehensive health check using goss (60+ tests)
sudo /usr/bin/healthcheck.sh

# Verbose output
sudo /usr/bin/healthcheck.sh --verbose

# With retry logic (useful during startup)
sudo /usr/bin/healthcheck.sh --retries 3 --retry-delay 10

# JSON output for monitoring
sudo /usr/bin/healthcheck.sh --format json

# k3s status
sudo systemctl status k3s

# Cluster status
sudo kubectl get nodes
sudo kubectl get pods -A
```

**Health Check Coverage:**
- Phase 1: k3s cluster, API server, DNS
- Phase 2: Longhorn storage, PVCs
- Phase 3: cert-manager, step-ca, TLS certificates
- Phase 4: Prometheus, Grafana, Alertmanager
- Phase 5: Authentik, PostgreSQL, Redis, OAuth blueprints
- Phase 6: Gitea, Vaultwarden, databases
- All ingress resources and TLS certificates
- All HelmChart deployments

See [docs/HEALTH-CHECKS.md](docs/HEALTH-CHECKS.md) for complete health check documentation.

## Troubleshooting

See [docs/BUILD.md](docs/BUILD.md) for common issues and solutions.

## Contributing

This is a personal home server project, but contributions and suggestions are welcome!

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [Universal Blue](https://universal-blue.org/) for base bootc images
- [k3s](https://k3s.io/) for lightweight Kubernetes
- [Longhorn](https://longhorn.io/) for distributed storage
- [Authentik](https://goauthentik.io/) for authentication
- All the amazing open-source projects that make this possible!
