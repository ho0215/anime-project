# Argo CD 랩 적용 (현우)

목표: 랩 클러스터에 Argo CD를 올리고, Git의 `deploy/k8s/overlays/lab-ecr` 를  
자동 sync 한다.

## 한 줄 흐름

```text
GitHub main (lab-ecr)
    ↑ sync
Argo CD (클러스터 argocd 네임스페이스)
    ↓ apply
aniverse 네임스페이스 (web + db)
```

이미지는 예전과 같이 **ECR** — 워커에 `ctr pull` 되어 있어야 Ready.

## 사전 조건

- [ ] `kubectl` 이 랩 클러스터를 가리킴 (`kubectl get nodes`)
- [ ] `main` 에 `deploy/k8s/overlays/lab-ecr` 있음
- [ ] wk1/wk2 에 ECR 이미지 있음 (`docs/lab-k8s-ecr.md`)
- [ ] (레포 private) GitHub PAT 또는 deploy key 준비

## 설치 (cp1)

```bash
cd ~/Desktop/anime-project
git pull origin main
# 이 브랜치 작업 중이면:
# git fetch && git checkout cursor/argocd-lab-8e41

chmod +x scripts/argocd-lab-install.sh
./scripts/argocd-lab-install.sh
```

스크립트가 하는 일:
1. `argocd` 네임스페이스
2. 공식 Argo CD install 매니페스트 적용
3. Application `aniverse-lab` 등록

## UI

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

브라우저: https://127.0.0.1:8080  
- ID: `admin`  
- PW: 설치 스크립트가 출력 (또는 아래)

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

## 상태 확인

```bash
kubectl -n argocd get application aniverse-lab
kubectl -n argocd get application aniverse-lab -o yaml | grep -E 'status:|synced|health' -n | head
kubectl -n aniverse get pods -o wide
```

목표: Application **Synced / Healthy**, Pod **1/1 Running**.

## private 레포일 때

Argo가 Git clone 실패하면 (`Authentication failed` 등):

1. GitHub → Settings → Developer settings → PAT (repo 읽기)
2. UI: Settings → Repositories → Connect Repo  
   - URL: `https://github.com/ho0215/anime-project.git`  
   - Username: `ho0215` (또는 아무 문자열)  
   - Password: PAT  
또는 CLI:

```bash
# argocd CLI 있을 때 예시
argocd repo add https://github.com/ho0215/anime-project.git \
  --username ho0215 --password "$GITHUB_PAT"
```

public 이면 이 단계 생략.

## 배포를 바꾸는 법 (이후)

1. Actions가 ECR에 `sha-…` push  
2. `deploy/k8s/overlays/lab-ecr` 의 `newTag` 를 그 태그로 변경 후 `main` 머지  
3. Argo가 자동 sync (selfHeal) → Pod 교체  

지금은 `latest` + 워커 ctr pull 전제.

## 롤백

Argo UI → Application → History → Rollback  
또는 Git revert 후 sync.

## 정리 (비용/랩 리셋)

```bash
kubectl delete -f deploy/argocd/application-lab-ecr.yaml
kubectl delete namespace argocd
# aniverse 앱만 지울 때:
# kubectl delete namespace aniverse
```

## 파일

| 경로 | 역할 |
|------|------|
| `scripts/argocd-lab-install.sh` | 설치 + Application |
| `deploy/argocd/application-lab-ecr.yaml` | sync 대상 정의 |
| `deploy/k8s/overlays/lab-ecr` | 실제 앱 매니페스트 |
