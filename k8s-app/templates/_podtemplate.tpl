{{- define "k8s-app.podTemplate" }}
    metadata:
      labels:
        {{- include "k8s-app.selectorLabels" . | nindent 8 }}
        {{- if .Values.deployment.additionalPodLabels }}
          {{- toYaml .Values.deployment.additionalPodLabels | nindent 8 }}
        {{- end }}
        {{- if .Values.deployment.disableIstioInject }}
        sidecar.istio.io/inject: "false"
        {{- end }}
      {{- if .Values.deployment.additionalPodAnnotations }}
      annotations:
        {{- toYaml .Values.deployment.additionalPodAnnotations | nindent 8 }}
      {{- end }}
    spec:
      {{- if .Values.deployment.hostAliases }}
      hostAliases:      
        {{- toYaml .Values.deployment.hostAliases | nindent 6 }}
      {{- end }}
      {{- if .Values.deployment.initContainers }}
      initContainers:
      {{- range $key, $value := .Values.deployment.initContainers  }}
        - name: {{ $key }}
      {{- include "k8s-app.tplvalues.render" ( dict "value" $value "context" $ ) | nindent 10 }}
      {{- end }}
      {{- end }}
      {{- with .Values.deployment.nodeSelector }}
      nodeSelector:
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.tolerations }}
      tolerations:
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.affinity }}
      affinity:
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 10 }}
      {{- end }}
      {{- with .Values.deployment.imagePullSecrets }}      
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.deployment.hostNetwork }}
      hostNetwork: true
      {{- end }}
      {{- if .Values.rbac.serviceAccount.enabled }}
      {{- if .Values.rbac.serviceAccount.name }}
      serviceAccountName: {{ .Values.rbac.serviceAccount.name }}
      {{- else }}
      serviceAccountName: {{ template "k8s-app.name" $ }}
      {{- end }}
      {{- end }}
      {{- if .Values.deployment.securityContext }}
      securityContext:      
        {{ toYaml .Values.deployment.securityContext | indent 8 }}
      {{- end }}
      {{- if .Values.deployment.dnsConfig }}
      dnsConfig:      
      {{- toYaml .Values.deployment.dnsConfig | nindent 8 }}
      {{- end }}
      terminationGracePeriodSeconds: {{ .Values.deployment.terminationGracePeriodSeconds }}
      {{- if or (.Values.deployment.volumes) (and (eq .Values.persistence.enabled true) (eq .Values.persistence.mountPVC true) )}} 
      volumes:
        {{- if (eq .Values.persistence.mountPVC true) }}
        - name: {{ template "k8s-app.name" . }}-data
          persistentVolumeClaim:
            {{- if .Values.persistence.name }}
            claimName: {{ .Values.persistence.name }}
            {{- else }}
            claimName: {{ template "k8s-app.name" . }}-data
            {{- end }}
        {{- end }}
        {{- if .Values.deployment.volumes }}
        {{- range $key, $value := .Values.deployment.volumes  }}
        - name: {{ $key  }}
        {{- include "k8s-app.tplvalues.render" ( dict "value" $value "context" $ ) | nindent 10 }}
        {{- end }}
        {{- end }}
      {{- end }}
      containers:
        - name: {{ template "k8s-app.name" . }}
          image: "{{ .Values.deployment.image.repository }}{{ if .Values.deployment.image.tag }}:{{ .Values.deployment.image.tag }}{{ else }}@{{ .Values.deployment.image.digest }}{{ end }}"
          imagePullPolicy: {{ .Values.deployment.image.pullPolicy }}
          {{- with .Values.deployment.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.deployment.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if .Values.deployment.ports }}
          ports:
            {{- $hostNetwork := .Values.deployment.hostNetwork }}
            {{- range $name, $config := .Values.deployment.ports }}
            {{- if $config }}
            {{- if and $hostNetwork (and $config.hostPort $config.port) }}
              {{- if ne ($config.hostPort | int) ($config.port | int) }}
                {{- fail "ERROR: All hostPort must match their respective containerPort when `hostNetwork` is enabled" }}
              {{- end }}
            {{- end }}
            - name: {{ $name | quote }}
              containerPort: {{ default $config.port $config.containerPort }}
              {{- if $config.hostPort }}
              hostPort: {{ $config.hostPort }}
              {{- end }}
              protocol: {{ default "TCP" $config.protocol | quote }}
            {{- end }}
            {{- end }}
          {{- end }}
          {{- if .Values.deployment.envFrom }}
          envFrom:
          {{- range $value := .Values.deployment.envFrom }}
          {{- if (eq .type "configmap") }}
            - configMapRef:
                {{- if .name }}
                name: {{ include "k8s-app.tplvalues.render" ( dict "value" $value.name "context" $ ) }}
                {{- else if .nameSuffix }}
                name: {{ template "k8s-app.name" $ }}-{{ include "k8s-app.tplvalues.render" ( dict "value" $value.nameSuffix "context" $ ) }}
                {{- else }}
                name: {{ template "k8s-app.name" $ }}
                {{- end }}
          {{- end }}
          {{- if (eq .type "secret") }}
            - secretRef:
                {{- if .name }}
                name: {{ include "k8s-app.tplvalues.render" ( dict "value" $value.name "context" $ ) }}
                {{- else if .nameSuffix }}
                name: {{ template "k8s-app.name" $ }}-{{ include "k8s-app.tplvalues.render" ( dict "value" $value.nameSuffix "context" $ ) }}
                {{- else }}
                name: {{ template "k8s-app.name" $ }}
                {{- end }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- if .Values.deployment.env }}
          env:
          {{- range $key, $value := .Values.deployment.env }}
          - name: {{ include "k8s-app.tplvalues.render" ( dict "value" $key "context" $ ) }}
            {{- include "k8s-app.tplvalues.render" ( dict "value" $value "context" $ ) | nindent 12 }}
          {{- end }}
          {{- end }}
          {{- with .Values.deployment.probes }}
          {{- if .livenessProbe }}
          livenessProbe:
            {{- toYaml .livenessProbe | nindent 12 }}
          {{- end }}
          {{- if .readinessProbe }}
          readinessProbe:
            {{- toYaml .readinessProbe | nindent 12 }}
          {{- end }}
          {{- if .startupProbe }}
          startupProbe:
            {{- toYaml .startupProbe | nindent 12 }}
          {{- end }}
          {{- end }}
          {{- if or (.Values.deployment.volumeMounts) (and (eq .Values.persistence.enabled true) (eq .Values.persistence.mountPVC true) )}} 
          volumeMounts:
          {{- if (eq .Values.persistence.mountPVC true) }}
          - mountPath: {{ .Values.persistence.mountPath }}
            name: {{ template "application.name" . }}-data
          {{- end }}
          {{- if .Values.deployment.volumeMounts }}
          {{- range $key, $value := .Values.deployment.volumeMounts }}
          - name: {{ $key }}
            {{-  include "k8s-app.tplvalues.render" ( dict "value" $value "context" $ ) | nindent 12 }} 	
          {{- end }}
          {{- end }}
          {{- end }}
{{ end -}}