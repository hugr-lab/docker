{{/*
Returns the core-db DSN
*/}}
{{- define "cluster.CoreDB.DSN" -}}
{{- if .Values.management.workNode.coreDBPath -}}
{{ .Values.management.workNode.coreDBPath }}
{{- else -}}
postgres://{{ .Values.postgresql.auth.username | default "postgres" }}:{{ .Values.postgresql.auth.password | default .Values.postgresql.auth.postgresPassword }}@{{ .Values.postgresql.fullnameOverride | default (printf "%s-postgresql" .Release.Name) }}:{{ .Values.postgresql.service.port | default 5432 }}/{{ .Values.management.workNode.coreDBName | default "core-db" }}
{{- end -}}
{{- end -}}

{{/*
Returns the cache addresses string
*/}}
{{- define "cluster.Cache.Addresses" -}}
{{- if .Values.workNode.cache.l2.addresses -}}
{{ .Values.workNode.cache.l2.addresses }}
{{- else if .Values.cache.redis.host -}}
{{ .Values.cache.redis.host }}:{{ .Values.cache.redis.port | default 6379 }}
{{- else -}}
{{ .Values.cache.fullnameOverride | default (printf "%s-redis" .Release.Name) }}-master:{{ .Values.cache.redis.port | default 6379 }}
{{- end -}}
{{- end -}}

{{/*
Returns the cache host
*/}}
{{- define "cluster.Cache.Host" -}}
{{- if .Values.cache.redis.host -}}
{{ .Values.cache.redis.host }}
{{- else -}}
{{ .Values.cache.fullnameOverride | default (printf "%s-redis" .Release.Name) }}-master
{{- end -}}
{{- end -}}
