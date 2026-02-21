# 🔐 Terraform 시크릿 관리 가이드

> **대상**: NSC Platform Infra 팀 전원  
> **목적**: GitHub에 코드를 안전하게 공유하면서 비밀번호/키 노출을 방지하는 방법

---

## 1. 파일 구조

```
infra_terraform_v02/
├── terraform.tfvars              ← 비민감 설정값 (Git ✅)
├── secrets.auto.tfvars           ← 민감 비밀번호 (Git ❌ — .gitignore에 등록)
├── secrets.auto.tfvars.example   ← 빈 템플릿 (Git ✅ — 팀원 참조용)
├── .gitignore                    ← secrets 파일 제외 규칙
```

| 파일 | GitHub 업로드 | 내용 |
|:-----|:-------------|:-----|
| `terraform.tfvars` | ✅ 올라감 | location, prefix, subnet CIDRs 등 |
| `secrets.auto.tfvars` | ❌ **절대 안 올라감** | 실제 비밀번호 |
| `secrets.auto.tfvars.example` | ✅ 올라감 | 빈 값 템플릿 (참조용) |

---

## 2. 로컬 개발 환경 설정 (신규 팀원)

### Step 1: 저장소 클론
```powershell
git clone https://github.com/Naver-Dunamu-Merge-TF/NSC-infra.git
cd Infra/infra_terraform_v02
```

### Step 2: 시크릿 파일 생성
```powershell
# 템플릿을 복사하여 실제 시크릿 파일 생성
Copy-Item secrets.auto.tfvars.example secrets.auto.tfvars
```

### Step 3: 값 입력
`secrets.auto.tfvars`를 열고 실제 비밀번호를 입력합니다:
```hcl
pg_admin_password = "실제비밀번호입력"
```

### Step 4: Terraform 실행
```powershell
terraform init
terraform plan      # secrets.auto.tfvars는 자동 로드됨
terraform apply     # -var-file 플래그 불필요
```

> [!IMPORTANT]
> `secrets.auto.tfvars`는 **절대 Git에 커밋하지 마세요.**  
> `.gitignore`에 이미 등록되어 있으니 정상적이면 추적되지 않습니다.

---

## 3. CI/CD 환경 (GitHub Actions)

CI/CD에서는 파일 대신 **GitHub Secrets → 환경변수**로 주입합니다:

### GitHub Secrets 등록
`Settings → Secrets and variables → Actions → New repository secret`

| Secret Name | 값 |
|:------------|:---|
| `PG_ADMIN_PASSWORD` | PostgreSQL 관리자 비밀번호 |

### Workflow 설정
```yaml
# .github/workflows/terraform.yml
jobs:
  terraform:
    runs-on: ubuntu-latest
    env:
      TF_VAR_pg_admin_password: ${{ secrets.PG_ADMIN_PASSWORD }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan
```

> [!NOTE]
> Terraform은 `TF_VAR_` 접두어가 붙은 환경변수를 **자동으로** 같은 이름의 변수에 매핑합니다.  
> 예: `TF_VAR_pg_admin_password` → `var.pg_admin_password`

---

## 4. 현재 민감 변수 목록

| 변수명 | 용도 | 전달 방법 |
|:-------|:-----|:---------|
| `pg_admin_password` | PostgreSQL 초기 관리자 비밀번호 | `secrets.auto.tfvars` 또는 `TF_VAR_` |

> [!TIP]
> SQL Server는 `azuread_authentication_only = true`로 설정되어 비밀번호가 **필요 없습니다.**  
> AKS, ACR, Key Vault도 Managed Identity 기반이라 별도 키 관리 불필요.

---

## 5. 보안 체크리스트

- [ ] `secrets.auto.tfvars`가 `.gitignore`에 등록되어 있는지 확인
- [ ] `git status`에서 `secrets.auto.tfvars`가 표시되지 않는지 확인
- [ ] 비밀번호를 Slack/Teams 등 메신저로 공유하지 않기
- [ ] CI/CD 시크릿은 GitHub Secrets에만 저장
- [ ] 운영 환경에서는 Azure Key Vault 직접 참조 권장

ℹ️ 참고사항 (문제는 아니지만 인지할 항목)
#	항목	위치	설명
1	administrator_login = "nscpgadmin"	data/main.tf:48	PG 로그인 이름 하드코딩. 변수화 가능하나 비밀번호가 아니라 보안 이슈는 아님
2	login_username = "nsc-sql-admin"	data/main.tf:16	SQL AAD 관리자 표시 이름. AAD-only 인증이라 문제 없음
3	
terraform.tfvars
 Git 업로드	.gitignore:8	비민감 값만 포함 (CIDR, region, tags). ✅ 안전
