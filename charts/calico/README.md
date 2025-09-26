# Calico CNI Helm Chart

This Helm chart deploys Calico CNI (Container Network Interface) for Kubernetes networking and network policy.

## Installation

- **Option 1**: Install via Github:

  ```bash
  helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts
  helm repo update

  helm install calico vks-helm-charts/calico \
    --namespace kube-system
  ```

- **Option 2**: Install via OCI-based registries

  ```bash
  helm install calico oci://vcr.vngcloud.vn/81-vks-public/vks-helm-charts/calico \
    --namespace kube-system
  ```

## Important Notes

### Value Merging Behavior

**NodeSelector (Map/Object)**: Values are **merged** with defaults. For example:

- Default: `kubernetes.io/os: linux`
- Override: `node-role.kubernetes.io/control-plane: "true"`
- Result: Both selectors are applied

### Static Manifest File

Note: This chart includes a static manifest file `calico-3.28.2.yml` that contains pre-configured Calico resources. When rendering templates, both the static resources and the templated resources will be included. The templated resources (with `.yaml` extension) support value customization, while the static file does not. (That why `nodeSelector` is merged)

## Testing

A test values file `values-test.yaml` is provided for testing purposes. To render the templates with the test values, run:

```bash
make template
```
