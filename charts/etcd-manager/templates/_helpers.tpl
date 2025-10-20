{{/*
Expand the name of the chart.
*/}}
{{- define "etcd-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "etcd-manager.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "etcd-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "etcd-manager.labels" -}}
helm.sh/chart: {{ include "etcd-manager.chart" . }}
{{ include "etcd-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "etcd-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "etcd-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Cert Checker ServiceAccount name
*/}}
{{- define "etcd-manager.certChecker.serviceAccountName" -}}
{{- if .Values.certChecker.serviceAccount.create }}
{{- default (printf "%s-cert-checker" (include "etcd-manager.fullname" .)) .Values.certChecker.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.certChecker.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Cert Renewal ServiceAccount name
*/}}
{{- define "etcd-manager.certRenewal.serviceAccountName" -}}
{{- if .Values.certRenewal.serviceAccount.create }}
{{- default (printf "%s-cert-renewal" (include "etcd-manager.fullname" .)) .Values.certRenewal.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.certRenewal.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Cert Checker labels
*/}}
{{- define "etcd-manager.certChecker.labels" -}}
{{ include "etcd-manager.labels" . }}
app.kubernetes.io/component: cert-checker
{{- end }}

{{/*
Cert Renewal labels
*/}}
{{- define "etcd-manager.certRenewal.labels" -}}
{{ include "etcd-manager.labels" . }}
app.kubernetes.io/component: cert-renewal
{{- end }}

{{/*
Return the secret name for cert renewal
*/}}
{{- define "etcd-manager.certRenewal.secretName" -}}
{{- if .Values.certRenewal.secrets.existingSecret }}
{{- .Values.certRenewal.secrets.existingSecret }}
{{- else }}
{{- default (printf "%s-secrets" .Values.certRenewal.name) .Values.certRenewal.secrets.name }}
{{- end }}
{{- end }}

{{/*
Return the config map name for cert renewal
*/}}
{{- define "etcd-manager.certRenewal.configMapName" -}}
{{- printf "%s-config" .Values.certRenewal.name }}
{{- end }}