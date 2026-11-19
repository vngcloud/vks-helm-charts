![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white) ![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689) ![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white) ![Github Pages](https://img.shields.io/badge/github%20pages-121013?style=for-the-badge&logo=github&logoColor=white) ![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
# VngCloud Snapshot Controller
![production-env](https://badgen.net/badge/PRODUCTION/environment/blue?icon=github)
<hr>

# 1. Installation
## 1.1. Prerequisites
- Helm 3.0+
- `KUBECONFIG` environment variable pointing to the `.kubeconfig` file with access to your vKS cluster.

## 1.2. Install `vngcloud-snapshot-controller` on Kubernetes
- Following the below steps to install `vks-helm-charts` on your vKS cluster:
  - **Step 1**: Add the `vks-helm-charts` Helm repository:
    ```
    helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts
    helm repo update
    ```

  - **Step 2**: Install `vngcloud-snapshot-controller`:
    ```
    helm install vngcloud-snapshot-controller vks-helm-charts/vngcloud-snapshot-controller \
      --replace --namespace kube-system
    ```

# 2. Configuration
Every value is top-level. Defaults render the same Deployment as chart 1.0.0 (no scheduling constraints, no
PodDisruptionBudget), except the image: snapshot-controller v8.7.0 with the v8.7.0 upstream CRDs and RBAC.

| Key | Default | Description |
|---|---|---|
| `replicaCount` | `2` | Replicas of the Deployment. Leader election is always on: one replica is active, the others are standbys. |
| `image.repository` | `vcr.vngcloud.vn/81-vks-public/snapshot-controller` | Image repository. |
| `image.tag` | `""` | Image tag; empty = `v<appVersion>`. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `logLevel` | `2` | klog verbosity (`--v`). |
| `resources` | requests `cpu: 10m`, `memory: 40Mi`; limits `memory: 256Mi` | Container resources. |
| `nodeSelector` | `{}` | Node selector of the pods. |
| `tolerations` | `[]` | Tolerations of the pods, rendered as given. |
| `affinity` | `{}` | Affinity of the pods, rendered as given. Pods carry `app.kubernetes.io/name: snapshot-controller`. |
| `topologySpreadConstraints` | `[]` | Topology spread constraints, rendered as given (set your own `labelSelector`). |
| `priorityClassName` | `""` | Priority class of the pods; empty = not set. |
| `podAnnotations` | `{}` | Extra pod annotations. |
| `podLabels` | `{}` | Extra pod labels. `app.kubernetes.io/name` (the selector) cannot be overridden. |
| `podDisruptionBudget.enabled` | `false` | Create a PodDisruptionBudget for the pods. |
| `podDisruptionBudget.maxUnavailable` | unset (`1` when enabled and `minAvailable` is unset) | Integer or percent string. |
| `podDisruptionBudget.minAvailable` | unset | Integer or percent string. Never together with `maxUnavailable` (the chart fails). |
| `keepSnapshotsOnUninstall` | `true` | Keep the snapshot CRDs and every VolumeSnapshot, VolumeSnapshotContent and VolumeSnapshotClass when the release is uninstalled (`helm.sh/resource-policy: keep`). Set `false` and upgrade before uninstalling to delete them. A later install with the same release name adopts the kept CRDs. |

## 2.1. Upgrading from 1.1.0

1.2.0 ships snapshot-controller v8.7.0 (was v7.0.1) from `vcr.vngcloud.vn/81-vks-public/snapshot-controller`
(a mirror of `registry.k8s.io/sig-storage/snapshot-controller`), with the v8.7.0 upstream CRDs and RBAC
(`volumesnapshotcontents/status`: `patch` only; `volumesnapshots`: adds `create`). The values keys are unchanged
apart from the new `keepSnapshotsOnUninstall`, which keeps the CRDs on uninstall by default: chart 1.1.0 deleted
them, and every snapshot object with them. Only the `v1` snapshot API is served, as in 1.1.0.

## 2.2. Upgrading from 1.0.0
1.1.0 removed the `snapshotController` object; the chart fails if it is still set. Move the keys:

| 1.0.0 | 1.1.0 |
|---|---|
| `snapshotController.replicas` | `replicaCount` |
| `snapshotController.image.*` | `image.*` |
| `snapshotController.logLevel` | `logLevel` |
| `snapshotController.resources` | `resources` |

With `helm upgrade --reuse-values` the old object is carried over: use `--reset-then-reuse-values` or pass the
new values explicitly.
