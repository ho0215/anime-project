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

프라이빗 ECR이라 워커에 **pull 권한(또는 로컬 이미지)** 이 필요하다.  
랩에서는 워커에서 `ctr images pull` (아래 절차 A).

(EKS에서는 노드 역할 / IRSA로 pull — 서이 담당)

## 절차 A — 워커에서 ECR `ctr pull` (랩 권장)

새 Docker는 `docker save`가 **레이어 없이 수 KB tar**만 만드는 경우가 있습니다.  
그래서 랩에서는 **wk에서 직접 pull** 합니다.

### cp1

```bash
cd ~/Desktop/anime-project
git pull   # lab-ecr 브랜치

PASS=$(aws ecr get-login-password --region ap-northeast-2)
IMG=679583587966.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:latest

ssh ho0215@wk1 "sudo ctr -n k8s.io images pull -u AWS:${PASS} ${IMG}"
ssh ho0215@wk2 "sudo ctr -n k8s.io images pull -u AWS:${PASS} ${IMG}"
```

또는:

```bash
LAB_ECR_PUSH=1 ./scripts/lab-ecr-import.sh latest
```

### wk1 / wk2 확인

```bash
sudo ctr -n k8s.io images ls | grep aniverse
```

`679583587966.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:latest` 가 보여야 함.

### cp1 apply

```bash
kubectl apply -k deploy/k8s/overlays/lab-ecr
kubectl -n aniverse delete pod -l app=aniverse-web
kubectl -n aniverse get pods -o wide -w
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
| `ImagePullBackOff` / no basic auth | 워커에 이미지 없음 → `ctr images pull` 다시 |
| tar가 수 KB | `docker save` 깨짐(containerd store) → tar 말고 `ctr pull` 사용 |
| `ErrImageNeverPull` | import/pull된 이름과 매니페스트 URI·태그 일치시키기 |
| DB `Pending` | lab-ecr 오버레이(emptyDir) 쓰는지 확인 |
| Calico Unauthorized | `kubectl -n kube-system rollout restart ds/calico-node` |

## 다음에

- **Argo CD:** [argocd-lab.md](./argocd-lab.md) — Git의 lab-ecr 을 자동 sync
- 서이: EKS 노드 ECR pull → import 없이 `imagePullPolicy: Always`
- 현우: Argo 가 `overlays/lab-ecr` 또는 이후 `overlays/eks` sync
