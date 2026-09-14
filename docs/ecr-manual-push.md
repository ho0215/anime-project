# ECR 수동 push (현우 · CI/CD 2단계)

로컬(또는 cp1)에서 이미지를 빌드해 **ECR에 한 번 올려** 보는 단계입니다.  
`main` 머지 후에는 GitHub Actions(`Docker build`)가 같은 리포에 자동 push 합니다.

## 비용

- ECR 프라이빗 리포 자체는 거의 무료에 가깝고, **저장된 이미지 GB · pull** 만큼만 과금됩니다.
- 라이프사이클(최근 N개 / untagged 7일)로 스토리지를 줄입니다.

## A. 오늘 당장 (AWS CLI — 추천)

계정에 `ecr:*` / `sts:GetCallerIdentity` 권한이 있는 프로필로:

```bash
cd ~/Desktop/anime-project   # 실제 clone 경로

# 1) (선택) 리포만 먼저 만들기
aws ecr create-repository \
  --repository-name aniverse \
  --region ap-northeast-2 \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

# 2) 빌드 + 로그인 + push (한 번에)
chmod +x scripts/ecr-push.sh
./scripts/ecr-push.sh
```

성공 시 출력 예:

```text
OK — pushed:
  123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:sha-xxxxxxxxxxxx
  123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:latest
```

확인:

```bash
aws ecr describe-images --repository-name aniverse --region ap-northeast-2
```

### 환경 변수 (선택)

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `AWS_REGION` | `ap-northeast-2` | 리전 |
| `ECR_REPOSITORY` | `aniverse` | 리포 이름 |
| `IMAGE_LOCAL_TAG` | `aniverse:local` | 로컬 태그 |

## B. Terraform으로 리포 만들기 (정식)

`anime-project-infra` 에 `module.ecr` 이 있습니다.

```bash
cd anime-project-infra/environments/dev
terraform plan -target=module.ecr
terraform apply -target=module.ecr
terraform output ecr_repository_url
```

전체 apply 전에 `-target` 으로 ECR만 만들어도 됩니다.  
이후에는 A의 `./scripts/ecr-push.sh` 로 push 하면 됩니다.

## 태그 규칙

| 태그 | 용도 |
|------|------|
| `sha-<12자>` | 재현용 (권장, K8s/Argo에 이 태그 사용) |
| `latest` | 랩·수동 확인용 (운영 고정은 비권장) |
| `local` | 로컬 compose / ctr import 전용 (ECR에 안 올려도 됨) |

## 권한 최소 세트 (수동 push IAM)

```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:GetAuthorizationToken",
    "ecr:CreateRepository",
    "ecr:DescribeRepositories",
    "ecr:DescribeImages",
    "ecr:BatchCheckLayerAvailability",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload",
    "ecr:PutImage",
    "ecr:BatchGetImage"
  ],
  "Resource": "*"
}
```

`GetAuthorizationToken` 은 Resource `*` 가 필요합니다.

## GitHub Actions 자동 push (3단계)

워크플로: `.github/workflows/docker-build.yml`

| 트리거 | 동작 |
|--------|------|
| PR / `cursor/**` push | 이미지 **빌드만** |
| `main` push | 빌드 + ECR push (`sha-*`, `latest`) |
| Actions → Run workflow | 빌드 + ECR push |

필요한 Secrets (CodeDeploy `deploy.yml` 과 동일):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

IAM에 ECR push 권한(`ecr:PutImage` 등)이 있어야 합니다. 수동 push에 쓴 키와 같으면 됩니다.

확인: GitHub → Actions → **Docker build** → 초록 + Summary에 이미지 URI.

## 다음에 할 일

1. ~~수동 push 1회~~ / ~~Actions ECR push~~
2. 서이: EKS 노드/IRSA pull 권한
3. 윤주: Helm/Kustomize 이미지 URL을 ECR로 교체
4. 현우: Argo CD가 ECR 태그 sync
