{{- define "node" }}
{{- if or (eq (default true .Values.node.enableLinux) true) }}
---
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: {{ .NodeName }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "vngcloud-blockstorage-csi-driver.labels" . | nindent 4 }}
  {{- with .Values.node.daemonSetAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if or (kindIs "float64" .Values.node.revisionHistoryLimit) (kindIs "int64" .Values.node.revisionHistoryLimit) }}
  revisionHistoryLimit: {{ .Values.node.revisionHistoryLimit }}
  {{- end }}
  selector:
    matchLabels:
      app: {{ .NodeName }}
      {{- include "vngcloud-blockstorage-csi-driver.selectorLabels" . | nindent 6 }}
  updateStrategy:
    {{- toYaml .Values.node.updateStrategy | nindent 4 }}
  template:
    metadata:
      labels:
        app: {{ .NodeName }}
        {{- include "vngcloud-blockstorage-csi-driver.labels" . | nindent 8 }}
        {{- if .Values.node.podLabels }}
        {{- toYaml .Values.node.podLabels | nindent 8 }}
        {{- end }}
      {{- with .Values.node.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- with .Values.node.affinity }}
      affinity: {{- toYaml . | nindent 8 }}
      {{- end }}
      nodeSelector:
        kubernetes.io/os: linux
        {{- with .Values.node.nodeSelector }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      serviceAccountName: {{ .Values.node.serviceAccount.name }}
      priorityClassName: {{ .Values.node.priorityClassName | default "system-node-critical" }}
      tolerations:
        {{- if .Values.node.tolerateAllTaints }}
        - operator: Exists
        {{- else }}
        {{- with .Values.node.tolerations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- end }}
      hostNetwork: {{ .Values.node.hostNetwork }}
      {{- with .Values.node.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: vngcloud-plugin
          image: {{ printf "%s%s:%s" (default "" .Values.image.containerRegistry) .Values.image.repository (default (printf "v%s" .Chart.AppVersion) (toString .Values.image.tag)) }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          command:
            - /bin/vngcloud-blockstorage-csi-driver
          args:
            - node
            - --endpoint=$(CSI_ENDPOINT)
            {{- with .Values.node.reservedVolumeAttachments }}
            - --reserved-volume-attachments={{ . }}
            {{- end }}
            {{- with .Values.node.volumeAttachLimit }}
            - --max-volumes-per-node={{ . }}
            {{- end }}
            {{- with .Values.node.loggingFormat }}
            - --logging-format={{ . }}
            {{- end }}
            - --v={{ .Values.node.logLevel }}
            {{- if .Values.node.otelTracing }}
            - --enable-otel-tracing=true
            {{- end}}
            {{- range .Values.node.additionalArgs }}
            - {{ . }}
            {{- end }}
          env:
            - name: CSI_ENDPOINT
              value: unix://csi/csi.sock
            - name: CSI_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            {{- if or (not .Values.node.volumeAttachLimit) (eq .Values.node.volumeAttachLimit 0) }}
            - name: VNGCLOUD_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.vngcloudAccessSecret.name }}
                  key: keyId
            - name: VNGCLOUD_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.vngcloudAccessSecret.name }}
                  key: accessKey
            - name: VNGCLOUD_IDENTITY_ENDPOINT
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.vngcloudAccessSecret.name }}
                  key: identityEndpoint
            - name: VNGCLOUD_VSERVER_ENDPOINT
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.vngcloudAccessSecret.name }}
                  key: vserverEndpoint
            {{- end }}
            {{- if .Values.proxy.http_proxy }}
            {{- include "vngcloud-blockstorage-csi-driver.http-proxy" . | nindent 12 }}
            {{- end }}
            {{- with .Values.node.otelTracing }}
            - name: OTEL_SERVICE_NAME
              value: {{ .otelServiceName }}
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: {{ .otelExporterEndpoint }}
            {{- end }}
            {{- with .Values.node.env }}
            {{- . | toYaml | nindent 12 }}
            {{- end }}
          {{- with .Values.controller.envFrom }}
          envFrom:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: kubelet-dir
              mountPath: {{ .Values.node.kubeletPath }}
              mountPropagation: "Bidirectional"
            - name: plugin-dir
              mountPath: /csi
            - name: device-dir
              mountPath: /dev
          {{- with .Values.node.volumeMounts }}
          {{- toYaml . | nindent 12 }}
          {{- end }}
          ports:
            - name: healthz
              containerPort: 9808
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /healthz
              port: healthz
            initialDelaySeconds: 10
            timeoutSeconds: 3
            periodSeconds: 10
            failureThreshold: 5
          readinessProbe:
            httpGet:
              path: /healthz
              port: healthz
            initialDelaySeconds: 120
            timeoutSeconds: 30
            periodSeconds: 30
            failureThreshold: 10
          {{- with .Values.node.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.node.containerSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          lifecycle:
            preStop:
              exec:
                command: ["/bin/vngcloud-blockstorage-csi-driver", "pre-stop-hook"]
        - name: node-driver-registrar
          image: {{ printf "%s%s:%s" (default "" .Values.image.containerRegistry) .Values.sidecars.nodeDriverRegistrar.image.repository .Values.sidecars.nodeDriverRegistrar.image.tag }}
          imagePullPolicy: {{ default .Values.image.pullPolicy .Values.sidecars.nodeDriverRegistrar.image.pullPolicy }}
          args:
            - --csi-address=$(ADDRESS)
            - --kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)
            - --v={{ .Values.sidecars.nodeDriverRegistrar.logLevel }}
            {{- range .Values.sidecars.nodeDriverRegistrar.additionalArgs }}
            - {{ . }}
            {{- end }}
          env:
            - name: ADDRESS
              value: /csi/csi.sock
            - name: DRIVER_REG_SOCK_PATH
              value: {{ printf "%s/plugins/bs.csi.vngcloud.vn/csi.sock" (trimSuffix "/" .Values.node.kubeletPath) }}
            {{- if .Values.proxy.http_proxy }}
            {{- include "vngcloud-blockstorage-csi-driver.http-proxy" . | nindent 12 }}
            {{- end }}
            {{- with .Values.sidecars.nodeDriverRegistrar.env }}
            {{- . | toYaml | nindent 12 }}
            {{- end }}
          {{- with .Values.controller.envFrom }}
          envFrom:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          {{- with .Values.sidecars.nodeDriverRegistrar.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: plugin-dir
              mountPath: /csi
            - name: registration-dir
              mountPath: /registration
            - name: probe-dir
              mountPath: {{ printf "%s/plugins/bs.csi.vngcloud.vn/" (trimSuffix "/" .Values.node.kubeletPath) }}
          {{- with default .Values.node.resources .Values.sidecars.nodeDriverRegistrar.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.sidecars.nodeDriverRegistrar.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
        - name: liveness-probe
          image: {{ printf "%s%s:%s" (default "" .Values.image.containerRegistry) .Values.sidecars.livenessProbe.image.repository .Values.sidecars.livenessProbe.image.tag }}
          imagePullPolicy: {{ default .Values.image.pullPolicy .Values.sidecars.livenessProbe.image.pullPolicy }}
          args:
            - --csi-address=/csi/csi.sock
            {{- range .Values.sidecars.livenessProbe.additionalArgs }}
            - {{ . }}
            {{- end }}
          {{- with .Values.controller.envFrom }}
          envFrom:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: plugin-dir
              mountPath: /csi
          {{- with default .Values.node.resources .Values.sidecars.livenessProbe.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.sidecars.livenessProbe.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- if .Values.imagePullSecrets }}
      imagePullSecrets:
      {{- range .Values.imagePullSecrets }}
        - name: {{ . }}
      {{- end }}
      {{- end }}
      volumes:
        - name: kubelet-dir
          hostPath:
            path: {{ .Values.node.kubeletPath }}
            type: Directory
        - name: plugin-dir
          hostPath:
            path: {{ printf "%s/plugins/bs.csi.vngcloud.vn/" (trimSuffix "/" .Values.node.kubeletPath) }}
            type: DirectoryOrCreate
        - name: registration-dir
          hostPath:
            path: {{ printf "%s/plugins_registry/" (trimSuffix "/" .Values.node.kubeletPath) }}
            type: Directory
        - name: device-dir
          hostPath:
            path: /dev
            type: Directory
        - name: probe-dir
          {{- if .Values.node.probeDirVolume }}
          {{- toYaml .Values.node.probeDirVolume | nindent 10 }}
          {{- else }}
          emptyDir: {}
          {{- end }}
        {{- with .Values.node.volumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
{{- end }}
{{- end }}
