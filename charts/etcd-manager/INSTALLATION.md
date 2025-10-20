# ETCD Manager - Installation Guide

This guide provides step-by-step instructions for installing and configuring the ETCD Manager Helm chart.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Installation](#quick-installation)
3. [Detailed Installation Steps](#detailed-installation-steps)
4. [Configuration](#configuration)
5. [Verification](#verification)
6. [Common Scenarios](#common-scenarios)
7. [Troubleshooting](#troubleshooting)
8. [Upgrade and Maintenance](#upgrade-and-maintenance)

---

## Prerequisites

Before installing the ETCD Manager Helm chart, ensure you have:

### Required

- **Kubernetes Cluster**: Version 1.19 or higher
- **Helm**: Version 3.0 or higher
- **kubectl**: Configured with cluster access
- **Namespace**: Target namespace for ETCD instances (default: `datastore`)
- **ETCD Instances**: Running ETCD StatefulSets in Kamaji environment
- **Permissions**: Cluster-admin or sufficient RBAC permissions to create:
  - ServiceAccounts
  - Roles/RoleBindings
  - ClusterRoles/ClusterRoleBindings
  - CronJobs
  - ConfigMaps
  - Secrets

### Optional

- **Telegram Bot**: For notifications (bot token and chat ID)
- **HTTP Proxy**: If cluster requires proxy for external access

### Verify Prerequisites

```bash
# Check Kubernetes version
kubectl version --short

# Check Helm version
helm version --short

# Verify namespace exists (create if needed)
kubectl get namespace datastore || kubectl create namespace datastore

# Check for existing ETCD instances
kubectl get statefulsets -n datastore | grep -E "ds-|datastore"

# Verify RBAC permissions
kubectl auth can-i create serviceaccounts --namespace datastore
kubectl auth can-i create clusterroles
```

---

## Quick Installation

### Option 1: Install with Default Values

```bash
# Clone or navigate to the chart directory
cd /path/to/etcd-manager

# Install the chart
helm install etcd-manager . --namespace datastore --create-namespace

# Wait for CronJobs to be created
kubectl get cronjob -n datastore
```

### Option 2: Install with Custom Values

```bash
# Create custom values file
cat > my-values.yaml <<EOF
namespace: datastore

certChecker:
  schedule: "0 3 * * *"
  checkDays: 30

certRenewal:
  schedule: "0 4 * * *"
  config:
    zone: "PRODUCTION"
  secrets:
    telegramBotToken: "YOUR_BOT_TOKEN"
    telegramChatId: "YOUR_CHAT_ID"
EOF

# Install with custom values
helm install etcd-manager . -n datastore -f my-values.yaml
```

---

## Detailed Installation Steps

### Step 1: Prepare Configuration

#### 1.1 Create a Telegram Bot (Optional but Recommended)

If you want to receive notifications:

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` command
3. Follow instructions to create a bot
4. Save the bot token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
5. Create a group or use existing chat
6. Add the bot to the group
7. Get chat ID:
   ```bash
   # Send a message to the group
   # Then get updates
   curl https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   # Look for "chat":{"id":-123456789,...}
   ```

#### 1.2 Create Values File

Create a `values-custom.yaml` file with your configuration:

```yaml
namespace: datastore

# Certificate Checker Configuration
certChecker:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  checkDays: 40          # Alert 40 days before expiry
  image:
    repository: vcr.vngcloud.vn/81-vks-public/etcd-cert-manager
    tag: latest
    pullPolicy: Always

# Certificate Renewal Configuration
certRenewal:
  enabled: true
  schedule: "0 10 * * *"  # Daily at 10 AM
  image:
    repository: vcr.vngcloud.vn/81-vks-public/etcd-cert-renewal
    tag: latest
    pullPolicy: Always

  config:
    zone: "PRODUCTION"  # Environment identifier
    proxyUrl: "your-proxy:3128"  # Or empty if no proxy

  secrets:
    telegramBotToken: "YOUR_BOT_TOKEN_HERE"
    telegramChatId: "YOUR_CHAT_ID_HERE"

# Optional: Resource limits for production
certChecker:
  resources:
    requests:
      memory: "128Mi"
      cpu: "200m"
    limits:
      memory: "256Mi"
      cpu: "500m"

certRenewal:
  resources:
    requests:
      memory: "256Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
```

### Step 2: Validate Configuration

```bash
# Lint the chart
helm lint ./etcd-manager

# Dry-run to see what will be created
helm install etcd-manager ./etcd-manager \
  -n datastore \
  -f values-custom.yaml \
  --dry-run --debug

# Template to see rendered manifests
helm template etcd-manager ./etcd-manager \
  -n datastore \
  -f values-custom.yaml > rendered-manifests.yaml

# Review the rendered manifests
less rendered-manifests.yaml
```

### Step 3: Install the Chart

```bash
# Install the chart
helm install etcd-manager ./etcd-manager \
  --namespace datastore \
  --create-namespace \
  -f values-custom.yaml

# Verify installation
helm list -n datastore
```

### Step 4: Verify Installation

```bash
# Check all resources created
kubectl get all -n datastore -l app.kubernetes.io/name=etcd-manager

# Check CronJobs
kubectl get cronjob -n datastore

# Check ServiceAccounts
kubectl get sa -n datastore | grep cert-

# Check RBAC
kubectl get role,rolebinding,clusterrole,clusterrolebinding -n datastore | grep cert-

# Check ConfigMaps and Secrets
kubectl get configmap,secret -n datastore | grep cert-
```

---

## Configuration

### Configuration Options

#### Schedules

Schedule format uses standard cron syntax:

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

Examples:
- `"0 2 * * *"` - Daily at 2:00 AM
- `"0 */6 * * *"` - Every 6 hours
- `"0 2 * * 1"` - Every Monday at 2:00 AM
- `"*/30 * * * *"` - Every 30 minutes

#### Certificate Check Days

The `checkDays` parameter determines how many days before expiration to trigger renewal:

- **30 days**: Aggressive renewal, ensures plenty of time
- **40 days**: Balanced (default)
- **60 days**: Conservative, may catch issues early but could lead to frequent renewals

### Using Existing Secrets

For production, it's recommended to create secrets separately:

```bash
# Create secret manually
kubectl create secret generic my-telegram-secret \
  --from-literal=telegram-bot-token="YOUR_TOKEN" \
  --from-literal=telegram-chat-id="YOUR_CHAT_ID" \
  -n datastore

# Configure values to use existing secret
cat > values-prod.yaml <<EOF
certRenewal:
  secrets:
    create: false
    existingSecret: "my-telegram-secret"
    existingSecretKeys:
      telegramBotToken: telegram-bot-token
      telegramChatId: telegram-chat-id
EOF

# Install with existing secret
helm install etcd-manager ./etcd-manager -n datastore -f values-prod.yaml
```

### Environment-Specific Configurations

#### Development Environment

```yaml
certChecker:
  schedule: "*/30 * * * *"  # Every 30 minutes for testing
  checkDays: 60

certRenewal:
  schedule: "0 * * * *"  # Every hour
  config:
    zone: "DEV"
```

#### Staging Environment

```yaml
certChecker:
  schedule: "0 6 * * *"  # Once daily
  checkDays: 45

certRenewal:
  schedule: "0 8 * * *"
  config:
    zone: "STAGING"
```

#### Production Environment

```yaml
certChecker:
  schedule: "0 2 * * *"  # Daily at off-peak hours
  checkDays: 30

certRenewal:
  schedule: "0 3 * * *"  # After check completes
  config:
    zone: "PRODUCTION"

# Use existing secrets
secrets:
  create: false
  existingSecret: "prod-telegram-secrets"
```

---

## Verification

### Verify CronJob Creation

```bash
# List all CronJobs
kubectl get cronjob -n datastore

# Expected output:
# NAME                    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
# cert-expiry-checker     0 2 * * *     False     0        <none>          1m
# etcd-cert-renewal       0 10 * * *    False     0        <none>          1m
```

### Verify RBAC Setup

```bash
# Test cert-checker permissions
kubectl auth can-i get secrets -n datastore \
  --as=system:serviceaccount:datastore:cert-checker-sa

kubectl auth can-i create configmaps -n datastore \
  --as=system:serviceaccount:datastore:cert-checker-sa

# Test cert-renewal permissions
kubectl auth can-i patch statefulsets -n datastore \
  --as=system:serviceaccount:datastore:cert-renewal-sa

kubectl auth can-i delete secrets -n datastore \
  --as=system:serviceaccount:datastore:cert-renewal-sa
```

### Test Manual Execution

```bash
# Manually trigger certificate checker
kubectl create job --from=cronjob/cert-expiry-checker \
  -n datastore test-cert-check-$(date +%s)

# Wait for completion
kubectl wait --for=condition=complete job/test-cert-check-* -n datastore --timeout=300s

# View logs
kubectl logs -n datastore job/test-cert-check-* --tail=50

# Check ConfigMap was created
kubectl get configmap etcd-renewal -n datastore -o yaml

# Manually trigger certificate renewal
kubectl create job --from=cronjob/etcd-cert-renewal \
  -n datastore test-cert-renewal-$(date +%s)

# Monitor execution
kubectl logs -n datastore job/test-cert-renewal-* -f
```

---

## Common Scenarios

### Scenario 1: First-Time Installation in Production

```bash
# 1. Create namespace
kubectl create namespace datastore

# 2. Create Telegram secret separately
kubectl create secret generic telegram-prod-secrets \
  --from-literal=telegram-bot-token="PROD_TOKEN" \
  --from-literal=telegram-chat-id="PROD_CHAT_ID" \
  -n datastore

# 3. Create production values
cat > values-prod.yaml <<EOF
namespace: datastore

certChecker:
  schedule: "0 2 * * *"
  checkDays: 30

certRenewal:
  schedule: "0 3 * * *"
  config:
    zone: "PRODUCTION"
    proxyUrl: "prod-proxy.example.com:3128"
  secrets:
    create: false
    existingSecret: "telegram-prod-secrets"

resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1"
EOF

# 4. Install
helm install etcd-manager ./etcd-manager -n datastore -f values-prod.yaml

# 5. Verify
helm test etcd-manager -n datastore
```

### Scenario 2: Development/Testing Setup

```bash
# Quick test installation with frequent runs
cat > values-dev.yaml <<EOF
certChecker:
  schedule: "*/15 * * * *"  # Every 15 minutes
  checkDays: 90

certRenewal:
  schedule: "*/30 * * * *"  # Every 30 minutes
  config:
    zone: "DEV"
EOF

helm install etcd-manager ./etcd-manager -n datastore -f values-dev.yaml
```

### Scenario 3: Monitoring Only (No Auto-Renewal)

```bash
# Only enable certificate checking
cat > values-monitor.yaml <<EOF
certChecker:
  enabled: true
  schedule: "0 6 * * *"

certRenewal:
  enabled: false
EOF

helm install etcd-manager ./etcd-manager -n datastore -f values-monitor.yaml
```

### Scenario 4: Multi-Namespace Deployment

If you have ETCD instances in multiple namespaces:

```bash
# Install separate instance for each namespace
helm install etcd-manager-ns1 ./etcd-manager \
  --namespace namespace-1 \
  --set namespace=namespace-1

helm install etcd-manager-ns2 ./etcd-manager \
  --namespace namespace-2 \
  --set namespace=namespace-2
```

---

## Troubleshooting

### Issue: CronJobs Not Running

**Symptoms**: CronJobs exist but no jobs are created

**Debug Steps**:
```bash
# Check CronJob status
kubectl get cronjob -n datastore -o yaml

# Verify schedule is valid
kubectl describe cronjob cert-expiry-checker -n datastore

# Check suspend status
kubectl get cronjob cert-expiry-checker -n datastore -o jsonpath='{.spec.suspend}'
```

**Solution**:
```bash
# Resume if suspended
kubectl patch cronjob cert-expiry-checker -n datastore -p '{"spec":{"suspend":false}}'
```

### Issue: Permission Denied Errors

**Symptoms**: Job logs show "forbidden" or permission errors

**Debug Steps**:
```bash
# Check service account exists
kubectl get sa -n datastore | grep cert-

# Check role bindings
kubectl get rolebinding -n datastore | grep cert-

# Test permissions
kubectl auth can-i get secrets -n datastore \
  --as=system:serviceaccount:datastore:cert-checker-sa
```

**Solution**:
```bash
# Reinstall with RBAC enabled
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.rbac.create=true \
  --set certRenewal.rbac.create=true
```

### Issue: No ETCD Instances Found

**Symptoms**: Logs show "No ETCD statefulsets found"

**Debug Steps**:
```bash
# Check StatefulSets in namespace
kubectl get statefulsets -n datastore

# Verify naming pattern
kubectl get statefulsets -n datastore -o json | jq -r '.items[].metadata.name'
```

**Solution**: Ensure ETCD StatefulSets exist and match naming pattern (`ds-*` or `datastore*`)

### Issue: Secret Not Found

**Symptoms**: "secret not found" errors in renewal job

**Debug Steps**:
```bash
# Check if secret exists
kubectl get secret cert-renewal-secrets -n datastore

# Verify secret has correct keys
kubectl get secret cert-renewal-secrets -n datastore -o jsonpath='{.data}'
```

**Solution**:
```bash
# Create missing secret
kubectl create secret generic cert-renewal-secrets \
  --from-literal=telegram-bot-token="TOKEN" \
  --from-literal=telegram-chat-id="CHAT_ID" \
  -n datastore
```

---

## Upgrade and Maintenance

### Upgrading the Chart

```bash
# Check current version
helm list -n datastore

# Update values if needed
vim values-custom.yaml

# Upgrade
helm upgrade etcd-manager ./etcd-manager \
  -n datastore \
  -f values-custom.yaml

# Verify upgrade
helm history etcd-manager -n datastore
```

### Changing Configuration

```bash
# Update schedule
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.schedule="0 3 * * *"

# Update check days
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.checkDays=30

# Update multiple values
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.checkDays=30 \
  --set certRenewal.config.zone="PRODUCTION"
```

### Rolling Back

```bash
# View history
helm history etcd-manager -n datastore

# Rollback to previous version
helm rollback etcd-manager -n datastore

# Rollback to specific revision
helm rollback etcd-manager 2 -n datastore
```

### Uninstalling

```bash
# Uninstall the release
helm uninstall etcd-manager -n datastore

# Optionally clean up ConfigMaps
kubectl delete configmap etcd-renewal -n datastore

# Optionally clean up completed jobs
kubectl delete job -n datastore -l app.kubernetes.io/name=etcd-manager
```

---

## Next Steps

After successful installation:

1. **Monitor First Run**: Wait for the scheduled CronJob to run or trigger manually
2. **Check Notifications**: Verify Telegram notifications are received
3. **Review ConfigMap**: Examine the etcd-renewal ConfigMap for detected issues
4. **Review Logs**: Check job logs for any warnings or errors
5. **Set Up Alerts**: Configure monitoring for job failures
6. **Document**: Record your configuration and any customizations

## Support

For issues or questions:
- Review logs: `kubectl logs -n datastore -l app.kubernetes.io/name=etcd-manager`
- Check runbook: [ETCD-Leader-Change-Runbook.md](../ETCD-Leader-Change-Runbook.md)
- GitHub Issues: [Create an issue](https://github.com/your-org/etcd-manager/issues)