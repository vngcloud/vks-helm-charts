{{/*
Expand the name of the chart.
*/}}
{{- define "VIC.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "VIC.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels and app labels
*/}}
{{- define "VIC.labels" -}}
app.kubernetes.io/name: {{ include "VIC.name" . }}
helm.sh/chart: {{ include "VIC.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "VIC.common.matchLabels" -}}
app: {{ template "VIC.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "VIC.common.metaLabels" -}}
chart: {{ template "VIC.chart" . }}
heritage: {{ .Release.Service }}
{{- end -}}

{{- define "VIC.selector.matchLabels" -}}
component: ingress-controller
{{ include "VIC.common.matchLabels" . }}
{{- end -}}

{{- define "VIC.template.labels" -}}
{{ include "VIC.selector.matchLabels" . }}
{{ include "VIC.common.metaLabels" . }}
{{- end -}}

