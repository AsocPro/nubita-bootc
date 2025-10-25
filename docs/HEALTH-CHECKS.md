# Health Check System

## Overview

The Nubita Bootc platform uses [Goss](https://github.com/goss-org/goss) for comprehensive health validation. Goss provides declarative system and application testing with fast, parallel execution.

## Health Check Coverage

The health check system validates all phases of the platform:

### Phase 1: Base Cluster
- ✅ k3s systemd service running
- ✅ k3s process active
- ✅ k3s binary exists with correct permissions
- ✅ k3s configuration files present
- ✅ API server listening on port 6443
- ✅ Kubelet listening on port 10250
- ✅ API server health endpoint responding
- ✅ kubectl connectivity working
- ✅ Nodes in Ready state
- ✅ CoreDNS pods running
- ✅ Required kernel modules loaded (br_netfilter, overlay)
- ✅ Cluster DNS resolution working

### Phase 2: Longhorn Storage
- ✅ longhorn-system namespace exists
- ✅ Longhorn manager pods running
- ✅ Longhorn driver deployer ready
- ✅ Longhorn StorageClass available
- ✅ Longhorn UI accessible
- ✅ Storage path (/var/lib/longhorn) exists
- ✅ All critical PVCs bound

### Phase 3: TLS and Certificates
- ✅ cert-manager namespace exists
- ✅ cert-manager controller running
- ✅ cert-manager webhook running
- ✅ cert-manager cainjector running
- ✅ step-ca CA server running
- ✅ step-ca ClusterIssuer ready
- ✅ All ingress certificates issued and ready:
  - Longhorn
  - Grafana
  - Prometheus
  - Alertmanager
  - Authentik
  - Gitea
  - Vaultwarden

### Phase 4: Monitoring Stack
- ✅ monitoring namespace exists
- ✅ Prometheus server running
- ✅ Grafana running
- ✅ Alertmanager running
- ✅ Prometheus Operator running
- ✅ node-exporter DaemonSet ready
- ✅ kube-state-metrics running
- ✅ Monitoring PVCs bound

### Phase 5: Authentik SSO/LDAP
- ✅ authentik namespace exists
- ✅ Authentik server running
- ✅ Authentik worker running
- ✅ Authentik PostgreSQL running
- ✅ Authentik Redis running
- ✅ OAuth blueprints ConfigMap loaded
- ✅ Authentik PVCs bound

### Phase 6: Core Applications
- ✅ gitea namespace exists
- ✅ Gitea server running
- ✅ Gitea PostgreSQL running
- ✅ Gitea PVCs bound
- ✅ vaultwarden namespace exists
- ✅ Vaultwarden server running
- ✅ Vaultwarden PVC bound

### GitOps Deployment Validation
- ✅ All 7 HelmChart CRDs deployed:
  - Longhorn
  - cert-manager
  - step-ca
  - kube-prometheus-stack
  - Authentik
  - Gitea
  - Vaultwarden

### Ingress and TLS Validation
- ✅ All 7 ingress resources exist
- ✅ All 7 TLS certificates ready

## Running Health Checks

### Quick Health Check

```bash
# Run health checks
/usr/bin/healthcheck.sh

# Or directly with goss
goss --gossfile /etc/goss/goss.yaml validate
```

### Verbose Output

```bash
# Show detailed output
/usr/bin/healthcheck.sh --verbose

# Or with goss
goss --gossfile /etc/goss/goss.yaml validate --format documentation
```

### Different Output Formats

```bash
# JSON output
/usr/bin/healthcheck.sh --format json

# TAP output (Test Anything Protocol)
/usr/bin/healthcheck.sh --format tap

# JUnit XML output
/usr/bin/healthcheck.sh --format junit

# Silent mode (exit code only)
/usr/bin/healthcheck.sh --format silent
```

### Retry Logic

The healthcheck.sh wrapper includes automatic retry logic:

```bash
# Retry up to 5 times with 30 second delay
/usr/bin/healthcheck.sh --retries 5 --retry-delay 30
```

Default behavior:
- 3 retries
- 10 second delay between retries
- Useful for waiting for pods to start after boot

## Health Check Tests

### Total Test Count

The goss.yaml configuration includes **60+ individual tests** covering:

- 8 namespace existence checks
- 20+ pod/deployment health checks
- 7 HelmChart deployment checks
- 7 ingress resource checks
- 7 TLS certificate readiness checks
- 10+ PVC binding checks
- Service availability checks
- Configuration file presence checks

### Test Categories

**System Tests** (Phase 1):
- Service: k3s enabled and running
- Process: k3s process running
- Files: Binaries, configs, kubeconfig
- Ports: 6443 (API), 10250 (kubelet)
- HTTP: API server health endpoint
- Commands: kubectl operations, node status
- Kernel modules: br_netfilter, overlay
- DNS: Cluster DNS resolution

**Application Tests** (Phases 2-6):
- Namespace existence
- Pod status (Running)
- Deployment replica counts
- PVC binding status
- Ingress resource presence
- Certificate readiness
- HelmChart deployment confirmation

## Integration with systemd

Health checks can be integrated with systemd for monitoring:

### Create systemd timer (optional)

```bash
# /etc/systemd/system/healthcheck.service
[Unit]
Description=Nubita Bootc Health Check
After=k3s.service

[Service]
Type=oneshot
ExecStart=/usr/bin/healthcheck.sh --format json
StandardOutput=journal

# /etc/systemd/system/healthcheck.timer
[Unit]
Description=Run health checks every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Enable the timer:
```bash
systemctl enable --now healthcheck.timer
```

## Interpreting Results

### Success

```
Total Duration: 2.345s
Count: 62, Failed: 0, Skipped: 0
```

All tests passed! The platform is fully operational.

### Partial Failure

```
Total Duration: 3.456s
Count: 62, Failed: 3, Skipped: 0

Failed Tests:
- Check Gitea is running
- Check Vaultwarden is running
- Check Grafana certificate ready
```

Some services are not ready. Common causes:
- Services still starting (wait and retry)
- Resource constraints (check pod events)
- Configuration errors (check logs)

### Complete Failure

```
Command: kubectl get namespace longhorn-system
Exit Status: 1
Error: connection refused
```

Kubernetes is not accessible. Check:
- k3s service status: `systemctl status k3s`
- k3s logs: `journalctl -u k3s -f`
- API server availability

## Troubleshooting

### Health Check Not Running

```bash
# Verify goss is installed
which goss

# Check goss version
goss --version

# Verify goss.yaml exists
ls -la /etc/goss/goss.yaml

# Verify healthcheck.sh is executable
ls -la /usr/bin/healthcheck.sh
```

### kubectl Commands Failing

```bash
# Verify KUBECONFIG is set
echo $KUBECONFIG

# Should be: /etc/rancher/k3s/k3s.yaml

# Check kubeconfig file exists
ls -la /etc/rancher/k3s/k3s.yaml

# Test kubectl manually
kubectl get nodes
```

### Timeouts on Commands

Some commands may timeout if the cluster is under heavy load or services are still starting.

**Increase timeouts** in goss.yaml:
```yaml
command:
  "kubectl get pods -n gitea":
    exit-status: 0
    timeout: 30000  # Increase from 10000 (10s) to 30000 (30s)
```

### Selective Testing

Run specific tests only:

```bash
# Test only Phase 2 (Longhorn)
goss --gossfile /etc/goss/goss.yaml validate --format documentation | grep -A 20 "Phase 2"

# Test only namespaces
kubectl get namespaces

# Test only certificates
kubectl get certificates --all-namespaces
```

## CI/CD Integration

Health checks can be integrated into CI/CD pipelines:

### GitHub Actions Example

```yaml
- name: Deploy bootc image
  run: ./deploy.sh

- name: Wait for cluster ready
  run: sleep 300  # 5 minutes for all services

- name: Run health checks
  run: /usr/bin/healthcheck.sh --format junit > health-results.xml

- name: Upload results
  uses: actions/upload-artifact@v3
  with:
    name: health-check-results
    path: health-results.xml
```

### GitLab CI Example

```yaml
health_check:
  stage: test
  script:
    - /usr/bin/healthcheck.sh --format json
  artifacts:
    reports:
      junit: health-results.xml
```

## Custom Tests

Add custom tests to goss.yaml:

### Example: Custom Application

```yaml
# Check custom application namespace
command:
  "kubectl get namespace my-app":
    exit-status: 0
    timeout: 10000

# Check custom application pods
command:
  "kubectl get pods -n my-app -l app=my-app -o jsonpath='{.items[*].status.phase}'":
    exit-status: 0
    stdout:
    - "/Running/"
    timeout: 10000
```

### Example: Database Connectivity

```yaml
# Test PostgreSQL connectivity
command:
  "kubectl exec -n gitea deployment/gitea -- pg_isready -h gitea-postgresql -U gitea":
    exit-status: 0
    timeout: 10000
```

### Example: HTTP Endpoint

```yaml
# Test Grafana is responding
http:
  https://grafana.local:
    status: 200
    timeout: 10000
    insecure: true  # For self-signed certs
```

## Performance

Goss runs tests in parallel, making validation fast:

**Typical execution time**:
- Phase 1 only: ~5 seconds
- All phases: ~10-15 seconds
- With retries: ~30-60 seconds

**Resource usage**:
- CPU: Minimal (~10-50m)
- Memory: <50Mi
- No persistent storage needed

## Best Practices

1. **Run after boot**: Wait 5-10 minutes for all services to start
2. **Use retries**: Services may not be immediately available
3. **Check logs on failure**: Use `kubectl logs` to investigate
4. **Monitor over time**: Set up periodic health checks
5. **Customize for your needs**: Add application-specific tests
6. **Document changes**: Update this file when adding tests

## Resources

- [Goss Documentation](https://github.com/goss-org/goss/blob/master/docs/manual.md)
- [Goss GitHub](https://github.com/goss-org/goss)
- [k3s Health Checks](https://docs.k3s.io/installation/requirements)
- [Kubernetes Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
