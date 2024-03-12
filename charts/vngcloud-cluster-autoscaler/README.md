# vngcloud-cluster-autoscaler

Scales Kubernetes worker nodes within autoscaling groups.

## TL;DR

```console
$ helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts

# Method 1 - Using Autodiscovery
$ helm install vngcloud-cluster-autoscaler vks-helm-charts/vngcloud-cluster-autoscaler \
    --set 'autoDiscovery.clusterName'=<CLUSTER NAME>

# Method 2 - Specifying groups manually
$ helm install vngcloud-cluster-autoscaler vks-helm-charts/vngcloud-cluster-autoscaler \
    --set "autoscalingGroups[0].name=your-asg-name" \
    --set "autoscalingGroups[0].maxSize=10" \
    --set "autoscalingGroups[0].minSize=1"
```

## Introduction

This chart bootstraps a cluster-autoscaler deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Helm 3+
- Kubernetes 1.8+
  - [Older versions](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler#releases) may work by overriding the `image`. Cluster autoscaler internally simulates the scheduler and bugs between mismatched versions may be subtle.
- Azure AKS specific Prerequisites:
  - Kubernetes 1.10+ with RBAC-enabled.

## Installing the Chart

**By default, no deployment is created and nothing will autoscale**.

You must provide some minimal configuration, either to specify instance groups or enable auto-discovery. It is not recommended to do both.

Either:

- Set `autoDiscovery.clusterName` and provide additional autodiscovery options if necessary **or**
- Set static node group configurations for one or more node groups (using `autoscalingGroups` or `autoscalingGroupsnamePrefix`).

To create a valid configuration, follow instructions for your cloud provider:

- [Cluster API](#cluster-api)

### Templating the autoDiscovery.clusterName

The cluster name can be templated in the `autoDiscovery.clusterName` variable. This is useful when the cluster name is dynamically generated based on other values coming from external systems like Argo CD or Flux. This also allows you to use global Helm values to set the cluster name, e.g., `autoDiscovery.clusterName=\{\{ .Values.global.clusterName }}`, so that you don't need to set it in more than 1 location in the values file.

### Cluster-API

`cloudProvider: clusterapi` must be set, and then one or more of

- `autoDiscovery.clusterName`
- or `autoDiscovery.labels`

See [here](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/clusterapi/README.md#configuring-node-group-auto-discovery) for more details.

Additional config parameters available, see the `values.yaml` for more details

- `clusterAPIMode`
- `clusterAPIKubeconfigSecret`
- `clusterAPIWorkloadKubeconfigPath`
- `clusterAPICloudConfigPath`

## Uninstalling the Chart

To uninstall `my-release`:

```console
$ helm uninstall my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

> **Tip**: List all releases using `helm list` or start clean with `helm uninstall my-release`

## Troubleshooting

The chart will succeed even if the container arguments are incorrect. A few minutes after starting `kubectl logs -l "app=aws-cluster-autoscaler" --tail=50` should loop through something like

```
polling_autoscaler.go:111] Poll finished
static_autoscaler.go:97] Starting main loop
utils.go:435] No pod using affinity / antiaffinity found in cluster, disabling affinity predicate for this loop
static_autoscaler.go:230] Filtering out schedulables
```

If not, find a pod that the deployment created and `describe` it, paying close attention to the arguments under `Command`. e.g.:

```
Containers:
  cluster-autoscaler:
    Command:
      ./cluster-autoscaler
      --cloud-provider=aws
# if specifying ASGs manually
      --nodes=1:10:your-scaling-group-name
# if using autodiscovery
      --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<ClusterName>
      --v=4
```

### PodSecurityPolicy

Though enough for the majority of installations, the default PodSecurityPolicy _could_ be too restrictive depending on the specifics of your release. Please make sure to check that the template fits with any customizations made or disable it by setting `rbac.pspEnabled` to `false`.

### VerticalPodAutoscaler

The CA Helm Chart can install a [`VerticalPodAutoscaler`](https://github.com/kubernetes/autoscaler/blob/master/vertical-pod-autoscaler/README.md) object from Chart version `9.27.0`
onwards for the Cluster Autoscaler Deployment to scale the CA as appropriate, but for that, we
need to install the VPA to the cluster separately. A VPA can help minimize wasted resources
when usage spikes periodically or remediate containers that are being OOMKilled.

The following example snippet can be used to install VPA that allows scaling down from the default recommendations of the deployment template:

```yaml
vpa:
  enabled: true
  containerPolicy:
    minAllowed:
      cpu: 20m
      memory: 50Mi
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalLabels | object | `{}` | Labels to add to each object of the chart. |
| affinity | object | `{}` | Affinity for pod assignment |
| autoDiscovery.clusterName | string | `nil` | Enable autodiscovery for `cloudProvider=aws`, for groups matching `autoDiscovery.tags`. autoDiscovery.clusterName -- Enable autodiscovery for `cloudProvider=azure`, using tags defined in https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/azure/README.md#auto-discovery-setup. Enable autodiscovery for `cloudProvider=clusterapi`, for groups matching `autoDiscovery.labels`. Enable autodiscovery for `cloudProvider=gce`, but no MIG tagging required. Enable autodiscovery for `cloudProvider=magnum`, for groups matching `autoDiscovery.roles`. |
| autoDiscovery.labels | list | `[]` | Cluster-API labels to match  https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/clusterapi/README.md#configuring-node-group-auto-discovery |
| autoDiscovery.roles | list | `["worker"]` | Magnum node group roles to match. |
| autoDiscovery.tags | list | `["k8s.io/cluster-autoscaler/enabled","k8s.io/cluster-autoscaler/{{ .Values.autoDiscovery.clusterName }}"]` | ASG tags to match, run through `tpl`. |
| autoscalingGroups | list | `[]` | For AWS, Azure AKS or Magnum. At least one element is required if not using `autoDiscovery`. For example: <pre> - name: asg1<br />   maxSize: 2<br />   minSize: 1 </pre> |
| autoscalingGroupsnamePrefix | list | `[]` | For GCE. At least one element is required if not using `autoDiscovery`. For example: <pre> - name: ig01<br />   maxSize: 10<br />   minSize: 0 </pre> |
| awsAccessKeyID | string | `""` | AWS access key ID ([if AWS user keys used](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#using-aws-credentials)) |
| awsRegion | string | `"us-east-1"` | AWS region (required if `cloudProvider=aws`) |
| awsSecretAccessKey | string | `""` | AWS access secret key ([if AWS user keys used](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#using-aws-credentials)) |
| azureClientID | string | `""` | Service Principal ClientID with contributor permission to Cluster and Node ResourceGroup. Required if `cloudProvider=azure` |
| azureClientSecret | string | `""` | Service Principal ClientSecret with contributor permission to Cluster and Node ResourceGroup. Required if `cloudProvider=azure` |
| azureResourceGroup | string | `""` | Azure resource group that the cluster is located. Required if `cloudProvider=azure` |
| azureSubscriptionID | string | `""` | Azure subscription where the resources are located. Required if `cloudProvider=azure` |
| azureTenantID | string | `""` | Azure tenant where the resources are located. Required if `cloudProvider=azure` |
| azureUseManagedIdentityExtension | bool | `false` | Whether to use Azure's managed identity extension for credentials. If using MSI, ensure subscription ID, resource group, and azure AKS cluster name are set. You can only use one authentication method at a time, either azureUseWorkloadIdentityExtension or azureUseManagedIdentityExtension should be set. |
| azureUseWorkloadIdentityExtension | bool | `false` | Whether to use Azure's workload identity extension for credentials. See the project here: https://github.com/Azure/azure-workload-identity for more details. You can only use one authentication method at a time, either azureUseWorkloadIdentityExtension or azureUseManagedIdentityExtension should be set. |
| azureVMType | string | `"vmss"` | Azure VM type. |
| cloudConfigPath | string | `""` | Configuration file for cloud provider. |
| cloudProvider | string | `"aws"` | The cloud provider where the autoscaler runs. Currently only `gce`, `aws`, `azure`, `magnum` and `clusterapi` are supported. `aws` supported for AWS. `gce` for GCE. `azure` for Azure AKS. `magnum` for OpenStack Magnum, `clusterapi` for Cluster API. |
| clusterAPICloudConfigPath | string | `"/etc/kubernetes/mgmt-kubeconfig"` | Path to kubeconfig for connecting to Cluster API Management Cluster, only used if `clusterAPIMode=kubeconfig-kubeconfig or incluster-kubeconfig` |
| clusterAPIConfigMapsNamespace | string | `""` | Namespace on the workload cluster to store Leader election and status configmaps |
| clusterAPIKubeconfigSecret | string | `""` | Secret containing kubeconfig for connecting to Cluster API managed workloadcluster Required if `cloudProvider=clusterapi` and `clusterAPIMode=kubeconfig-kubeconfig,kubeconfig-incluster or incluster-kubeconfig` |
| clusterAPIMode | string | `"incluster-incluster"` | Cluster API mode, see https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/clusterapi/README.md#connecting-cluster-autoscaler-to-cluster-api-management-and-workload-clusters Syntax: workloadClusterMode-ManagementClusterMode for `kubeconfig-kubeconfig`, `incluster-kubeconfig` and `single-kubeconfig` you always must mount the external kubeconfig using either `extraVolumeSecrets` or `extraMounts` and `extraVolumes` if you dont set `clusterAPIKubeconfigSecret`and thus use an in-cluster config or want to use a non capi generated kubeconfig you must do so for the workload kubeconfig as well |
| clusterAPIWorkloadKubeconfigPath | string | `"/etc/kubernetes/value"` | Path to kubeconfig for connecting to Cluster API managed workloadcluster, only used if `clusterAPIMode=kubeconfig-kubeconfig or kubeconfig-incluster` |
| containerSecurityContext | object | `{}` | [Security context for container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |
| deployment.annotations | object | `{}` | Annotations to add to the Deployment object. |
| dnsPolicy | string | `"ClusterFirst"` | Defaults to `ClusterFirst`. Valid values are: `ClusterFirstWithHostNet`, `ClusterFirst`, `Default` or `None`. If autoscaler does not depend on cluster DNS, recommended to set this to `Default`. |
| envFromConfigMap | string | `""` | ConfigMap name to use as envFrom. |
| envFromSecret | string | `""` | Secret name to use as envFrom. |
| expanderPriorities | object | `{}` | The expanderPriorities is used if `extraArgs.expander` contains `priority` and expanderPriorities is also set with the priorities. If `extraArgs.expander` contains `priority`, then expanderPriorities is used to define cluster-autoscaler-priority-expander priorities. See: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/expander/priority/readme.md |
| extraArgs | object | `{"logtostderr":true,"stderrthreshold":"info","v":4}` | Additional container arguments. Refer to https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-parameters-to-ca for the full list of cluster autoscaler parameters and their default values. Everything after the first _ will be ignored allowing the use of multi-string arguments. |
| extraEnv | object | `{}` | Additional container environment variables. |
| extraEnvConfigMaps | object | `{}` | Additional container environment variables from ConfigMaps. |
| extraEnvSecrets | object | `{}` | Additional container environment variables from Secrets. |
| extraVolumeMounts | list | `[]` | Additional volumes to mount. |
| extraVolumeSecrets | object | `{}` | Additional volumes to mount from Secrets. |
| extraVolumes | list | `[]` | Additional volumes. |
| fullnameOverride | string | `""` | String to fully override `cluster-autoscaler.fullname` template. |
| hostNetwork | bool | `false` | Whether to expose network interfaces of the host machine to pods. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.pullSecrets | list | `[]` | Image pull secrets |
| image.repository | string | `"registry.k8s.io/autoscaling/cluster-autoscaler"` | Image repository |
| image.tag | string | `"v1.29.0"` | Image tag |
| kubeTargetVersionOverride | string | `""` | Allow overriding the `.Capabilities.KubeVersion.GitVersion` check. Useful for `helm template` commands. |
| kwokConfigMapName | string | `"kwok-provider-config"` | configmap for configuring kwok provider |
| magnumCABundlePath | string | `"/etc/kubernetes/ca-bundle.crt"` | Path to the host's CA bundle, from `ca-file` in the cloud-config file. |
| magnumClusterName | string | `""` | Cluster name or ID in Magnum. Required if `cloudProvider=magnum` and not setting `autoDiscovery.clusterName`. |
| nameOverride | string | `""` | String to partially override `cluster-autoscaler.fullname` template (will maintain the release name) |
| nodeSelector | object | `{}` | Node labels for pod assignment. Ref: https://kubernetes.io/docs/user-guide/node-selection/. |
| podAnnotations | object | `{}` | Annotations to add to each pod. |
| podDisruptionBudget | object | `{"maxUnavailable":1}` | Pod disruption budget. |
| podLabels | object | `{}` | Labels to add to each pod. |
| priorityClassName | string | `"system-cluster-critical"` | priorityClassName |
| priorityConfigMapAnnotations | object | `{}` | Annotations to add to `cluster-autoscaler-priority-expander` ConfigMap. |
| prometheusRule.additionalLabels | object | `{}` | Additional labels to be set in metadata. |
| prometheusRule.enabled | bool | `false` | If true, creates a Prometheus Operator PrometheusRule. |
| prometheusRule.interval | string | `nil` | How often rules in the group are evaluated (falls back to `global.evaluation_interval` if not set). |
| prometheusRule.namespace | string | `"monitoring"` | Namespace which Prometheus is running in. |
| prometheusRule.rules | list | `[]` | Rules spec template (see https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/api.md#rule). |
| rbac.clusterScoped | bool | `true` | if set to false will only provision RBAC to alter resources in the current namespace. Most useful for Cluster-API |
| rbac.create | bool | `true` | If `true`, create and use RBAC resources. |
| rbac.pspEnabled | bool | `false` | If `true`, creates and uses RBAC resources required in the cluster with [Pod Security Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) enabled. Must be used with `rbac.create` set to `true`. |
| rbac.serviceAccount.annotations | object | `{}` | Additional Service Account annotations. |
| rbac.serviceAccount.automountServiceAccountToken | bool | `true` | Automount API credentials for a Service Account. |
| rbac.serviceAccount.create | bool | `true` | If `true` and `rbac.create` is also true, a Service Account will be created. |
| rbac.serviceAccount.name | string | `""` | The name of the ServiceAccount to use. If not set and create is `true`, a name is generated using the fullname template. |
| replicaCount | int | `1` | Desired number of pods |
| resources | object | `{}` | Pod resource requests and limits. |
| revisionHistoryLimit | int | `10` | The number of revisions to keep. |
| secretKeyRefNameOverride | string | `""` | Overrides the name of the Secret to use when loading the secretKeyRef for AWS and Azure env variables |
| securityContext | object | `{}` | [Security context for pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |
| service.annotations | object | `{}` | Annotations to add to service |
| service.create | bool | `true` | If `true`, a Service will be created. |
| service.externalIPs | list | `[]` | List of IP addresses at which the service is available. Ref: https://kubernetes.io/docs/user-guide/services/#external-ips. |
| service.labels | object | `{}` | Labels to add to service |
| service.loadBalancerIP | string | `""` | IP address to assign to load balancer (if supported). |
| service.loadBalancerSourceRanges | list | `[]` | List of IP CIDRs allowed access to load balancer (if supported). |
| service.portName | string | `"http"` | Name for service port. |
| service.servicePort | int | `8085` | Service port to expose. |
| service.type | string | `"ClusterIP"` | Type of service to create. |
| serviceMonitor.annotations | object | `{}` | Annotations to add to service monitor |
| serviceMonitor.enabled | bool | `false` | If true, creates a Prometheus Operator ServiceMonitor. |
| serviceMonitor.interval | string | `"10s"` | Interval that Prometheus scrapes Cluster Autoscaler metrics. |
| serviceMonitor.metricRelabelings | object | `{}` | MetricRelabelConfigs to apply to samples before ingestion. |
| serviceMonitor.namespace | string | `"monitoring"` | Namespace which Prometheus is running in. |
| serviceMonitor.path | string | `"/metrics"` | The path to scrape for metrics; autoscaler exposes `/metrics` (this is standard) |
| serviceMonitor.selector | object | `{"release":"prometheus-operator"}` | Default to kube-prometheus install (CoreOS recommended), but should be set according to Prometheus install. |
| tolerations | list | `[]` | List of node taints to tolerate (requires Kubernetes >= 1.6). |
| topologySpreadConstraints | list | `[]` | You can use topology spread constraints to control how Pods are spread across your cluster among failure-domains such as regions, zones, nodes, and other user-defined topology domains. (requires Kubernetes >= 1.19). |
| updateStrategy | object | `{}` | [Deployment update strategy](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy) |
| vpa | object | `{"containerPolicy":{},"enabled":false,"updateMode":"Auto"}` | Configure a VerticalPodAutoscaler for the cluster-autoscaler Deployment. |
| vpa.containerPolicy | object | `{}` | [ContainerResourcePolicy](https://github.com/kubernetes/autoscaler/blob/vertical-pod-autoscaler/v0.13.0/vertical-pod-autoscaler/pkg/apis/autoscaling.k8s.io/v1/types.go#L159). The containerName is always et to the deployment's container name. This value is required if VPA is enabled. |
| vpa.enabled | bool | `false` | If true, creates a VerticalPodAutoscaler. |
| vpa.updateMode | string | `"Auto"` | [UpdateMode](https://github.com/kubernetes/autoscaler/blob/vertical-pod-autoscaler/v0.13.0/vertical-pod-autoscaler/pkg/apis/autoscaling.k8s.io/v1/types.go#L124) |
