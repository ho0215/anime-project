# aniverse-db-backup CronJob 전용 이미지.
# amazon/aws-cli:latest 에는 kubectl이 없어서, 원래는 Job이 실행될 때마다
# `yum install -y kubectl`로 매번 설치했음 — 이게 메모리 스파이크(OOM)와
# 간헐적 hang의 원인이었음(2026-10-13 503 장애, 2026-10-16 재발 발견).
# 빌드 시점에 한 번만 설치해서 이 문제를 제거함.
FROM amazon/aws-cli:latest

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/
