# ETCD Manager Helm Chart

A Helm chart for managing ETCD certificate lifecycle and health monitoring in Kamaji tenant control plane environments.

## Overview

This Helm chart deploys two CronJobs that automate ETCD certificate management and health monitoring:

1. **Certificate Expiry Checker** - Scans ETCD certificates and identifies those expiring soon
2. **Certificate Renewal** - Automatically renews expiring certificates and configures health checks

## Features

- 🔍 **Automatic Certificate Monitoring** - Daily scans of all ETCD certificates
- 🔄 **Automated Certificate Renewal** - Renews certificates before expiration
- 💚 **Health Check Configuration** - Ensures proper liveness and readiness probes
- 📊 **ConfigMap-based Communication** - Checker stores results for renewal job
- 📱 **Telegram Notifications** - Real-time alerts on renewal status
- 🔒 **RBAC Compliant** - Minimal required permissions
- ⚙️ **Highly Configurable** - Extensive customization via values.yaml

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- ETCD instances running in Kamaji environment
- kubectl access to the cluster
- (Optional) Telegram bot for notifications

## Installation

### Quick Start

```bash
# Add the Helm repository (if applicable)
helm repo add etcd-manager https://your-repo-url
helm repo update

# Install with default values
helm install etcd-manager etcd-manager/etcd-manager -n datastore --create-namespace

# Or install from local chart
helm install etcd-manager ./etcd-manager -n datastore --create-namespace
```

### Custom Installation

```bash
# Create a custom values file
cat > my-values.yaml <<EOF
namespace: datastore

certChecker:
  schedule: "0 3 * * *"  # Run at 3 AM
  checkDays: 30          # Check 30 days before expiry

certRenewal:
  schedule: "0 11 * * *" # Run at 11 AM
  config:
    zone: "PRODUCTION"
    proxyUrl: "proxy.example.com:3128"
  secrets:
    telegramBotToken: "your-bot-token"
    telegramChatId: "your-chat-id"
EOF

# Install with custom values
helm install etcd-manager ./etcd-manager -n datastore -f my-values.yaml
```

## Configuration

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Namespace where ETCD instances are running | `datastore` |
| `commonLabels` | Additional labels to add to all resources | `{}` |
| `commonAnnotations` | Additional annotations to add to all resources | `{}` |

### Certificate Checker Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `certChecker.enabled` | Enable certificate checker CronJob | `true` |
| `certChecker.schedule` | CronJob schedule | `"0 2 * * *"` |
| `certChecker.checkDays` | Days before expiration to trigger renewal | `40` |
| `certChecker.configMapName` | ConfigMap to store check results | `etcd-renewal` |
| `certChecker.image.repository` | Image repository | `vcr.vngcloud.vn/81-vks-public/etcd-cert-manager` |
| `certChecker.image.tag` | Image tag | `latest` |
| `certChecker.resources.requests.memory` | Memory request | `64Mi` |
| `certChecker.resources.requests.cpu` | CPU request | `100m` |

### Certificate Renewal Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `certRenewal.enabled` | Enable certificate renewal CronJob | `true` |
| `certRenewal.schedule` | CronJob schedule | `"0 10 * * *"` |
| `certRenewal.image.repository` | Image repository | `vcr.vngcloud.vn/81-vks-public/etcd-cert-renewal` |
| `certRenewal.image.tag` | Image tag | `latest` |
| `certRenewal.config.zone` | Environment zone identifier | `DEV` |
| `certRenewal.config.proxyUrl` | Proxy URL for external communication | `172.28.4.4:3128` |
| `certRenewal.secrets.telegramBotToken` | Telegram bot token | (required) |
| `certRenewal.secrets.telegramChatId` | Telegram chat ID | (required) |
| `certRenewal.resources.requests.memory` | Memory request | `128Mi` |
| `certRenewal.resources.requests.cpu` | CPU request | `200m` |

### RBAC Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `certChecker.serviceAccount.create` | Create service account for checker | `true` |
| `certChecker.rbac.create` | Create RBAC resources for checker | `true` |
| `certRenewal.serviceAccount.create` | Create service account for renewal | `true` |
| `certRenewal.rbac.create` | Create RBAC resources for renewal | `true` |
| `certRenewal.rbac.createClusterRole` | Create ClusterRole for Kamaji resources | `true` |

## Usage

### Manual Trigger

#### Trigger Certificate Check

```bash
kubectl create job --from=cronjob/cert-expiry-checker \
  -n datastore manual-cert-check-$(date +%s)
```

#### Trigger Certificate Renewal

```bash
kubectl create job --from=cronjob/etcd-cert-renewal \
  -n datastore manual-cert-renewal-$(date +%s)
```

### View Results

#### Check ConfigMap Results

```bash
# View instances needing renewal
kubectl get configmap etcd-renewal -n datastore -o yaml

# Extract specific information
kubectl get configmap etcd-renewal -n datastore \
  -o jsonpath='{.data.instances}' | tr ',' '\n'

kubectl get configmap etcd-renewal -n datastore \
  -o jsonpath='{.data.last-check}'
```

#### View Job Logs

```bash
# Certificate checker logs
kubectl logs -n datastore -l app.kubernetes.io/component=cert-checker --tail=100

# Certificate renewal logs
kubectl logs -n datastore -l app.kubernetes.io/component=cert-renewal --tail=100

# Specific job logs
kubectl logs -n datastore job/<job-name>
```

### Monitor CronJobs

```bash
# View CronJob status
kubectl get cronjob -n datastore

# View recent jobs
kubectl get jobs -n datastore --sort-by=.metadata.creationTimestamp

# View job history
kubectl get jobs -n datastore -l app.kubernetes.io/name=etcd-manager
```

## Troubleshooting

### Check RBAC Permissions

```bash
# Verify cert-checker permissions
kubectl auth can-i get secrets -n datastore \
  --as=system:serviceaccount:datastore:cert-checker-sa

# Verify cert-renewal permissions
kubectl auth can-i patch statefulsets -n datastore \
  --as=system:serviceaccount:datastore:cert-renewal-sa
```

### Debug Failed Jobs

```bash
# Get failed job details
kubectl get jobs -n datastore --field-selector status.successful=0

# View pod logs from failed job
kubectl logs -n datastore -l job-name=<failed-job-name>

# Describe job for events
kubectl describe job <failed-job-name> -n datastore
```

### Common Issues

#### 1. No ETCD Instances Found

**Symptom**: Certificate checker reports "No ETCD statefulsets found"

**Solution**: Verify ETCD StatefulSets exist and match the naming pattern:
```bash
kubectl get statefulsets -n datastore | grep -E "ds-|datastore"
```

#### 2. Certificate Reading Failures

**Symptom**: "Failed to read certificate" errors in logs

**Solution**: Check that secrets exist and contain the expected certificate keys:
```bash
kubectl get secret <etcd-name>-certs -n datastore -o yaml
```

#### 3. Telegram Notification Failures

**Symptom**: Renewal completes but no notifications

**Solution**: Verify Telegram credentials:
```bash
kubectl get secret cert-renewal-secrets -n datastore -o yaml
```

#### 4. Permission Denied Errors

**Symptom**: "forbidden" errors in job logs

**Solution**: Check RBAC configuration:
```bash
helm get values etcd-manager -n datastore
kubectl describe role cert-renewal-role -n datastore
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade etcd-manager ./etcd-manager -n datastore -f my-values.yaml

# Upgrade specific parameters
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.checkDays=30 \
  --set certRenewal.config.zone=PROD
```

## Uninstallation

```bash
# Uninstall the chart
helm uninstall etcd-manager -n datastore

# Optionally remove ConfigMaps
kubectl delete configmap etcd-renewal -n datastore
```

## Architecture

### Certificate Check Flow

```
┌─────────────────────┐
│  CronJob Trigger    │
│  (Daily at 2:00 AM) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Scan ETCD          │
│  StatefulSets       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Check Certificate  │
│  Expiration Dates   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Check Health       │
│  Probe Config       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Update ConfigMap   │
│  with Results       │
└─────────────────────┘
```

### Certificate Renewal Flow

```
┌─────────────────────┐
│  CronJob Trigger    │
│  (Daily at 10:00 AM)│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Read ConfigMap     │
│  for Instance List  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  For Each Instance: │
│  - Renew Certs      │
│  - Update Secrets   │
│  - Configure Health │
│  - Restart Pods     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Send Telegram      │
│  Notification       │
└─────────────────────┘
```

## Security Considerations

- Secrets are stored in Kubernetes Secrets (base64 encoded)
- Service accounts use minimal required RBAC permissions
- CronJobs run with `restartPolicy: OnFailure` to prevent resource exhaustion
- Consider using sealed secrets or external secret managers for production

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Your License Here]

## Support

For issues and questions:
- GitHub Issues: https://github.com/your-org/etcd-manager/issues
- Documentation: https://github.com/your-org/etcd-manager/docs
- Runbook: See [ETCD-Leader-Change-Runbook.md](../ETCD-Leader-Change-Runbook.md)

## Related Documentation

- [ETCD Leader Change Troubleshooting Runbook](../ETCD-Leader-Change-Runbook.md)
- [Kamaji Documentation](https://kamaji.clastix.io/)
- [ETCD Documentation](https://etcd.io/docs/)