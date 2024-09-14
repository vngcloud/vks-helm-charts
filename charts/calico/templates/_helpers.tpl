{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "calicoCni.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "calicoCni.calicoKubeControllers.labels" -}}
k8s-app: calico-kube-controllers
{{- end -}}

{{- define "calicoCni.calicoKubeControllers.matchLabels" -}}
{{- include "calicoCni.calicoKubeControllers.labels" . }}
{{- end -}}

{{- define "calicoCni.calicoNode.labels" -}}
k8s-app: calico-node
{{- end -}}

{{- define "calicoCni.calicoNode.matchLabels" -}}
{{- include "calicoCni.calicoNode.labels" . }}
{{- end -}}

{{- define "calicoCni.calicoTypha.labels" -}}
k8s-app: calico-typha
{{- end -}}

{{- define "calicoCni.calicoTypha.matchLabels" -}}
{{- include "calicoCni.calicoTypha.labels" . }}
{{- end -}}

{{- define "calicoCni.calicoTypha.selector" -}}
{{- include "calicoCni.calicoTypha.labels" . }}
{{- end -}}