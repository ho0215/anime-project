# 로컬 Kubernetes (minikube) — Pod로 올리기

Compose로 이미지가 되는 것을 확인했다면, 같은 이미지를 **Pod**로 띄운다.
EKS 전에 “쿠버네티스 방식”을 한 번 검증하는 단계다.

## 0. 준비

- Docker 동작 중
- 브랜치에 `Dockerfile`, `deploy/k8s/` 있음

```bash
cd ~/Desktop/aniverse/anime-project
# compose 쓰던 터미널은 Ctrl+C 또는:
docker compose down
```

## 1. minikube 설치 (없을 때)

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version
```

kubectl:

```bash
sudo apt update
sudo apt install -y kubectl
# 또는: https://kubernetes.io/docs/tasks/tools/
```

## 2. 클러스터 시작

```bash
minikube start --driver=docker
kubectl get nodes
```

## 3. 앱 이미지를 minikube에 넣기

**방법 A (추천)** — minikube Docker에 직접 빌드

```bash
eval $(minikube docker-env)
docker build -t aniverse:local .
# 이후 터미널에서 호스트 Docker로 돌아가려면:
# eval $(minikube docker-env -u)
```

**방법 B** — 이미 빌드된 이미지 로드

```bash
docker build -t aniverse:local .
minikube image load aniverse:local
```

## 4. 매니페스트 적용 (web Pod + DB StatefulSet)

```bash
kubectl apply -k deploy/k8s/overlays/local
kubectl -n aniverse get pods -w
```

`aniverse-web-...` / `aniverse-db-0` 가 `Running` · Ready 될 때까지 기다린다.

```bash
kubectl -n aniverse get svc
kubectl -n aniverse logs deploy/aniverse-web --tail=50
```

## 5. 접속

```bash
kubectl -n aniverse port-forward svc/aniverse-web 8000:80
```

브라우저: http://127.0.0.1:8000/health/ → `OK`  
메인: http://127.0.0.1:8000/

## 6. 정리

```bash
kubectl delete -k deploy/k8s/overlays/local
minikube stop
# 완전 삭제: minikube delete
```

## 안 되면

| 증상 | 확인 |
|------|------|
| ImagePullBackOff | `eval $(minikube docker-env)` 후 다시 `docker build -t aniverse:local .` |
| web CrashLoop | `kubectl -n aniverse logs deploy/aniverse-web` — DB 미준비면 조금 기다렸다가 재시작 |
| DB Pending | `kubectl -n aniverse describe pvc` — minikube 기본 StorageClass 확인 |

## Compose vs 지금 단계

| | Compose | minikube Pod |
|--|---------|----------------|
| 실행 주체 | Docker Compose | Kubernetes |
| 앱 단위 | container | **Pod** |
| DB | compose service | **StatefulSet + PVC** |
| 다음 | — | 같은 매니페스트 감각으로 EKS |

## 다음에 (AWS)

서이 EKS 준비 → 이미지 ECR → `image:` 를 ECR URI로 바꾸고 apply/Argo sync.
