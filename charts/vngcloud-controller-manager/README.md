# VNG Cloud Controller Manager

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)
![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![Github Pages](https://img.shields.io/badge/github%20pages-121013?style=for-the-badge&logo=github&logoColor=white)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

![prod-env](https://badgen.net/badge/PRODUCTION/environment/blue?icon=github)

## Introduction

The `vngcloud-controller-manager` is a powerful Kubernetes plugin designed to streamline and enhance **network load balancing (L4 load-balancer)** within your clusters.

## Prerequisites

- Helm 3.0+
- `KUBECONFIG` environment variable pointing to the `.kubeconfig` file with access to your Kubernetes cluster.

## Install `vngcloud-controller-manager` on vContainer Kubernetes clusters

- Following the below steps to install `vngcloud-controller-manager` on your Kubernetes cluster:
  - **Step 1**: Add the `vks-helm-charts` Helm repository:

    ```bash
    helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts
    helm repo update
    ```

  - **Step 2**: Install `vngcloud-controller-manager`:

    ```bash
    helm install vngcloud-controller-manager vks-helm-charts/vngcloud-controller-manager --replace \
      --namespace kube-system \
      --set cloudConfig.global.clientID=<PUT_YOUR_CLIENT_ID> \
      --set cloudConfig.global.clientSecret=<PUT_YOUR_CLIENT_SECRET> \
      --set cluster.clusterName=<PUT_YOUR_CLUSTER_NAME>
      --set cluster.clusterID=<PUT_YOUR_CLUSTER_ID>
    ```
