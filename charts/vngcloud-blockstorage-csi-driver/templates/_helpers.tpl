{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "vngcloud-blockstorage-csi-driver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
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
{{- if ne .Release.Name "kustomize" }}
helm.sh/chart: {{ include "vngcloud-blockstorage-csi-driver.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/component: csi-driver
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end }}
{{- end -}}


{{/*
Common selector labels
*/}}
{{- define "vngcloud-blockstorage-csi-driver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vngcloud-blockstorage-csi-driver.name" . }}
{{- if ne .Release.Name "kustomize" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
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
