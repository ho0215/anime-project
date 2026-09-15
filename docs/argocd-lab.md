# Argo CD 랩 적용 (현우) — Helm GitOps

목표: 랩에 Argo CD를 올리고, **윤주 Helm 차트** (`deploy/helm/aniverse`) 를 sync 한다.

원래 계획: `Actions → ECR → Argo CD → (Helm) 클러스터`

## 한 줄 흐름

```text
GitHub main
  deploy/helm/aniverse + values-lab-ecr.yaml
         ↑ sync
Argo CD (argocd 네임스페이스)
         ↓ apply
aniverse 네임스페이스 (web + db)
```

이미지는 **ECR** — 랩 워커에 `ctr pull` 필요 (`docs/lab-k8s-ecr.md`).

## 사전 조건

- [ ] `kubectl` → 랩 클러스터
- [ ] `main`에 `deploy/helm/aniverse` 있음 (윤주)
- [ ] wk1/wk2에 ECR 이미지
- [ ] (private 레포) GitHub PAT

## 설치 / 전환 (cp1)

이미 Argo가 있고 Kustomize Application만 쓰던 경우:

```bash
cd ~/Desktop/anime-project
git pull origin main

kubectl apply -f deploy/argocd/application-lab-helm.yaml
kubectl -n argocd get app aniverse-lab -o yaml | grep -A5 'source:'
```

`path: deploy/helm/aniverse` 이면 OK.

처음 설치:

```bash
chmod +x scripts/argocd-lab-install.sh
./scripts/argocd-lab-install.sh
```

## UI · 상태

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
# https://127.0.0.1:8080  admin / (아래 비밀번호)

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo

kubectl -n argocd get app aniverse-lab
kubectl -n aniverse get pods
```

## 파일

| 경로 | 역할 |
|------|------|
| `deploy/helm/aniverse` | 윤주 Helm 차트 |
| `deploy/helm/aniverse/values-lab-ecr.yaml` | 랩·ECR values |
| `deploy/argocd/application-lab-helm.yaml` | **현재** Argo Application |
| `deploy/argocd/application-eks-helm.yaml` | EKS용 (서이 클러스터 후, 수동 sync) |
| `deploy/argocd/application-lab-ecr.yaml` | 예전 Kustomize (deprecated) |
| `deploy/k8s/overlays/lab-ecr` | 참고용 Kustomize (Argo 기본 path 아님) |

## 배포 바꾸기

1. Actions가 ECR에 `sha-…` push  
2. `values-lab-ecr.yaml` (또는 eks values)의 `image.tag` 변경 후 main 머지  
3. Argo sync → Pod 교체  

## EKS

서이 클러스터 준비되면:

```bash
# Argo가 EKS를 보도록 kubeconfig 등록 또는 EKS에 Argo 설치 후
kubectl apply -f deploy/argocd/application-eks-helm.yaml
# UI에서 Sync (자동 sync 꺼 둠)
```

`values-eks.yaml`에 ECR URI는 이미 반영. StorageClass·시크릿은 서이/윤주와 확인.

## private 레포

Argo UI → Settings → Repositories → PAT 연결. 상세는 이전과 동일.
