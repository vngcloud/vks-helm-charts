# ETCD Manager Helm Chart - Summary

## Overview

The **etcd-manager** Helm chart automates ETCD certificate lifecycle management and health monitoring for Kamaji tenant control plane environments.

## Chart Structure

```
etcd-manager/
├── Chart.yaml                          # Chart metadata
├── values.yaml                         # Default configuration values
├── values-example.yaml                 # Example configurations for different environments
├── .helmignore                         # Files to ignore when packaging
│
├── templates/                          # Kubernetes resource templates
│   ├── _helpers.tpl                   # Template helper functions
│   ├── NOTES.txt                      # Post-installation notes
│   │
│   ├── cert-checker-serviceaccount.yaml
│   ├── cert-checker-role.yaml
│   ├── cert-checker-rolebinding.yaml
│   ├── cert-checker-cronjob.yaml
│   │
│   ├── cert-renewal-serviceaccount.yaml
│   ├── cert-renewal-role.yaml
│   ├── cert-renewal-rolebinding.yaml
│   ├── cert-renewal-clusterrole.yaml
│   ├── cert-renewal-clusterrolebinding.yaml
│   ├── cert-renewal-configmap.yaml
│   ├── cert-renewal-secret.yaml
│   └── cert-renewal-cronjob.yaml
│
└── Documentation/
    ├── README.md                      # Comprehensive guide
    ├── INSTALLATION.md                # Detailed installation instructions
    ├── QUICK-REFERENCE.md            # Quick command reference
    └── SUMMARY.md                    # This file
```

## Components

### 1. Certificate Expiry Checker

**Purpose**: Scans ETCD certificates and identifies those approaching expiration

**Resources Created**:
- ServiceAccount: `cert-checker-sa`
- Role: `<release-name>-cert-checker`
- RoleBinding: `<release-name>-cert-checker`
- CronJob: `cert-expiry-checker`

**Key Features**:
- Checks certificates in secrets: `{etcd-name}-certs`, `{etcd-name}-root-client-certs`
- Validates health probe configuration
- Stores results in ConfigMap for renewal job
- Configurable expiration threshold (default: 40 days)

**Default Schedule**: `0 2 * * *` (Daily at 2:00 AM)

### 2. Certificate Renewal

**Purpose**: Automatically renews expiring ETCD certificates and configures health checks

**Resources Created**:
- ServiceAccount: `cert-renewal-sa`
- Role: `<release-name>-cert-renewal`
- RoleBinding: `<release-name>-cert-renewal`
- ClusterRole: `cert-renewal-tcp-reader` (for Kamaji TCP resources)
- ClusterRoleBinding: `cert-renewal-tcp-reader-binding`
- ConfigMap: `etcd-cert-renewal-config`
- Secret: `cert-renewal-secrets` (for Telegram credentials)
- CronJob: `etcd-cert-renewal`

**Key Features**:
- Reads instance list from ConfigMap created by checker
- Renews certificates using Kamaji APIs
- Updates Kubernetes secrets
- Configures health probes (liveness/readiness)
- Restarts ETCD pods with rolling updates
- Sends Telegram notifications

**Default Schedule**: `0 10 * * *` (Daily at 10:00 AM)

## Installation

### Quick Start

```bash
helm install etcd-manager ./etcd-manager -n datastore --create-namespace
```

### Production Installation

```bash
# 1. Create secret
kubectl create secret generic telegram-prod \
  --from-literal=telegram-bot-token="TOKEN" \
  --from-literal=telegram-chat-id="CHAT_ID" \
  -n datastore

# 2. Install with production values
helm install etcd-manager ./etcd-manager -n datastore \
  --set certChecker.checkDays=30 \
  --set certRenewal.config.zone="PRODUCTION" \
  --set certRenewal.secrets.create=false \
  --set certRenewal.secrets.existingSecret="telegram-prod"
```

## Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Target namespace | `datastore` |
| `certChecker.enabled` | Enable checker CronJob | `true` |
| `certChecker.schedule` | Checker run schedule | `"0 2 * * *"` |
| `certChecker.checkDays` | Days before expiry to alert | `40` |
| `certRenewal.enabled` | Enable renewal CronJob | `true` |
| `certRenewal.schedule` | Renewal run schedule | `"0 10 * * *"` |
| `certRenewal.config.zone` | Environment identifier | `"DEV"` |
| `certRenewal.config.proxyUrl` | HTTP proxy URL | `"172.28.4.4:3128"` |

## Workflows

### Certificate Check Workflow

1. **CronJob triggers** based on schedule
2. **Scan** all ETCD StatefulSets in namespace
3. **Check certificates** in associated secrets
4. **Validate** health probe configuration
5. **Store results** in ConfigMap `etcd-renewal`
6. **Report** instances needing action

### Certificate Renewal Workflow

1. **CronJob triggers** based on schedule
2. **Read ConfigMap** for instances list
3. **For each instance**:
   - Generate new certificates via Kamaji
   - Update secrets with new certificates
   - Configure health probes if missing
   - Perform rolling restart
4. **Send notifications** via Telegram
5. **Log results**

## Manual Operations

### Trigger Jobs Manually

```bash
# Certificate check
kubectl create job --from=cronjob/cert-expiry-checker \
  -n datastore manual-check-$(date +%s)

# Certificate renewal
kubectl create job --from=cronjob/etcd-cert-renewal \
  -n datastore manual-renewal-$(date +%s)
```

### View Results

```bash
# Check ConfigMap
kubectl get configmap etcd-renewal -n datastore -o yaml

# View logs
kubectl logs -n datastore -l app.kubernetes.io/component=cert-checker --tail=100
kubectl logs -n datastore -l app.kubernetes.io/component=cert-renewal --tail=100
```

## RBAC Permissions

### Cert Checker Permissions (Namespace-scoped)
- **Secrets**: get, list
- **ConfigMaps**: get, list, create, update, patch
- **StatefulSets**: get, list
- **Services**: get, list

### Cert Renewal Permissions (Namespace-scoped)
- **Secrets**: get, list, create, update, patch, delete
- **ConfigMaps**: get, list, create, update, patch
- **Services**: get, list, patch
- **StatefulSets**: get, list, watch, patch
- **Jobs**: get, list, create, delete, watch
- **Roles/RoleBindings**: get, list, create, delete
- **ServiceAccounts**: get, list

### Cert Renewal Permissions (Cluster-scoped)
- **Kamaji Resources** (`kamaji.clastix.io`): get, list, watch

## Environment-Specific Configurations

### Development
```yaml
certChecker:
  schedule: "*/30 * * * *"  # Every 30 min
  checkDays: 60

certRenewal:
  schedule: "0 * * * *"  # Hourly
  config:
    zone: "DEV"
```

### Production
```yaml
certChecker:
  schedule: "0 2 * * *"  # Daily at 2 AM
  checkDays: 30

certRenewal:
  schedule: "0 3 * * *"  # Daily at 3 AM
  config:
    zone: "PRODUCTION"
  secrets:
    create: false
    existingSecret: "prod-secrets"
```

## Monitoring & Alerting

### Metrics to Monitor
- CronJob execution success/failure
- Job completion time
- Certificate expiration dates
- Number of instances with issues

### Recommended Alerts
- CronJob failed > 2 consecutive times
- Certificate expiration < 7 days
- Job execution time > 30 minutes
- No successful run in 48 hours

### Monitoring Commands
```bash
# Check CronJob status
kubectl get cronjob -n datastore

# View recent jobs
kubectl get jobs -n datastore --sort-by=.metadata.creationTimestamp

# Check failures
kubectl get jobs -n datastore --field-selector status.successful=0

# View ConfigMap metrics
kubectl get configmap etcd-renewal -n datastore \
  -o jsonpath='{.data.total-instances}' && echo
kubectl get configmap etcd-renewal -n datastore \
  -o jsonpath='{.data.instances-with-issues}' && echo
```

## Troubleshooting

### Common Issues

1. **No ETCD instances found**
   - Verify StatefulSets exist and match naming pattern (`ds-*` or `datastore*`)

2. **Permission denied errors**
   - Check RBAC resources are created
   - Verify ServiceAccount has correct bindings

3. **Certificate reading failures**
   - Ensure secrets exist with expected keys
   - Check secret format (base64 encoded certificates)

4. **Telegram notifications not working**
   - Verify bot token and chat ID are correct
   - Check proxy configuration if using proxy

5. **CronJob not running**
   - Check suspend status: `kubectl get cronjob -o yaml`
   - Verify schedule syntax is valid

### Debug Commands
```bash
# Test RBAC
kubectl auth can-i get secrets -n datastore \
  --as=system:serviceaccount:datastore:cert-checker-sa

# Check logs
kubectl logs -n datastore -l app.kubernetes.io/name=etcd-manager --tail=50

# Describe resources
kubectl describe cronjob cert-expiry-checker -n datastore
kubectl describe job <job-name> -n datastore
```

## Upgrade & Maintenance

```bash
# Upgrade chart
helm upgrade etcd-manager ./etcd-manager -n datastore -f values.yaml

# Rollback
helm rollback etcd-manager -n datastore

# Uninstall
helm uninstall etcd-manager -n datastore
```

## Security Considerations

- **Secrets**: Store Telegram credentials in Kubernetes Secrets
- **RBAC**: Use minimal required permissions
- **ServiceAccounts**: Dedicated accounts for each component
- **Image Pull Policy**: Use `IfNotPresent` in production with specific tags
- **Network Policies**: Consider restricting egress to required endpoints
- **Pod Security**: Enable security contexts in production

## Best Practices

1. **Use specific image tags** in production (not `latest`)
2. **Store secrets separately** (use existing secrets)
3. **Set appropriate resource limits** based on cluster size
4. **Monitor job execution** and set up alerts
5. **Test in dev/staging** before production deployment
6. **Schedule jobs during off-peak hours**
7. **Keep certificates renewed** well before expiration (30-40 days)
8. **Document custom configurations**
9. **Regular backup** of ETCD data
10. **Review logs periodically** for warnings

## Testing

```bash
# Validate chart
helm lint ./etcd-manager

# Dry run
helm install test ./etcd-manager -n datastore --dry-run --debug

# Template rendering
helm template test ./etcd-manager -n datastore > output.yaml

# Apply to test cluster
helm install test ./etcd-manager -n test-namespace -f test-values.yaml
```

## Related Documentation

- **README.md**: Comprehensive feature documentation and usage guide
- **INSTALLATION.md**: Detailed installation procedures and scenarios
- **QUICK-REFERENCE.md**: Quick command reference for daily operations
- **../ETCD-Leader-Change-Runbook.md**: ETCD troubleshooting runbook

## Support

For issues or questions:
- Review documentation in this directory
- Check job logs for detailed error messages
- Verify RBAC permissions
- Test manual job execution
- Consult ETCD runbook for cluster-level issues

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-10-20 | Initial release |

## License

[Your License Here]

## Contributors

VNG Cloud Platform Team