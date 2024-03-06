# VNGCLOUD Ingress Controller

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)
![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![Github Pages](https://img.shields.io/badge/github%20pages-121013?style=for-the-badge&logo=github&logoColor=white)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

![prod-env](https://badgen.net/badge/PRODUCTION/environment/blue?icon=github)

<hr>

# Prerequisites

- Helm 3.0+
- `KUBECONFIG` environment variable pointing to the `.kubeconfig` file with access to your Kubernetes cluster.

# Install `vngcloud-ingress-controller` on vContainer Kubernetes clusters

- Following the below steps to install `vngcloud-ingress-controller` on your Kubernetes cluster:
  - **Step 1**: Add the `vks-helm-charts` Helm repository:

    ```
    helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts
    helm repo update
    ```

  - **Step 2**: Install `vngcloud-ingress-controller`:

    ```
    helm install vngcloud-ingress-controller vks-helm-charts/vngcloud-ingress-controller \
      --set cloudConfig.global.clientID=__________________________ \
      --set cloudConfig.global.clientSecret=__________________________ \
      --set cloudConfig.clusterID=__________________________
    ```
