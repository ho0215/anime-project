# 랩 K8s에 ECR 이미지 붙이기 (현우 · 1순위)

목표: GitHub Actions / 수동 push로 ECR에 올라간 이미지로  
**kubeadm 랩(cp1/wk1/wk2)** 에서 web Pod를 기동한다.

DB는 계속 공개 MariaDB 이미지 + **emptyDir**(StorageClass 없는 랩용).

## 이미지 URI

```text
679583587966.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:latest
679583587966.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:sha-<12자>
```

## 왜 바로 `image:` 만 바꾸면 안 되나

프라이빗 ECR이라 워커에 **pull 권한(또는 로컬 import)** 이 필요하다.  
랩 노드에 AWS IAM이 없으면, 예전에 하던 것처럼 **`ctr import`** 가 제일 단순하다.

(EKS에서는 노드 역할 / IRSA로 pull — 서이 담당)

## 절차 A — ECR pull → ctr import (랩 권장)

### 1) cp1 (aws CLI · docker 있는 곳)

```bash
cd ~/Desktop/anime-project
git pull
git checkout cursor/lab-k8s-ecr-image-8e41   # 또는 main 머지 후

chmod +x scripts/lab-ecr-import.sh
./scripts/lab-ecr-import.sh latest
# 또는: ./scripts/lab-ecr-import.sh sha-xxxxxxxxxxxx
```

스크립트가 tar 경로와 `scp` / `ctr import` 안내를 출력한다.

### 2) wk1 / wk2

```bash
sudo ctr -n k8s.io images import ~/aniverse-ecr-latest.tar
sudo ctr -n k8s.io images ls | grep aniverse
```

이름이  
`679583587966.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:latest`  
로 보여야 한다.

### 3) cp1에서 apply

```bash
# latest 아니면 태그 맞추기
# (cd deploy/k8s/overlays/lab-ecr && \
#    kustomize edit set image aniverse=679583587966.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:sha-XXXX)

kubectl apply -k deploy/k8s/overlays/lab-ecr
kubectl -n aniverse get pods -o wide -w
```

### 4) 접속

```bash
kubectl -n aniverse port-forward svc/aniverse-web 8000:80
# http://127.0.0.1:8000/health/
```

## 절차 B — (선택) imagePullSecrets

토큰이 **약 12시간**이라 랩용으로는 A가 낫다. EKS 전에 연습만 할 때:

```bash
kubectl -n aniverse create secret docker-registry ecr-pull \
  --docker-server=679583587966.dkr.ecr.ap-northeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region ap-northeast-2)"
# Deployment 에 imagePullSecrets: [{name: ecr-pull}] + imagePullPolicy: Always
```

## 오버레이 구성

| 경로 | 용도 |
|------|------|
| `deploy/k8s/overlays/local` | `aniverse:local` (minikube / 예전 방식) |
| `deploy/k8s/overlays/lab-ecr` | ECR URI + emptyDir DB |

## 확인 체크

- [ ] `kubectl -n aniverse get pods` → web/db `1/1 Running`
- [ ] web 이미지 URI가 ECR인지:  
  `kubectl -n aniverse get deploy aniverse-web -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'`
- [ ] `/health/` → OK

## 안 되면

| 증상 | 대응 |
|------|------|
| `ImagePullBackOff` | 워커에 ctr import 안 됨 / 태그 불일치 |
| `ErrImageNeverPull` | import된 이름과 매니페스트 URI·태그 일치시키기 |
| DB `Pending` | lab-ecr 오버레이(emptyDir) 쓰는지 확인 |
| Calico Unauthorized | `kubectl -n kube-system rollout restart ds/calico-node` |

## 다음에

- 서이: EKS 노드 ECR pull → import 없이 `imagePullPolicy: Always`
- 현우: Argo CD가 `overlays/lab-ecr` 또는 이후 `overlays/eks` sync
