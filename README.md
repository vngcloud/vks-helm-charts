# VKS Helm Charts

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)
![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![Github Pages](https://img.shields.io/badge/github%20pages-121013?style=for-the-badge&logo=github&logoColor=white)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/vks-helm-charts)](https://artifacthub.io/packages/search?repo=vks-helm-charts)

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions of the packages.

You can then run `helm search repo vks-helm-charts` to see the charts.

### Cert Manager

- The `cert-manager` chart is a wrapper around the upstream `cert-manager` chart. It adds some additional configuration options and a few extra resources.
- The upstream chart is available at [GitHub](https://github.com/cert-manager/cert-manager/tree/release-1.17/deploy/charts/cert-manager).
- Clone this repo and run `make release-manifests` to generate the upstream chart.
- Rewrite the defalut repository in the `values.yaml`.

To install the chart:

```bash
helm install \
  cert-manager oci://vcr.vngcloud.vn/81-vks-public/vks-helm-charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.2 \
  --set crds.enabled=true
```

## How to Copy Helm Charts from Community to this Repository

1. **Add the community helm repository**

   ```bash
   helm repo add <repo-name> <repo-url>
   helm repo update
   ```

   Example:

   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```

2. **Search and identify the chart version**

   ```bash
   helm search repo <repo-name>/<chart-name>
   ```

   Example:

   ```bash
   helm search repo bitnami/nginx
   ```

3. **Pull the chart to local directory**

   ```bash
   helm pull <repo-name>/<chart-name> --version <version> --untar --untardir ./charts/
   ```

   Example:

   ```bash
   helm pull bitnami/nginx --version 22.3.3 --untar --untardir ./charts/
   ```

4. **Navigate to the chart directory**

   ```bash
   cd ./charts/<chart-name>
   ```

5. **Review and modify the chart**

   - Check `Chart.yaml` for metadata
   - Review `values.yaml` for default configurations
   - Make a copy of docker image references to point to VCR if necessary
   - **Should not modify the original chart structure significantly to ease future updates**

6. **Validate the chart**

   ```bash
   helm lint .
   helm template . --debug
   ```

7. **Test the chart locally**

   ```bash
   helm install test-release . --dry-run --debug
   ```
