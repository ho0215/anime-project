# DB SQL 자동 복구

EKS MariaDB PVC · SQL 시드 · S3 media 복구 절차와 트러블슈팅은 **infra 레포에 통일**되어 있습니다.

→ **[anime-project-infra/docs/db-restore.md](https://github.com/ho0215/anime-project-infra/blob/main/docs/db-restore.md)**  
→ 장애 로그: **[troubleshooting-log.md](https://github.com/ho0215/anime-project-infra/blob/main/docs/troubleshooting-log.md)**

앱 레포에서 관리하는 것:

| 항목 | 경로 |
|------|------|
| SQL 덤프 | `data/aniverse_backup.sql` (main) |
| Helm Job / values | `deploy/helm/aniverse/` (`dbRestore.*`) |

덤프를 바꿨으면 main에 머지한 뒤 infra Actions **Verify DB restore Job** 을 실행하세요.
