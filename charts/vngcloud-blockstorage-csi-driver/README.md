![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white) ![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689) ![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white) ![Github Pages](https://img.shields.io/badge/github%20pages-121013?style=for-the-badge&logo=github&logoColor=white) ![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

# VngCloud BlockStorage CSI Driver

![prod-env](https://badgen.net/badge/PRODUCTION/environment/blue?icon=github)

<hr>

# 1. Installation

## 1.1. Prerequisites

- Helm 3.0+
- `KUBECONFIG` environment variable pointing to the `.kubeconfig` file with access to your Kubernetes cluster.

## 1.2. Install `vngcloud-blockstorage-csi-driver` on Kubernetes clusters

- Following the below steps to install `vngcloud-blockstorage-csi-driver` on your Kubernetes cluster:

  - **Step 1**: Add the `vks-helm-charts` Helm repository:

    ```bash=
    helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts
    helm repo update
    ```

  - **Step 2**: Install `vngcloud-blockstorage-csi-driver`:

    ```bash=
    VNGCLOUD_CLIENT_ID=<put-your-client-id>
    VNGCLOUD_CLIENT_SECRET=<put-your-client-secret>
    VNGCLOUD_VKS_CLUSTER_ID=<put-your-vks-cluster-id>  # Optional

    helm install vngcloud-blockstorage-csi-driver vks-helm-charts/vngcloud-blockstorage-csi-driver \
      --replace --namespace kube-system \
      --set vngcloudAccessSecret.keyId=${VNGCLOUD_CLIENT_ID} \
      --set vngcloudAccessSecret.accessKey=${VNGCLOUD_CLIENT_SECRET} \
      --set vngcloudAccessSecret.vksClusterId=${VNGCLOUD_VKS_CLUSTER_ID}  # Optional
    ```

## 1.3. Upgrade

- Upgrade `vngcloud-blockstorage-csi-driver` to `latest` version.
  ```bash
  helm upgrade vngcloud-blockstorage-csi-driver vks-helm-charts/vngcloud-blockstorage-csi-driver -n kube-system
  ```

## 1.4. Uninstall

- Uninstall `vngcloud-blockstorage-csi-driver` from your Kubernetes cluster.
  ```bash
  helm uninstall vngcloud-blockstorage-csi-driver -n kube-system
  ```

# 2. Other features

## 2.1. Enable Snapshot feature

- To enable the snapshot feature, you **MUST** install the `vngcloud-snapshot-controller` along with the `vngcloud-blockstorage-csi-driver` Helm chart, as follows:
  ```bash=
  helm install vngcloud-snapshot-controller vks-helm-charts/vngcloud-snapshot-controller \
    --replace --namespace kube-system
  ```
