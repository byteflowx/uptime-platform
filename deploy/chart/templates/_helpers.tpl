{{- define "uptime.container" -}}
image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
env:
  - name: PGHOST
    value: {{ .Values.db.host | quote }}
  - name: PGDATABASE
    value: {{ .Values.db.name | quote }}
  - name: PGUSER
    value: {{ .Values.db.user | quote }}
  - name: PGSSLMODE
    value: require
  - name: PGPASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.db.passwordSecret }}
        key: password
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: [ALL]
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    memory: 256Mi
{{- end -}}
