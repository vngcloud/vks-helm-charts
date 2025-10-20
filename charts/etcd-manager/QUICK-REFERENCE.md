# ETCD Manager - Quick Reference Guide

Quick commands and configurations for daily operations.

## Installation

```bash
# Basic installation
helm install etcd-manager ./etcd-manager -n datastore --create-namespace

# With custom values
helm install etcd-manager ./etcd-manager -n datastore -f my-values.yaml

# Dry run
helm install etcd-manager ./etcd-manager -n datastore --dry-run --debug
```

## Verification

```bash
# Check installation
helm list -n datastore
kubectl get cronjob -n datastore
kubectl get all -n datastore -l app.kubernetes.io/name=etcd-manager

# Validate chart
helm lint ./etcd-manager
helm template test ./etcd-manager -n datastore > output.yaml
```

## Manual Job Execution

```bash
# Trigger certificate check
kubectl create job --from=cronjob/cert-expiry-checker \
  -n datastore manual-check-$(date +%s)

# Trigger certificate renewal
kubectl create job --from=cronjob/etcd-cert-renewal \
  -n datastore manual-renewal-$(date +%s)

# Follow logs
kubectl logs -n datastore -l app.kubernetes.io/component=cert-checker -f
kubectl logs -n datastore -l app.kubernetes.io/component=cert-renewal -f
```

## Monitoring

```bash
# List all jobs
kubectl get jobs -n datastore --sort-by=.metadata.creationTimestamp

# Check recent job status
kubectl get jobs -n datastore -l app.kubernetes.io/name=etcd-manager

# View job logs
kubectl logs -n datastore job/<job-name> --tail=100

# Check ConfigMap results
kubectl get configmap etcd-renewal -n datastore -o yaml
kubectl get configmap etcd-renewal -n datastore -o jsonpath='{.data.instances}'
```

## Configuration Updates

```bash
# Update schedule
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.schedule="0 3 * * *"

# Update check days threshold
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.checkDays=30

# Update zone
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certRenewal.config.zone="PRODUCTION"

# Update from values file
helm upgrade etcd-manager ./etcd-manager -n datastore -f updated-values.yaml

# Reuse existing values
helm upgrade etcd-manager ./etcd-manager -n datastore --reuse-values
```

## Troubleshooting

```bash
# Check CronJob details
kubectl describe cronjob cert-expiry-checker -n datastore
kubectl describe cronjob etcd-cert-renewal -n datastore

# Check failed jobs
kubectl get jobs -n datastore --field-selector status.successful=0

# View pod events
kubectl get events -n datastore --sort-by='.lastTimestamp' | grep cert-

# Test RBAC permissions
kubectl auth can-i get secrets -n datastore \
  --as=system:serviceaccount:datastore:cert-checker-sa

kubectl auth can-i patch statefulsets -n datastore \
  --as=system:serviceaccount:datastore:cert-renewal-sa

# Check secret exists
kubectl get secret cert-renewal-secrets -n datastore
kubectl describe secret cert-renewal-secrets -n datastore

# Resume suspended CronJob
kubectl patch cronjob cert-expiry-checker -n datastore \
  -p '{"spec":{"suspend":false}}'
```

## Secret Management

```bash
# Create secret manually
kubectl create secret generic cert-renewal-secrets \
  --from-literal=telegram-bot-token="YOUR_TOKEN" \
  --from-literal=telegram-chat-id="YOUR_CHAT_ID" \
  -n datastore

# Update existing secret
kubectl create secret generic cert-renewal-secrets \
  --from-literal=telegram-bot-token="NEW_TOKEN" \
  --from-literal=telegram-chat-id="NEW_CHAT_ID" \
  --dry-run=client -o yaml | kubectl apply -f -

# View secret (base64 encoded)
kubectl get secret cert-renewal-secrets -n datastore -o yaml

# Decode secret values
kubectl get secret cert-renewal-secrets -n datastore \
  -o jsonpath='{.data.telegram-bot-token}' | base64 -d
```

## Cleanup

```bash
# Delete specific job
kubectl delete job <job-name> -n datastore

# Delete all completed jobs
kubectl delete job -n datastore \
  -l app.kubernetes.io/name=etcd-manager \
  --field-selector status.successful=1

# Delete all failed jobs
kubectl delete job -n datastore \
  -l app.kubernetes.io/name=etcd-manager \
  --field-selector status.successful=0

# Uninstall chart
helm uninstall etcd-manager -n datastore

# Full cleanup (including ConfigMaps)
helm uninstall etcd-manager -n datastore
kubectl delete configmap etcd-renewal -n datastore
kubectl delete jobs -n datastore -l app.kubernetes.io/name=etcd-manager
```

## Helm Operations

```bash
# View values
helm get values etcd-manager -n datastore

# View all resources
helm get all etcd-manager -n datastore

# View manifest
helm get manifest etcd-manager -n datastore

# View history
helm history etcd-manager -n datastore

# Rollback
helm rollback etcd-manager -n datastore
helm rollback etcd-manager <revision> -n datastore

# Status
helm status etcd-manager -n datastore
```

## Common Value Overrides

```bash
# Disable cert renewal
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certRenewal.enabled=false

# Change both schedules
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.schedule="0 2 * * *" \
  --set certRenewal.schedule="0 3 * * *"

# Update image tags
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certChecker.image.tag="v1.2.0" \
  --set certRenewal.image.tag="v1.2.0"

# Use existing secret
helm upgrade etcd-manager ./etcd-manager -n datastore \
  --set certRenewal.secrets.create=false \
  --set certRenewal.secrets.existingSecret="my-secret"
```

## Schedule Examples

```bash
# Every 30 minutes (testing)
--set certChecker.schedule="*/30 * * * *"

# Every hour
--set certChecker.schedule="0 * * * *"

# Every 6 hours
--set certChecker.schedule="0 */6 * * *"

# Daily at 2 AM
--set certChecker.schedule="0 2 * * *"

# Weekly on Monday at 2 AM
--set certChecker.schedule="0 2 * * 1"

# First day of month at 3 AM
--set certChecker.schedule="0 3 1 * *"
```

## Useful kubectl Commands

```bash
# Watch jobs
watch kubectl get jobs -n datastore

# Stream logs
kubectl logs -n datastore -l app.kubernetes.io/component=cert-renewal -f --tail=20

# Get job completion status
kubectl get jobs -n datastore -o wide

# List ETCD instances
kubectl get statefulsets -n datastore | grep -E "ds-|datastore"

# Check specific ETCD certificates
kubectl get secrets -n datastore | grep certs

# View ConfigMap with instances needing renewal
kubectl get configmap etcd-renewal -n datastore -o json | jq .data
```

## Testing & Validation

```bash
# Test template rendering
helm template test ./etcd-manager -n datastore > test-output.yaml

# Validate YAML
helm template test ./etcd-manager -n datastore | kubectl apply --dry-run=client -f -

# Test with specific values
helm template test ./etcd-manager -n datastore \
  --set certChecker.checkDays=30 \
  --set certRenewal.config.zone="TEST" > test.yaml

# Lint chart
helm lint ./etcd-manager

# Package chart
helm package ./etcd-manager

# Check chart dependencies
helm dependency list ./etcd-manager
```

## Debugging

```bash
# Enable verbose logging in Helm
helm install etcd-manager ./etcd-manager -n datastore --debug

# Get pod yaml
kubectl get pod -n datastore <pod-name> -o yaml

# Execute into pod (if needed for debugging)
kubectl exec -it -n datastore <pod-name> -- /bin/bash

# Check controller logs
kubectl logs -n kube-system -l component=cronjob-controller

# Get all events
kubectl get events -n datastore --sort-by='.lastTimestamp'
```

## Quick Status Check

```bash
# One-liner to check everything
echo "=== CronJobs ===" && \
kubectl get cronjob -n datastore && \
echo -e "\n=== Recent Jobs ===" && \
kubectl get jobs -n datastore --sort-by=.metadata.creationTimestamp | tail -5 && \
echo -e "\n=== ConfigMap ===" && \
kubectl get configmap etcd-renewal -n datastore -o jsonpath='{.data}' | jq .
```

## Environment-Specific Quick Deploys

### Development
```bash
cat <<EOF | helm install etcd-manager ./etcd-manager -n datastore -f -
certChecker:
  schedule: "*/30 * * * *"
  checkDays: 60
certRenewal:
  schedule: "0 * * * *"
  config:
    zone: "DEV"
EOF
```

### Production
```bash
cat <<EOF | helm install etcd-manager ./etcd-manager -n datastore -f -
certChecker:
  schedule: "0 2 * * *"
  checkDays: 30
certRenewal:
  schedule: "0 3 * * *"
  config:
    zone: "PRODUCTION"
  secrets:
    create: false
    existingSecret: "prod-telegram-secrets"
EOF
```

## Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# ETCD Manager aliases
alias em-check='kubectl create job --from=cronjob/cert-expiry-checker -n datastore manual-check-$(date +%s)'
alias em-renew='kubectl create job --from=cronjob/etcd-cert-renewal -n datastore manual-renewal-$(date +%s)'
alias em-logs='kubectl logs -n datastore -l app.kubernetes.io/name=etcd-manager --tail=50'
alias em-status='kubectl get cronjob,jobs -n datastore -l app.kubernetes.io/name=etcd-manager'
alias em-cm='kubectl get configmap etcd-renewal -n datastore -o yaml'
alias em-instances='kubectl get configmap etcd-renewal -n datastore -o jsonpath="{.data.instances}" | tr "," "\n"'
```

## Support

- Helm Chart: `/path/to/etcd-manager`
- Documentation: `README.md`, `INSTALLATION.md`
- Runbook: `../ETCD-Leader-Change-Runbook.md`
- Issues: GitHub repository