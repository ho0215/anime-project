{{/*
공통 라벨. 리소스 이름 자체는 kustomize 시절과 동일하게 고정값(aniverse-web, aniverse-db 등)을
그대로 쓴다 — ConfigMap의 DB_HOST=aniverse-db, restore_db.sh 등 여러 곳이 이 이름을 전제하기 때문에
Helm의 release-name 접두사 규칙(fullname template)을 적용하지 않는다.
*/}}
{{- define "aniverse.labels" -}}
project: aniverse
app.kubernetes.io/name: aniverse
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}
