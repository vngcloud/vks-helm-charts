{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "vcontainer-storage-interface.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vcontainer-storage-interface.fullname" -}}
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
{{- define "vcontainer-storage-interface.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "vcontainer-storage-interface.labels" -}}
app.kubernetes.io/name: {{ include "vcontainer-storage-interface.name" . }}
helm.sh/chart: {{ include "vcontainer-storage-interface.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}


{{/*
Create the name of the service account to use
*/}}
{{- define "vcontainer-storage-interface.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "vcontainer-storage-interface.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create unified labels for vcontainer-csi components
*/}}
{{- define "vcontainer-storage-interface.common.matchLabels" -}}
app: {{ template "vcontainer-storage-interface.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "vcontainer-storage-interface.common.metaLabels" -}}
chart: {{ template "vcontainer-storage-interface.chart" . }}
heritage: {{ .Release.Service }}
{{- if .Values.extraLabels }}
{{ toYaml .Values.extraLabels -}}
{{- end }}
{{- end -}}

{{- define "vcontainer-storage-interface.controllerplugin.matchLabels" -}}
component: controllerplugin
{{ include "vcontainer-storage-interface.common.matchLabels" . }}
{{- end -}}

{{- define "vcontainer-storage-interface.controllerplugin.labels" -}}
{{ include "vcontainer-storage-interface.controllerplugin.matchLabels" . }}
{{ include "vcontainer-storage-interface.common.metaLabels" . }}
{{- end -}}

{{- define "vcontainer-storage-interface.nodeplugin.matchLabels" -}}
component: nodeplugin
{{ include "vcontainer-storage-interface.common.matchLabels" . }}
{{- end -}}

{{- define "vcontainer-storage-interface.nodeplugin.labels" -}}
{{ include "vcontainer-storage-interface.nodeplugin.matchLabels" . }}
{{ include "vcontainer-storage-interface.common.metaLabels" . }}
{{- end -}}

{{- define "vcontainer-storage-interface.snapshot-controller.matchLabels" -}}
component: snapshot-controller
{{ include "vcontainer-storage-interface.common.matchLabels" . }}
{{- end -}}

{{- define "vcontainer-storage-interface.snapshot-controller.labels" -}}
{{ include "vcontainer-storage-interface.snapshot-controller.matchLabels" . }}
{{ include "vcontainer-storage-interface.common.metaLabels" . }}
{{- end -}}