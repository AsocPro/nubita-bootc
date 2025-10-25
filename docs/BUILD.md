# Building the Nubita Bootc Image

## Prerequisites

- **Container Runtime**: Podman or Docker
- **Bootc**: Install via `dnf install bootc` (on Fedora/RHEL) or equivalent
- **Hardware**: x86_64 system with at least 4GB RAM (8GB+ recommended)
- **Disk Space**: At least 20GB free for building and testing

## Quick Start

Build the default image:

```bash
./scripts/build.sh
```

This creates a local image: `localhost/nubita-bootc:latest`

## Build Options

### Using Different Base Images

The Containerfile supports swappable base images via build arguments:

**Default (ublue-os/base-main)**:
```bash
BASE_IMAGE=ghcr.io/ublue-os/base-main:latest ./scripts/build.sh
```

**AlmaLinux 9**:
```bash
BASE_IMAGE=quay.io/centos-bootc/almalinux:9 ./scripts/build.sh
```

**Other Ublue variants**:
```bash
BASE_IMAGE=ghcr.io/ublue-os/aurora:latest ./scripts/build.sh
```

### Pinning k3s Version

```bash
K3S_VERSION=v1.31.4+k3s1 ./scripts/build.sh
```

To find available k3s versions: https://github.com/k3s-io/k3s/releases

### Custom Image Name and Tag

```bash
IMAGE_NAME=myregistry/nubita IMAGE_TAG=v1.0.0 ./scripts/build.sh
```

### Combining Options

```bash
BASE_IMAGE=quay.io/centos-bootc/almalinux:9 \
K3S_VERSION=v1.31.4+k3s1 \
IMAGE_NAME=localhost/nubita-bootc \
IMAGE_TAG=almalinux-k3s-1.31.4 \
./scripts/build.sh
```

## Adding Custom CA Certificates

1. Place your custom CA certificates (`.crt` files) in the `custom-ca/` directory
2. Uncomment the CA certificate section in the `Containerfile`:
   ```dockerfile
   COPY custom-ca/*.crt /etc/pki/ca-trust/source/anchors/
   RUN update-ca-trust
   ```
3. Rebuild the image

## Manual Build (Advanced)

If you prefer to build manually without the build script:

```bash
podman build \
    --build-arg BASE_IMAGE=ghcr.io/ublue-os/base-main:latest \
    --build-arg K3S_VERSION=v1.31.4+k3s1 \
    -t localhost/nubita-bootc:latest \
    -f Containerfile \
    .
```

## Deployment Options

### Option 1: Install to Existing System

On a bootc-compatible system:

```bash
# Save the image to a tar archive
podman save localhost/nubita-bootc:latest -o nubita-bootc.tar

# Copy to target system and load
scp nubita-bootc.tar target-host:~
ssh target-host
podman load -i nubita-bootc.tar

# Switch to the new image
sudo bootc switch --transport=oci localhost/nubita-bootc:latest

# Reboot
sudo systemctl reboot
```

### Option 2: Create Installation ISO

```bash
# Install bootc-image-builder if not present
sudo dnf install bootc-image-builder

# Create an ISO installer
sudo podman run --rm -it --privileged \
    -v $(pwd)/output:/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type iso \
    localhost/nubita-bootc:latest
```

The ISO will be created in the `output/` directory.

### Option 3: Direct Installation to Disk

**WARNING**: This will erase the target disk!

```bash
sudo bootc install to-disk \
    --target-imgref localhost/nubita-bootc:latest \
    /dev/sdX  # Replace with your target disk
```

## Verification After Boot

After booting into the new system:

1. **Check k3s service status**:
   ```bash
   sudo systemctl status k3s
   ```

2. **Verify cluster is running**:
   ```bash
   sudo kubectl get nodes
   sudo kubectl get pods -A
   ```

3. **Run goss-based health check**:
   ```bash
   # Basic health check
   sudo /usr/local/bin/healthcheck.sh

   # Verbose output with detailed test results
   sudo /usr/local/bin/healthcheck.sh -v

   # With retry logic (useful during cluster startup)
   sudo /usr/local/bin/healthcheck.sh -r 3 -s 10

   # JSON output for automation/monitoring
   sudo /usr/local/bin/healthcheck.sh -f json
   ```

4. **Check k3s version**:
   ```bash
   k3s --version
   goss --version
   ```

## Health Checks with Goss

The image includes [goss](https://github.com/goss-org/goss), a YAML-based serverspec alternative for validating server configuration. The health check script (`/usr/local/bin/healthcheck.sh`) wraps goss to provide comprehensive cluster validation.

### What Gets Validated

The goss configuration (`/etc/goss/goss.yaml`) validates:

- **Services**: k3s service is enabled and running
- **Processes**: k3s process is active
- **Files**: k3s binary, config files, kubeconfig exist with correct permissions
- **Ports**: API server (6443) and kubelet (10250) are listening
- **HTTP Endpoints**: API server /healthz endpoint responds
- **Commands**: kubectl works, nodes are ready, system pods are running
- **Kernel Modules**: Required modules (br_netfilter, overlay) are loaded
- **DNS**: Cluster DNS resolution works

### Health Check Usage

```bash
# Basic usage - runs all tests
sudo /usr/local/bin/healthcheck.sh

# Verbose output
sudo /usr/local/bin/healthcheck.sh -v

# Retry on failure (useful during startup)
sudo /usr/local/bin/healthcheck.sh -r 3 -s 10

# Different output formats
sudo /usr/local/bin/healthcheck.sh -f json      # JSON
sudo /usr/local/bin/healthcheck.sh -f junit     # JUnit XML
sudo /usr/local/bin/healthcheck.sh -f tap       # TAP
sudo /usr/local/bin/healthcheck.sh -f silent    # Silent (exit code only)

# Get help
/usr/local/bin/healthcheck.sh --help
```

### Direct Goss Usage

You can also run goss directly for more control:

```bash
# Run all tests
sudo goss --gossfile /etc/goss/goss.yaml validate

# Run specific tests
sudo goss --gossfile /etc/goss/goss.yaml validate --format documentation

# Generate test report
sudo goss --gossfile /etc/goss/goss.yaml validate --format json > health-report.json
```

### Customizing Health Checks

To add custom health checks, you can:

1. **Extend the goss configuration** - Add tests to `/etc/goss/goss.yaml`
2. **Create a custom goss file** and use: `GOSS_FILE=/path/to/custom.yaml healthcheck.sh`
3. **Layer in your own goss config** via Containerfile

Example custom test:
```yaml
# Add to /etc/goss/goss.yaml
command:
  "my-custom-check":
    exit-status: 0
    stdout:
    - "healthy"
```

## Updates and Rollbacks

### Updating the System

Rebuild the image with a new version, then:

```bash
sudo bootc switch --transport=oci localhost/nubita-bootc:new-version
sudo systemctl reboot
```

### Rolling Back

View available deployments:
```bash
sudo rpm-ostree status
```

Rollback to previous deployment:
```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Troubleshooting

### Build Fails

1. **Check container runtime**:
   ```bash
   podman --version
   # or
   docker --version
   ```

2. **Clear build cache**:
   ```bash
   podman system prune -a
   ```

3. **Check disk space**:
   ```bash
   df -h
   ```

### k3s Doesn't Start After Boot

1. **Check systemd service**:
   ```bash
   sudo journalctl -u k3s -n 50
   ```

2. **Verify k3s binary**:
   ```bash
   ls -l /usr/local/bin/k3s
   /usr/local/bin/k3s --version
   ```

3. **Check network requirements**:
   ```bash
   # Ensure required ports are available
   sudo ss -tlnp | grep -E ':(6443|10250)'
   ```

### kubectl Command Not Found

k3s installs `kubectl` as a symlink. If missing:

```bash
sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl
```

Or use k3s directly:
```bash
sudo k3s kubectl get nodes
```

## Advanced: Multi-Node Setup

See [MULTI-NODE.md](MULTI-NODE.md) for instructions on expanding to a multi-node cluster (Phase 7).

## Advanced: NVIDIA GPU Support

See [NVIDIA.md](NVIDIA.md) for instructions on adding NVIDIA driver layers (Phase 7).

## Version Management

The build script supports pinning versions for reproducibility:

| Component | Environment Variable | Default |
|-----------|---------------------|---------|
| Base Image | `BASE_IMAGE` | `ghcr.io/ublue-os/base-main:latest` |
| k3s | `K3S_VERSION` | `v1.31.4+k3s1` |
| Image Name | `IMAGE_NAME` | `localhost/nubita-bootc` |
| Image Tag | `IMAGE_TAG` | `latest` |

## CI/CD Integration

Once Gitea is deployed (Phase 6), you can use Gitea Actions to automate builds:

```yaml
# .gitea/workflows/build.yml
name: Build Bootc Image
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Image
        run: ./scripts/build.sh
      - name: Push to Registry
        run: podman push localhost/nubita-bootc:latest your-registry/nubita-bootc:latest
```

## Next Steps

After successful build and deployment:

1. **Verify cluster operation** with health checks
2. **Proceed to Phase 2**: Deploy Longhorn for persistent storage
3. **See [../CLAUDE.md](../CLAUDE.md)** for overall project status and next phases
