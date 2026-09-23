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

# 2. About the snapshot CRDs
From chart version `1.1.0`, the three `snapshot.storage.k8s.io` CRDs are only
created by this chart when the cluster does not already serve them.

On a vKS cluster they normally arrive with the blockstorage CSI addon, which
ships them so that its `csi-snapshotter` sidecar has something to watch. This
chart then installs only the snapshot controller itself - the component that
turns a `VolumeSnapshot` into a `VolumeSnapshotContent`, and without which
snapshots do nothing.

The CRDs carry `helm.sh/resource-policy: keep`, so `helm uninstall` leaves them
in place along with every `VolumeSnapshot` object they hold.
