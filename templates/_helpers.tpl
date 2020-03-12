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

{{/*
Load efs + additionalEfs as a list
Aggregates required global values:
- enabled
Set:
.Valess.efsList.list a list of all efs configs (including .Values.efs)
.Values.efsList.enabled true if one efs is enabled
*/}}
{{- define "efs.list" }}
{{- if empty (hasKey .Values "efsList") }}
{{- $efs := dict "list" list "enabled" false }}
{{- $_ := set $efs "list" (prepend (ternary (list .Values.additionalEfs) .Values.additionalEfs (eq (kindOf .Values.additionalEfs) "map")) .Values.efs) }}
{{- range $index := $efs.list }}
{{- $_ := set $efs "enabled" (ternary true $efs.enabled (eq (empty .enabled) false)) }}
{{- end }}
{{- $_ := set .Values "efsList" $efs }}
{{- end }}
{{- end }}

{{/*
Create a prefix for efs using name if provided
*/}}
{{- define "efs.nameSuffix" }}
    {{- $name := default "" .name }}
    {{- if not (eq $name "") }}-{{ .name }}{{ end }}
{{- end }}

{{/*
Print efs list volumes
*/}}
{{- define "efs.list.volumes" }}
{{- if .Values.efsList.enabled }}
{{- range $index, $efs := .Values.efsList.list }}
{{- if .enabled }}
{{- $efsVolumeName := printf "efs%s%s" (include "efs.nameSuffix" .) (ternary (printf "-%s" (cat $index)) "" (gt $index 0)) }}
- name: {{ $efsVolumeName }}
  persistentVolumeClaim:
    claimName: {{ .existingClaim | default (printf "%s-efs-pvc" (include "akeneo.fullname" $)) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Print efs list volumeMounts
*/}}
{{- define "efs.list.volumeMounts" }}
{{- if .Values.efsList.enabled }}
{{- range $index, $efs := .Values.efsList.list }}
{{- if .enabled }}
{{- $efsVolumeName := printf "efs%s%s" (include "efs.nameSuffix" .) (ternary (printf "-%s" (cat $index)) "" (gt $index 0)) }}
- mountPath: /{{ $efsVolumeName }}
  name: {{ $efsVolumeName }}
{{- range $mount := .containerMountPaths }}
{{- if eq (kindOf .) "map" }}
- mountPath: "{{ .containerPath }}"
  subPath: "{{ (trimPrefix "/" .volumePath) }}"
{{- else }}
- mountPath: "{{ . }}"
  subPath: "{{ (trimPrefix "/" .) }}"
{{- end }}
  name: {{ $efsVolumeName }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Print efs list initContainers args
*/}}
{{- define "efs.list.initContainers.args" }}
{{- $userPermissions := .Values.phpfpm.userPermissions }}
{{- if .Values.efsList.enabled }}
{{- range $index, $efs := .Values.efsList.list }}
{{- if .enabled }}
{{- $efsVolumeName := printf "efs%s%s" (include "efs.nameSuffix" .) (ternary (printf "-%s" (cat $index)) "" (gt $index 0)) }}
  chown -c {{ $userPermissions }}:{{ $userPermissions }} /{{ $efsVolumeName }} &&
{{- range $mount := .containerMountPaths }}
{{- if eq (kindOf .) "map" }}
  chown -c {{ $userPermissions }}:{{ $userPermissions }} "{{ .containerPath }}" &&
{{- else }}
  chown -c {{ $userPermissions }}:{{ $userPermissions }} "{{ . }}" &&
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}