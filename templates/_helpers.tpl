{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "akeneo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "akeneo.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified chart name.
*/}}
{{- define "akeneo.chartname" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "akeneo.serviceAccountName" -}}
{{- if .Values.efs.serviceAccount.create -}}
    {{ default (include "akeneo.fullname" .) .Values.efs.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.efs.serviceAccount.name }}
{{- end -}}
{{- end -}}