{{/*
Expand the name of the chart.
*/}}
{{- define "vconCcm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vconCcm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels and app labels
*/}}
{{- define "vconCcm.labels" -}}
app.kubernetes.io/name: {{ include "vconCcm.name" . }}
helm.sh/chart: {{ include "vconCcm.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "vconCcm.common.matchLabels" -}}
app: {{ template "vconCcm.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "vconCcm.common.metaLabels" -}}
chart: {{ template "vconCcm.chart" . }}
heritage: {{ .Release.Service }}
{{- end -}}

{{- define "vconCcm.controllermanager.matchLabels" -}}
component: controllermanager
{{ include "vconCcm.common.matchLabels" . }}
{{- end -}}

{{- define "vconCcm.controllermanager.labels" -}}
{{ include "vconCcm.controllermanager.matchLabels" . }}
{{ include "vconCcm.common.metaLabels" . }}
{{- end -}}

{{/*
Create cloud-config makro.
*/}}
{{- define "cloudConfig" -}}
[Cluster]
cluster-name = {{ .Values.cluster.clusterName | quote }}
cluster-id = {{ .Values.cluster.clusterID | quote }}

[Global]
identity-url = {{ .Values.cloudConfig.global.identityURL | quote }}
vserver-url = {{ .Values.cloudConfig.global.vserverURL | quote }}
client-id = {{ .Values.cloudConfig.global.clientID | quote}}
client-secret = {{ .Values.cloudConfig.global.clientSecret | quote }}

[VLB]
default-l4-package-id = {{ .Values.cloudConfig.vlb.defaultL4PackageID | quote }}
default-listener-allowed-cidrs = {{ .Values.cloudConfig.vlb.defaultListenerAllowedCIRDs| quote }}
default-idle-timeout-client = {{ .Values.cloudConfig.vlb.defaultIdleTimeoutClient | quote }}
default-idle-timeout-member = {{ .Values.cloudConfig.vlb.defaultIdleTimeoutMember | quote }}
default-idle-timeout-connection = {{ .Values.cloudConfig.vlb.defaultIdleTimeoutConnection | quote }}
default-pool-algorithm = {{ .Values.cloudConfig.vlb.defaultPoolAlgorithm | quote }}
default-monitor-healthy-threshold = {{ .Values.cloudConfig.vlb.defaultMonitorHealthyThreshold | quote }}
default-monitor-unhealthy-threshold = {{ .Values.cloudConfig.vlb.defaultMonitorUnhealthyThreshold | quote }}
default-monitor-timeout = {{ .Values.cloudConfig.vlb.defaultMonitorTimeout | quote }}
default-monitor-interval = {{ .Values.cloudConfig.vlb.defaultMonitorInterval | quote }}
default-monitor-http-method = {{ .Values.cloudConfig.vlb.defaultMonitorHttpMethod | quote }}
default-monitor-http-path = {{ .Values.cloudConfig.vlb.defaultMonitorHttpPath | quote }}
default-monitor-http-success-code = {{ .Values.cloudConfig.vlb.defaultMonitorHttpSuccessCode | quote }}
default-monitor-http-version = {{ .Values.cloudConfig.vlb.defaultMonitorHttpVersion | quote }}
default-monitor-http-domain-name = {{ .Values.cloudConfig.vlb.defaultMonitorHttpDomainName | quote }}
default-monitor-protocol = {{ .Values.cloudConfig.vlb.defaultMonitorProtocol | quote }}

{{- if .Chart.Version }}
[Metadata]
chart-version = {{ .Chart.Version | quote }}
{{- end }}
{{- end -}}

{{/*
Generate string of enabled controllers. Might have a trailing comma (,) which needs to be trimmed.
*/}}
{{- define "vconCcm.enabledControllers" }}
{{- range .Values.enabledControllers -}}{{ . }},{{- end -}}
{{- end }}
