{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "vngcloud-blockstorage-csi-driver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vngcloud-blockstorage-csi-driver.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vngcloud-blockstorage-csi-driver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "vngcloud-blockstorage-csi-driver.labels" -}}
{{ include "vngcloud-blockstorage-csi-driver.selectorLabels" . }}
helm.sh/chart: {{ include "vngcloud-blockstorage-csi-driver.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/component: csi-driver
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end }}
{{- end -}}

{{/*
Common selector labels
*/}}
{{- define "vngcloud-blockstorage-csi-driver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vngcloud-blockstorage-csi-driver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Controller service account name
*/}}
{{- define "vngcloud-blockstorage-csi-driver.controllerServiceAccountName" -}}
{{- if .Values.controller.serviceAccount.create -}}
{{- default (printf "%s-controller-sa" (include "vngcloud-blockstorage-csi-driver.fullname" .)) .Values.controller.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.controller.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Node service account name
*/}}
{{- define "vngcloud-blockstorage-csi-driver.nodeServiceAccountName" -}}
{{- if .Values.node.serviceAccount.create -}}
{{- default (printf "%s-node-sa" (include "vngcloud-blockstorage-csi-driver.fullname" .)) .Values.node.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.node.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Convert the `--extra-tags` command line arg from a map.
*/}}
{{- define "vngcloud-blockstorage-csi-driver.extra-volume-tags" -}}
{{- $result := dict "pairs" (list) -}}
{{- range $key, $value := .Values.controller.extraVolumeTags -}}
{{- $noop := printf "%s=%v" $key $value | append $result.pairs | set $result "pairs" -}}
{{- end -}}
{{- if gt (len $result.pairs) 0 -}}
{{- printf "- \"--extra-tags=%s\"" (join "," $result.pairs) -}}
{{- end -}}
{{- end -}}

{{/*
Handle http proxy env vars
*/}}
{{- define "vngcloud-blockstorage-csi-driver.http-proxy" -}}
- name: HTTP_PROXY
  value: {{ .Values.proxy.http_proxy | quote }}
- name: HTTPS_PROXY
  value: {{ .Values.proxy.http_proxy | quote }}
- name: NO_PROXY
  value: {{ .Values.proxy.no_proxy | quote }}
{{- end -}}
