# Phase 4: Monitoring and Observability

## Overview

Phase 4 adds complete monitoring and observability with the kube-prometheus-stack, providing Prometheus for metrics collection, Grafana for visualization, and Alertmanager for alerting.

## Components

### Prometheus
- Time-series metrics database
- Scrapes metrics from all cluster components
- 15-day retention, 10GB size limit
- **Auto-deployed** via k3s Helm controller

### Grafana
- Visualization and dashboarding
- Pre-loaded with Kubernetes dashboards
- Persistent storage for dashboards
- **Auto-deployed** with automatic HTTPS

### Alertmanager
- Alert routing and management
- Notification handling
- **Auto-deployed** via k3s Helm controller

### Additional Components
- **Prometheus Operator**: Manages Prometheus instances
- **Node Exporter**: Collects node-level metrics
- **kube-state-metrics**: Collects Kubernetes object metrics
- **Default Alert Rules**: Pre-configured alerts for common issues

## Quick Start

**No manual steps needed!** Everything is automatically deployed when the system boots.

1. Boot the bootc image
2. k3s deploys kube-prometheus-stack
3. Access Grafana at `https://grafana.local`
4. Default credentials: `admin` / `admin` (change on first login)

## Accessing Dashboards

### Grafana

```
https://grafana.local
```

**Default Login:**
- Username: `admin`
- Password: `admin` (you'll be prompted to change this)

**Setup DNS:**
```bash
# Add to /etc/hosts
echo "192.168.1.x grafana.local" | sudo tee -a /etc/hosts
```

### Prometheus UI (Optional)

```
https://prometheus.local
```

Direct access to Prometheus for advanced queries.

### Alertmanager UI (Optional)

```
https://alertmanager.local
```

Manage and silence alerts.

## Default Dashboards

Grafana comes pre-loaded with dashboards for:

- **Kubernetes / Compute Resources / Cluster**: Overall cluster metrics
- **Kubernetes / Compute Resources / Namespace (Pods)**: Per-namespace resource usage
- **Kubernetes / Compute Resources / Node (Pods)**: Per-node resource usage
- **Kubernetes / Compute Resources / Pod**: Individual pod metrics
- **Kubernetes / Networking / Cluster**: Network traffic
- **Kubernetes / Storage / Volumes**: Persistent volume metrics
- **Node Exporter / Nodes**: Detailed node metrics
- **Prometheus / Overview**: Prometheus health

## Configuration

### Grafana Settings

Configured in `manifests/kube-prometheus-stack/helmchart.yaml`:

- **Admin Password**: `admin` (change this!)
- **Persistence**: 5Gi Longhorn volume
- **Ingress**: Automatic HTTPS via step-ca
- **Default Dashboards**: Enabled
- **Plugins**: Piechart and Clock panels

### Prometheus Settings

- **Retention**: 15 days
- **Storage**: 15Gi Longhorn volume
- **Scrape Interval**: 30 seconds
- **Resources**: 512Mi memory, 100m CPU (requests)

### Alertmanager Settings

- **Storage**: 2Gi Longhorn volume
- **Resources**: Minimal (64Mi memory, 10m CPU)

## Metrics Collection

Prometheus automatically scrapes metrics from:

- **Kubernetes API Server**
- **kubelet** (node agent)
- **kube-state-metrics** (Kubernetes objects)
- **Node Exporter** (node-level metrics)
- **Longhorn** (storage metrics, if ServiceMonitor exists)
- **cert-manager** (certificate metrics, if ServiceMonitor exists)
- **Traefik** (ingress metrics)

## Alert Rules

Default alerts are enabled for:

- **Node conditions** (memory pressure, disk pressure)
- **Pod health** (crashlooping, not ready)
- **Persistent volumes** (nearly full)
- **Kubernetes components** (API server down, kubelet issues)
- **Prometheus** (scrape failures, rule evaluation errors)

## Custom Dashboards

### Creating a Dashboard

1. Log in to Grafana
2. Click **+** → **Dashboard**
3. Add panels with queries
4. Save dashboard

Example PromQL query:
```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Memory usage by namespace
sum(container_memory_usage_bytes) by (namespace)

# Disk usage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes
```

### Importing Dashboards

Grafana.com has thousands of community dashboards:

1. Go to **+** → **Import**
2. Enter dashboard ID from [grafana.com/dashboards](https://grafana.com/dashboards)
3. Select Prometheus datasource
4. Import

**Recommended Dashboard IDs:**
- **1860**: Node Exporter Full
- **12740**: Kubernetes Monitoring
- **13770**: Longhorn
- **11455**: Traefik

## ServiceMonitors

To add metrics from custom applications, create a ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 30s
```

Prometheus will automatically discover and scrape it.

## Alerting

### Configure Notifications

Edit Alertmanager config:

```bash
kubectl -n monitoring edit secret alertmanager-kube-prometheus-stack-alertmanager
```

Add receivers (Slack, email, PagerDuty, etc.):

```yaml
receivers:
- name: 'slack'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
    channel: '#alerts'
    title: 'Cluster Alert'
```

### Create Custom Alerts

Create a PrometheusRule:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-alerts
  namespace: monitoring
spec:
  groups:
  - name: custom
    interval: 30s
    rules:
    - alert: HighMemoryUsage
      expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ $labels.instance }}"
        description: "Memory usage is above 90%"
```

## Verification

### Check Deployment

```bash
# Check pods
kubectl -n monitoring get pods

# Check PVCs
kubectl -n monitoring get pvc

# Check ServiceMonitors
kubectl -n monitoring get servicemonitors

# Check PrometheusRules
kubectl -n monitoring get prometheusrules
```

### Check Metrics

```bash
# Port-forward to Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

# Open http://localhost:9090 and run queries
```

### Check Grafana

```bash
# Port-forward to Grafana (if DNS not set up)
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

# Open http://localhost:3000
```

## Troubleshooting

### Prometheus Not Scraping Targets

```bash
# Check Prometheus targets
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check ServiceMonitor selector
kubectl -n monitoring describe prometheus kube-prometheus-stack-prometheus
```

### Grafana Dashboards Not Loading

```bash
# Check Grafana logs
kubectl -n monitoring logs -l app.kubernetes.io/name=grafana

# Check datasource connection
# In Grafana: Configuration → Data Sources → Prometheus → Test
```

### High Memory Usage

If Prometheus uses too much memory:

1. **Reduce retention**: Change `retention: 15d` to `retention: 7d`
2. **Reduce scrape frequency**: Change `scrapeInterval: 30s` to `60s`
3. **Limit storage**: Keep `retentionSize: "10GB"`

### PVC Not Binding

```bash
# Check Longhorn is ready
kubectl -n longhorn-system get pods

# Check PVC status
kubectl -n monitoring describe pvc

# Check storage class
kubectl get storageclass
```

## Performance Tuning

### For Low-Resource Systems

If running on limited hardware, reduce resources:

```yaml
# Edit helmchart.yaml
prometheus:
  prometheusSpec:
    retention: 7d  # Reduce from 15d
    retentionSize: "5GB"  # Reduce from 10GB
    resources:
      requests:
        memory: 256Mi  # Reduce from 512Mi
```

### For High-Traffic Systems

If monitoring many services:

```yaml
prometheus:
  prometheusSpec:
    retention: 30d  # Increase retention
    retentionSize: "50GB"  # Increase storage
    resources:
      requests:
        memory: 2Gi  # Increase memory
```

## Security

### Change Default Password

**Important**: Change the Grafana admin password on first login!

Or set it before deployment by editing `helmchart.yaml`:

```yaml
grafana:
  adminPassword: "your-secure-password"
```

Then rebuild the bootc image.

### Enable OAuth (Phase 5)

After deploying Authentik (Phase 5), configure Grafana OAuth:

```yaml
grafana:
  grafana.ini:
    auth.generic_oauth:
      enabled: true
      name: Authentik
      client_id: grafana
      client_secret: SECRET
      scopes: openid profile email
      auth_url: https://authentik.local/application/o/authorize/
      token_url: https://authentik.local/application/o/token/
      api_url: https://authentik.local/application/o/userinfo/
```

## Next Phase

After Phase 4, you'll have complete visibility into your cluster!

**Phase 5: Authentication (Authentik)** will add:
- SSO for Grafana
- SSO for all future services
- LDAP for authentication

## Resources

- [kube-prometheus-stack Documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
