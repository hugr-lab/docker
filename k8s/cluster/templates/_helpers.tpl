{{/*
Returns the core-db DSN
*/}}
{{- define "cluster.CoreDB.DSN" -}}
{{- if .Values.coreDB.path -}}
{{ .Values.coreDB.path }}
{{- else if .Values.postgresql.bitnami -}}
postgres://{{ .Values.postgresql.auth.username | default "postgres" }}:{{ .Values.postgresql.auth.password | default .Values.postgresql.auth.postgresPassword }}@{{ .Values.postgresql.fullnameOverride | default (printf "%s-postgresql" .Release.Name) }}:{{ .Values.postgresql.service.port | default 5432 }}/{{ .Values.coreDB.name | default "hugr-core" }}
{{- else -}}
postgres://{{ .Values.coreDB.auth.username | default "postgres" }}:{{ .Values.coreDB.auth.password }}@coredb:{{ .Values.coreDB.port | default 5432 }}/{{ .Values.coreDB.name | default "hugr-core" }}
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

{{/*
Returns the CoreDB host
*/}}
{{- define "cluster.CoreDB.Host" -}}
{{- if .Values.postgresql.bitnami -}}
{{ .Values.postgresql.fullnameOverride | default (printf "%s-postgresql" .Release.Name) }}
{{- else -}}
coredb
{{- end -}}
{{- end -}}

{{/*
Returns the CoreDB port
*/}}
{{- define "cluster.CoreDB.Port" -}}
{{- if .Values.postgresql.bitnami -}}
{{ .Values.postgresql.service.port | default 5432 }}
{{- else -}}
{{ .Values.coreDB.port | default 5432 }}
{{- end -}}
{{- end -}}

{{/*
Returns the CoreDB username
*/}}
{{- define "cluster.CoreDB.Username" -}}
{{- if .Values.postgresql.bitnami -}}
{{ .Values.postgresql.auth.username | default "postgres" }}
{{- else -}}
{{ .Values.coreDB.auth.username | default "postgres" }}
{{- end -}}
{{- end -}}

{{/*
Returns the CoreDB password
*/}}
{{- define "cluster.CoreDB.Password" -}}
{{- if .Values.postgresql.bitnami -}}
{{ .Values.postgresql.auth.password | default .Values.postgresql.auth.postgresPassword }}
{{- else -}}
{{ .Values.coreDB.auth.password }}
{{- end -}}
{{- end -}}

{{/*
Extracts port number from BIND string (strips leading colon)
*/}}
{{- define "cluster.bindPort" -}}
{{- . | trimPrefix ":" -}}
{{- end -}}
