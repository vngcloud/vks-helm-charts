# vMonitor Plaform Metric Agent

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square) ![AppVersion: 1.26.2](https://img.shields.io/badge/AppVersion-1.26.2-informational?style=flat-square)

[vMonitor Platform Metric](https://www.vngcloud.vn/en/product/vmonitor-platform-metric) is a service that continuously monitors the performance of all resources on your system. This chart adds the vMonitor Platform Metric Agent to all nodes in your Kubernetes cluster via a DaemonSet. It also optionally deploy and collect [kube-state-metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) which support deep monitoring Kubernetes resources.

## How to use vMonitor Platform repository

```
helm repo add vmonitor-platform https://vngcloud.github.io/helm-charts-vmonitor
helm repo update
```

## Kubernetes compatibility versions

| Name       | Version |
| ---------- | ------- |
| Kubernetes | >= 1.20 |

Note that: vMonitor Metrics Agent also supports Kubernetes Cluster version < 1.20, see [vMonitor Platform Metrics Agent legacy](https://docs.vngcloud.vn/display/ONVINA/Kubernetes) for more information

## Requirements

| Repository                                         | Name               | Version |
| -------------------------------------------------- | ------------------ | ------- |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 4.20.0  |

## Quick start

The vMonitor Platform Metric Node Agent runs in a DaemonSet.
The vMonitor Platform Metric Agent that collects kube-state-metrics runs in a Deployment.

### Installing the vMonitor Platform Metrics Chart

To install the chart with the release name 'vmonitor-metric-agent', retrieve or create the IAM credentials from the [IAM Dashboard](https://hcm-3.console.vngcloud.vn/iam/service-accounts) and run

```bash
helm install vmonitor-metric-agent vmonitor-platform/vmonitor-metric-agent \
 --set vmonitor.iamClientID=YOUR_CLIENT_ID_XXXXXXXXXXXXXXXXXXX \
 --set vmonitor.iamClientSecret=YOUR_CLIENT_SECRET_XXXXXXXXXXXXXXX \
 --set vmonitor.clusterName=my-cluster-k8s \
```

To install the chart in specific namespace using the following command

```bash
helm install -n <your_namespace> vmonitor-metric-agent vmonitor-platform/vmonitor-metric-agent \
 --set vmonitor.iamClientID=YOUR_CLIENT_ID_XXXXXXXXXXXXXXXXXXX \
 --set vmonitor.iamClientSecret=YOUR_CLIENT_SECRET_XXXXXXXXXXXXXXX \
 --set vmonitor.clusterName=my-cluster-k8s \
```

Run the following command using `kubectl` and make sure all pods are in the `Running state`

```bash
kubectl get pod <-n your_namespace> | grep "vmonitor-metric-agent"
```

### Uninstalling the chart

To uninstall/delete the `vmonitor-metric-agent` deployment:

```bash
helm uninstall vmonitor-metric-agent
```

The command removes all the Kubernetes resources associated with the chart and deletes the release.

## Configuration

For the configuration management to become easier, you only need to create a new YAML file that specifies the values for the chart parameters should be used to configure the chart. `Any parameters not specified in this file` will default to those set in [values.yaml](https://github.com/vngcloud/helm-charts-vmonitor/blob/main/charts/vmonitor-metric-agent/values.yaml)

Export default values of vmonitor-metric-agent chart to file values.yaml:

```bash
helm show values vmonitor-platform/vmonitor-metric-agent > values.yaml
```

Create an empty 'vmonitor-values.yaml'
Set the following parameters in your `vmonitor-values.yaml` file to change the collect and flush metric interval:

```yaml
nodeAgent:
  config:
    agent:
      interval: "10s"
      flush_interval: "10s"
kubeStateMetricsAgent:
  config:
    agent:
      interval: "10s"
      flush_interval: "10s"
```

Install or upgrade the vMonitor Platform Metrics Helm chart with the new `vmonitor-values.yaml` file:

```bash
helm install -f vmonitor-values.yaml vmonitor-metric-agent vmonitor-platform/vmonitor-metric-agent
```

OR

```bash
helm upgrade -f vmonitor-values.yaml --reuse-values vmonitor-metric-agent vmonitor-platform/vmonitor-metric-agent
```

See the [All configuration options](#all-configuration-options) section to discover the description of all the available configuration.

## All configuration options

The following table contains the configurable parameters available in the vMonitor Platform Metric Agent chart and their default values.

### Configuration and their default values.

| Configuration                              | Type   | Default                                                    | Description                                                                                                                                                                                                          |
| ------------------------------------------ | ------ | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| image.repo                                 | string | `"vcr.vngcloud.vn/81-vmp-public/vmonitor-metrics-agent"`                        | vMonitor Platform Metric Agent image name to use                                                                                                                                                                     |
| image.tag                                  | string | `"1.26.0-2.0.2"`                                           | Define the Agent version to use                                                                                                                                                                                      |
| image.pullPolicy                           | string | `"IfNotPresent"`                                           | Agent image pull policy                                                                                                                                                                                              |
| vmonitor.kubeStateMetricsEnabled           | bool   | `true`                                                     | If false, install vMonitor Platform Metric Agent without deploy the kube-state-metrics deployment (Use the kube-state-metrics that is already deployed using kubeStateMetricsAgent.useCustomKubeStateMetricEndpoint) |
| vmonitor.vmonitorSite                      | string | `"monitoring-agent.vngcloud.vn"`                           | The site of vMonitor Platform receive metric from agent                                                                                                                                                              |
| vmonitor.iamURL                            | string | `"https://iamapis.vngcloud.vn/accounts-api/v2/auth/token"` | Endpoint for IAM Authentication                                                                                                                                                                                      |
| vmonitor.iamClientID                       | string | `nil`                                                      | Your IAM Client ID                                                                                                                                                                                                   |
| vmonitor.iamClientSecret                   | string | `nil`                                                      | Your IAM Client Secret                                                                                                                                                                                               |
| vmonitor.clusterName                       | string | `"cluster-k8s"`                                                      | Set a unique Kubernetes Cluster Name for filtering hosts easily                                                                                                                                                      |
| nodeAgent.config.agent.interval   | string    | `"30s"`                                                     | Interval for collecting data from Kubernetes node                                                                                                          |
| nodeAgent.config.agent.metric_batch_size   | int    | `1000`                                                     | Control the size of each write batch that vMonitor Platform Metric Agent send to the vMonitor Platform site                                                                                                          |
| nodeAgent.config.agent.metric_buffer_limit | int    | `100000`                                                   | Max metric buffer size when Agent writes are failing to the vMonitor Platform site                                                                                                                                   |
| nodeAgent.config.agent.flush_interval | string    | `"30s"`                                                   | Interval for flushing (writing) data to the vMonitor Platform site. This value should not be set lower tan the nodeAgent.config.agent.interval (collection interval)                                                                                                                                  |
| nodeAgent.resources | object | `{}` | Resource requests and limits for the Agent. |
| nodeAgent.nodeSelector | object | `{}` | Allow the Agent DaemonSet to schedule only on selected nodes |
| nodeAgent.tolerations | list | `[]` | Allow the Agent DaemonSet to schedule on tainted nodes |
| nodeAgent.affinity | object | `{}` | Allow the Agent DaemonSet to schedule using affinity rules |
| kubeStateMetricsAgent.enabled           | bool   | `true`                                                     | If false, do not deploy vMonitor Platform Metric Agent that collects metrics from the kube-state-metrics |
| kubeStateMetricsAgent.useCustomKubeStateMetricEndpoint.enabled           | bool   | `false`                                                     | If true, using the custom endpoint for collecting the kube-state-metrics |
| kubeStateMetricsAgent.useCustomKubeStateMetricEndpoint.endpoint                       | string | `"http://example-kube-state-metrics.namespace:8080/metrics"`                                                      | Custom endpoint for collecting the kube-state-metrics `(required kubeStateMetricsAgent.useCustomKubeStateMetricEndpoint.enabled=true to take effect)`
| kubeStateMetricsAgent.config.agent.interval   | string    | `"30s"`                                                     | Interval for collecting data from Kubernetes node                                                                                                          |
| kubeStateMetricsAgent.config.agent.metric_batch_size   | int    | `1000`                                                     | Control the size of each write batch that vMonitor Platform Metric Agent send to the vMonitor Platform site                                                                                                          |
| kubeStateMetricsAgent.config.agent.metric_buffer_limit | int    | `100000`                                                   | Max metric buffer size when Agent writes are failing to the vMonitor Platform site                                                                                                                                   |
| kubeStateMetricsAgent.config.agent.flush_interval | string    | `"30s"`                                                   | Interval for flushing (writing) data to the vMonitor Platform site. This value should not be set lower tan the nodeAgent.config.agent.interval (collection interval)                                                                                                                                  |
| kubeStateMetricsAgent.resources | object | `{}` | Resource requests and limits for the Kube State Metrics Agent. |
| kubeStateMetricsAgent.nodeSelector | object | `{}` | Allow Kube State Metrics Agent Deployment to schedule on selected nodes |
| kubeStateMetricsAgent.tolerations | list | `[]` | Allow Kube State Metrics Agent Deployment to schedule on tainted nodes |
| kubeStateMetricsAgent.affinity | object | `{}` | Allow Kube State Metrics Agent Deployment to schedule using affinity rules |
| kube-state-metrics.image.repository | string | `"vcr.vngcloud.vn/81-vmp-public/kube-state-metrics"` | Default kube-state-metrics image repository. |
| kube-state-metrics.rbac.create | bool | `true` | If true, create & use RBAC resources |
| kube-state-metrics.resources | object | `{}` | Resource requests and limits for the kube-state-metrics container. |
| kube-state-metrics.serviceAccount.create | bool | `true` | If true, create ServiceAccount, require rbac kube-state-metrics.rbac.create true |
| kube-state-metrics.serviceAccount.name | string | `nil` | The name of the ServiceAccount to use. |