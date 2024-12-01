{{/*
Expand the name of the chart.
*/}}
{{- define "k8s-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Define app version to be used in labels
*/}}
{{- define "k8s-app.version" -}}
  {{- $appVersion := default .Chart.Version .Values.deployment.image.tag -}}
  {{- regexReplaceAll "[^a-zA-Z0-9_\\.\\-]" $appVersion "-" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "k8s-app.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "k8s-app.labels" -}}
helm.sh/chart: {{ include "k8s-app.chart" . }}
{{ include "k8s-app.selectorLabels" . }}
{{- with include "k8s-app.version" . }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ .Values.partOfOverride | default (include "k8s-app.name" .) }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8s-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .Values.componentOverride | default (include "k8s-app.name" .) }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "k8s-app.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "k8s-app.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}