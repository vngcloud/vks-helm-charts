# VNGCLOUD Ingress Controller

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)
![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![Github Pages](https://img.shields.io/badge/github%20pages-121013?style=for-the-badge&logo=github&logoColor=white)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

![prod-env](https://badgen.net/badge/PRODUCTION/environment/blue?icon=github)

## Prerequisites

- Helm 3.0+
- `KUBECONFIG` environment variable pointing to the `.kubeconfig` file with access to your Kubernetes cluster.

## Install `vngcloud-ingress-controller` on VKS clusters

- Following the below steps to install `vngcloud-ingress-controller` on your Kubernetes cluster:
  - **Option 1**: Install via Github:

    ```bash
    helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts
    helm repo update

    helm install vngcloud-ingress-controller vks-helm-charts/vngcloud-ingress-controller \
      --namespace kube-system \
      --set cloudConfig.global.clientID=__________________________ \
      --set cloudConfig.global.clientSecret=__________________________ \
      --set cluster.clusterID=__________________________
    ```

  - **Option 2**: Install via OCI-based registries

    ```bash
    helm install vngcloud-ingress-controller oci://vcr.vngcloud.vn/81-vks-public/vks-helm-charts/vngcloud-ingress-controller \
      --namespace kube-system \
      --set cloudConfig.global.clientID=__________________________ \
      --set cloudConfig.global.clientSecret=__________________________ \
      --set cluster.clusterID=__________________________
    ```
