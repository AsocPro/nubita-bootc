# Phase 1 Validation Checklist

This document provides a validation checklist for Phase 1 completion.

## Pre-Build Validation

- [x] Containerfile exists and is syntactically valid
- [x] k3s-config.yaml exists with appropriate defaults
- [x] k3s.service systemd unit file exists
- [x] Build script exists and is executable
- [x] Health check script exists and is executable
- [x] Documentation (BUILD.md) is complete
- [x] Project structure is organized
- [x] .gitignore configured properly

## Build Validation

To validate the build process, run:

```bash
# Test build with default settings
./scripts/build.sh
```

**Expected outcome**: Image builds successfully without errors.

**Approximate time**: 10-20 minutes (depends on network speed)

**Image size**: Expected ~2-3GB

## Post-Build Validation

After building the image:

### 1. Verify Image Exists

```bash
podman images | grep nubita-bootc
```

**Expected output**: Should show `localhost/nubita-bootc` with tag `latest`

### 2. Inspect Image Metadata

```bash
podman inspect localhost/nubita-bootc:latest | jq '.[0].Config.Labels'
```

**Expected output**: Should show labels including:
- `org.opencontainers.image.title`
- `org.opencontainers.image.description`
- `org.opencontainers.image.version`

### 3. Verify k3s Binary in Image (if possible)

```bash
podman run --rm localhost/nubita-bootc:latest /usr/local/bin/k3s --version
```

**Expected output**: Should display k3s version (e.g., `v1.31.4+k3s1`)

## Deployment Validation

### Option A: Test in VM (Recommended)

1. **Create test VM** with 8GB RAM, 20GB disk
2. **Deploy image** using one of the methods in BUILD.md
3. **Boot system** and wait for initialization
4. **Run validation commands**:

```bash
# Check systemd service
sudo systemctl status k3s

# Check cluster
sudo kubectl get nodes
sudo kubectl get pods -A

# Run health check
sudo /usr/local/bin/healthcheck.sh
```

**Expected outcomes**:
- k3s service is active and running
- Node shows as "Ready"
- All system pods are running (coredns, traefik, etc.)
- Health check passes

### Option B: Manual Inspection

If you cannot deploy to a real system, you can manually inspect:

```bash
# Check if systemd unit is included
podman run --rm localhost/nubita-bootc:latest cat /etc/systemd/system/k3s.service

# Check if k3s config exists
podman run --rm localhost/nubita-bootc:latest cat /etc/rancher/k3s/config.yaml

# Verify k3s binary
podman run --rm localhost/nubita-bootc:latest ls -l /usr/local/bin/k3s
```

## Validation Test Pod

Once deployed and cluster is running, deploy a test pod:

```bash
sudo kubectl run nginx-test --image=nginx:latest --port=80
sudo kubectl wait --for=condition=ready pod/nginx-test --timeout=60s
sudo kubectl get pod nginx-test
sudo kubectl delete pod nginx-test
```

**Expected outcome**: Pod creates, runs, and deletes successfully.

## Success Criteria

Phase 1 is considered complete when:

- [x] All files are created and organized properly
- [ ] Image builds without errors
- [ ] Image size is reasonable (~2-3GB)
- [ ] k3s binary is present in image with correct version
- [ ] Systemd service file is properly installed
- [ ] System boots successfully (if deployed)
- [ ] k3s service starts automatically on boot
- [ ] Cluster becomes ready within ~10 minutes
- [ ] kubectl commands work
- [ ] Test pod can be deployed and runs successfully
- [ ] Health check script passes

## Known Limitations (Phase 1)

At this phase, the following are expected:

- **Storage**: Only local-path storage (Longhorn comes in Phase 2)
- **Networking**: Basic Traefik (TLS/CA comes in Phase 3)
- **Monitoring**: No monitoring yet (Phase 4)
- **Auth**: No SSO yet (Phase 5)
- **Apps**: No applications yet (Phase 6+)

## Troubleshooting

### Build Fails with Network Errors

- Check internet connectivity
- Try again (k3s install script may be temporarily unavailable)
- Check if you need proxy configuration

### Build Fails with Permission Errors

- Ensure you're running as user with podman access
- Check SELinux contexts if on Fedora/RHEL
- Try: `sudo setsebool -P container_manage_cgroup true`

### k3s Service Doesn't Start After Deploy

- Check logs: `sudo journalctl -u k3s -n 100`
- Verify required kernel modules: `lsmod | grep -E 'br_netfilter|overlay'`
- Check if ports 6443, 10250 are available
- Ensure sufficient memory (minimum 2GB, recommended 4GB+)

### Cluster Takes Too Long to Be Ready

- Normal initialization can take 5-10 minutes on first boot
- Check pod status: `sudo kubectl get pods -A`
- Look for image pulls: `sudo kubectl describe pod <pod-name> -n kube-system`

## Next Steps After Validation

Once Phase 1 validation passes:

1. **Git commit** all Phase 1 work
2. **Update CLAUDE.md** to mark Phase 1 complete
3. **Proceed to Phase 2**: Longhorn storage deployment

See [../CLAUDE.md](../CLAUDE.md) for phase tracking.
