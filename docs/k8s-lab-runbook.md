# Aniverse — 로컬 K8s(실습 클러스터)에서 앱 실행 가이드

Docker Compose로 검증한 뒤, **같은 이미지를 쿠버네티스 Pod로 올리는** 절차입니다.  
(AWS EKS 아님. cp1 + 워커 노드 실습 클러스터 기준)

| 항목 | 내용 |
|------|------|
| 대상 레포 | `anime-project` |
| 브랜치 | `cursor/local-docker-cicd-8e41` (또는 머지 후 `main`) |
| 선행 | Docker로 이미지 빌드 가능, `kubectl`로 클러스터 접근 가능 |
| 담당 참고 | 앱·이미지·매니페스트 → 앱/CI 담당 / **Calico·노드 CNI → 네트워크·클러스터 담당** |

관련: [로컬 Docker](./local-docker.md) · [minikube용 메모](./local-k8s.md)

---

## 0. 목표 (여기까지 오면 “K8s로 앱 실행” 완료)

- [ ] `aniverse:local` 이미지가 워커에 있음  
- [ ] `kubectl apply -k deploy/k8s/overlays/local` 성공  
- [ ] `aniverse-web`, `aniverse-db-0` 이 **`1/1 Running`**  
- [ ] `port-forward` 후 http://127.0.0.1:8000/health/ → `OK`

---

## 1. 코드 받기

제어 플레인(또는 kubectl 쓰는 머신, 예: **cp1**):

```bash
cd ~/Desktop/aniverse/anime-project   # 본인 경로에 맞게
git fetch origin
git checkout cursor/local-docker-cicd-8e41
git pull origin cursor/local-docker-cicd-8e41
```

브랜치가 어긋나면 (emptyDir 등 최신 매니페스트 필요할 때):

```bash
cp .env .env.backup 2>/dev/null || true
git fetch origin
git reset --hard origin/cursor/local-docker-cicd-8e41
grep -A2 emptyDir deploy/k8s/base/db.yaml   # emptyDir: {} 가 보여야 함
```

---

## 2. (권장) Docker Compose로 먼저 확인

K8s 전에 **이미지·앱이 정상인지** Compose로 한 번 확인하는 것을 권장합니다.

```bash
cp -n .env.docker.example .env
docker compose up --build
```

- http://127.0.0.1:8000/health/ → `OK`  
- 확인 후: `Ctrl+C` 또는 `docker compose down`

상세: [local-docker.md](./local-docker.md)

---

## 3. 이미지 빌드 + 워커에 넣기

실습 클러스터는 워커에 Docker가 없고 **containerd**만 있는 경우가 많음.  
이미지를 tar로 만들어 각 워커에 import 합니다.

### 3.1 빌드 · 저장 (cp1)

```bash
cd ~/Desktop/aniverse/anime-project
docker build -t aniverse:local .
docker save aniverse:local -o /tmp/aniverse-local.tar
```

### 3.2 워커로 복사

호스트명/계정은 환경에 맞게 변경:

```bash
scp /tmp/aniverse-local.tar ho0215@wk1:/tmp/
scp /tmp/aniverse-local.tar ho0215@wk2:/tmp/
```

처음 연결 시 `Are you sure you want to continue connecting` → `yes`

### 3.3 각 워커에서 import

워커에 SSH 들어간 뒤 (**이미 wk1에 있으면 ssh 다시 치지 말 것**):

```bash
sudo ctr -n k8s.io images import /tmp/aniverse-local.tar
sudo ctr -n k8s.io images ls | grep aniverse
```

`docker.io/library/aniverse:local` 이 보이면 OK.  
**wk1, wk2 둘 다** 반복.

> `sudo docker load` 는 워커에 docker가 없으면 `명령이 없습니다` → **ctr** 사용.

---

## 4. 매니페스트 적용

cp1에서:

```bash
kubectl apply -k deploy/k8s/overlays/local
kubectl -n aniverse get pods -o wide
```

구성 요약:

| 리소스 | 역할 |
|--------|------|
| Deployment `aniverse-web` | Django(Daphne) Pod |
| StatefulSet `aniverse-db` | MariaDB (학습용 **emptyDir**) |
| Service | `aniverse-web`, `aniverse-db` |
| ConfigMap / Secret | DB·Django env |

> StorageClass가 없는 클러스터에서는 PVC StatefulSet이 `Pending` 납니다.  
> 현재 브랜치 DB는 **emptyDir** (Pod 삭제 시 DB 데이터 삭제됨 — 학습용).

---

## 5. 자주 막힌 문제와 대응

### 5.1 DB `Pending` — unbound PVC

```
pod has unbound immediate PersistentVolumeClaims
kubectl get sc  → No resources found
```

**원인:** StorageClass 없음.  
**대응:** emptyDir 매니페스트로 `git pull`/`reset` 후:

```bash
kubectl delete statefulset aniverse-db -n aniverse
kubectl delete pvc -n aniverse --all --ignore-not-found
kubectl apply -k deploy/k8s/overlays/local
```

확인:

```bash
kubectl -n aniverse describe pod aniverse-db-0 | grep -A5 "Volumes:"
```

`Type: EmptyDir` 이면 OK.

### 5.2 web `ContainerCreating` — Calico Unauthorized

```
plugin type="calico" failed (add): error getting ClusterInformation: Unauthorized
```

**원인:** 앱이 아니라 **클러스터 Calico CNI** 권한/상태 문제.  
**앱 Dockerfile·Django 수정으로 해결되지 않음.** → 네트워크/클러스터 담당과 수리.

시도해 볼 수 있는 조치(클러스터 관리):

```bash
kubectl -n kube-system delete pod -l k8s-app=calico-node
kubectl -n kube-system get pods -l k8s-app=calico-node
```

전부 `1/1 Running` 된 뒤 앱 재apply.  
계속 Unauthorized면 Calico RBAC/매니페스트 재적용 필요.

**담당자에게 전달할 한 줄**

> Pod sandbox 생성 시 Calico CNI가 `ClusterInformation` GET에서 Unauthorized. calico-node는 Running인데 CNI add 실패. 앱 매니페스트 이슈 아님.

### 5.3 web `ImagePullBackOff`

이미지가 **그 Pod가 스케줄된 워커**에 없음 → 해당 노드에서 `ctr import` 다시.

```bash
kubectl -n aniverse get pods -o wide
```

### 5.4 `port-forward` 실패 (Pending)

Pod가 Running이 되기 전이라 실패하는 것. 상태 먼저 확인.

---

## 6. 성공 확인 · 접속

```bash
kubectl -n aniverse get pods -o wide
```

예:

```text
aniverse-db-0     1/1   Running   ...
aniverse-web-xxx  1/1   Running   ...   <IP>   wk2
```

접속:

```bash
kubectl -n aniverse port-forward svc/aniverse-web 8000:80
```

- 헬스: http://127.0.0.1:8000/health/ → `OK`  
- 메인: http://127.0.0.1:8000/

로그:

```bash
kubectl -n aniverse logs deploy/aniverse-web --tail=50
kubectl -n aniverse logs aniverse-db-0 --tail=30
```

---

## 7. 정리

```bash
kubectl delete -k deploy/k8s/overlays/local
```

이미지만 워커에 남겨도 되고, 필요 시 워커에서 이미지 삭제 가능.

---

## 8. Compose vs 지금(K8s) vs 다음(EKS)

| | Docker Compose | 실습 K8s (지금) | AWS EKS (다음) |
|--|----------------|-----------------|----------------|
| 실행 | `docker compose up` | `kubectl apply` → **Pod** | 동일하게 Pod |
| 이미지 | 로컬 Docker | 워커에 `ctr import` | **ECR** pull |
| DB | compose MariaDB | Pod + emptyDir | StatefulSet + EBS 등 |
|  Trafic | localhost:8000 | port-forward | Ingress / ALB |
| 네트워크 | Docker 브리지 | **Calico** 등 CNI | AWS VPC CNI |

**정리:** Compose로 앱·이미지를 검증했고, 지금은 **같은 이미지를 쿠버네티스 Pod로 실행**한 단계입니다.  
다음은 이미지를 ECR에 두고 EKS에 올리는 것입니다.

---

## 9. 체크리스트 (팀원용)

- [ ] `git` 브랜치 최신 (emptyDir 포함)  
- [ ] `docker build -t aniverse:local .`  
- [ ] wk1/wk2에 `ctr import`  
- [ ] Calico 정상 (새 Pod에 IP 할당, Unauthorized 없음)  
- [ ] `kubectl apply -k deploy/k8s/overlays/local`  
- [ ] pods `1/1 Running`  
- [ ] port-forward → `/health/` OK  

---

*작성 기준: 실습 중 겪은 Docker 설치 충돌, scp/ctr import, Calico Unauthorized, PVC Pending → emptyDir 대응을 포함*
