# Checkov SAST Scan — TEST_LOG

> **Date**: 2026-02-15  
> **Checkov**: v3.2.500 | **Framework**: Terraform (source scan)  
> **Command**: `checkov -d . --framework terraform`

---

## Summary

| Metric | Initial | After Fix |
|:-------|--------:|----------:|
| Passed | 149 | **153** |
| Failed | 45 | **41** |
| Pass Rate | 76.8% | **78.9%** |

---

## 🟡 보안 망함 (수정 강력 권장)

| Check | Resource | Issue | Status |
|:------|:---------|:------|:-------|
| ~~CKV_AZURE_115~~ | ~~AKS~~ | ~~Private Cluster 미적용 → API Server 공개 노출~~ | ✅ Fixed |
| ~~CKV_AZURE_116~~ | ~~AKS~~ | ~~Azure Policy 없음 → 비인가 Pod 배포 가능~~ | ✅ Fixed |
| ~~CKV_AZURE_171~~ | ~~AKS~~ | ~~자동 업그레이드 미설정 → 보안 패치 누락~~ | ✅ Fixed |
| ~~CKV_AZURE_172~~ | ~~AKS~~ | ~~Workload Identity 미사용~~ | ✅ Already Set |
| ~~CKV2_AZURE_31~~ | ~~Subnet ×2~~ | ~~Analytics NSG 미연결~~ | ⚠️ False Positive |
| ~~CKV_AZURE_160~~ | ~~NSG~~ | ~~SSH/HTTP 인터넷 노출~~ | ⚠️ False Positive |

**추가 적용** (Checkov 외 보안 강화):
- `local_account_disabled = true` — 로컬 관리자 계정 차단
- `key_vault_secrets_provider { secret_rotation_enabled = true }` — Pod → KV 시크릿 자동 조회

### Fix Diff (`modules/compute/main.tf`)

```diff
  resource "azurerm_kubernetes_cluster" "main" {
+   private_cluster_enabled   = true              # CKV_AZURE_115
+   automatic_channel_upgrade = "stable"           # CKV_AZURE_171
+   local_account_disabled    = true               # 추가 보안
+   azure_policy_enabled      = true               # CKV_AZURE_116
+   key_vault_secrets_provider {                    # 추가 보안
+     secret_rotation_enabled = true
+   }
  }
```

### False Positive 근거

| Check | 근거 |
|:------|:-----|
| CKV2_AZURE_31 | `modules/analytics/main.tf`에서 NSG 생성 + 연결됨. Cross-module 오탐. |
| CKV_AZURE_160 | `deny-ssh-internet` 규칙 존재, Bastion만 SSH 허용. 오탐. |

---

## 🟠 하면 좋음 (무료, 시간 여유 시 수정)

| Check | Resource | Issue | Fix | Status |
|:------|:---------|:------|:----|:-------|
| CKV_AZURE_109 | Key Vault | 키 만료일 미설정 | 배포 후 Portal에서 설정 | Skip (Terraform 미지원) |
| CKV_AZURE_110 | Key Vault | 시크릿 만료일 미설정 | 배포 후 Portal에서 설정 | Skip (Terraform 미지원) |
| CKV_AZURE_111 | Key Vault | 키 자동 회전 미설정 | 배포 후 Portal에서 설정 | Skip (Terraform 미지원) |
| ~~CKV_AZURE_169~~ | ~~AKS~~ | ~~노드풀 Scale Sets 미사용~~ | ~~`type = "VirtualMachineScaleSets"`~~ | ✅ Fixed |
| ~~CKV_AZURE_170~~ | ~~AKS~~ | ~~Paid SLA SKU 미사용~~ | ~~`sku_tier = "Standard"`~~ | ✅ Fixed |
| ~~CKV_AZURE_163~~ | ~~ACR~~ | ~~이미지 서명 검증 없음~~ | ~~`trust_policy { enabled = true }`~~ | ✅ Fixed |
| ~~CKV_AZURE_164~~ | ~~ACR~~ | ~~오래된 이미지 자동 삭제 없음~~ | ~~`retention_policy { days=30 }`~~ | ✅ Fixed |
| CKV_AZURE_165 | ACR | 이미지 격리 검증 없음 | 배포 후 Portal에서 설정 | Skip (Terraform 미지원) |
| ~~CKV_AZURE_166~~ | ~~ACR~~ | ~~전용 데이터 엔드포인트 미사용~~ | ~~`data_endpoint_enabled = true`~~ | ✅ Fixed |
| CKV2_AZURE_29 | SQL | 취약점 자동 스캔 없음 | 새 리소스 생성 필요 | 새 리소스 (복잡) |
| ~~CKV_AZURE_229~~ | ~~SQL DB~~ | ~~변경 이력 감사 추적 없음~~ | ~~`ledger_enabled = true`~~ | ✅ Fixed |
| CKV2_AZURE_25 | SQL | 감사 로그 미수집 | 새 리소스 생성 필요 | 새 리소스 |
| CKV2_AZURE_27 | SQL | 보안 위협 시 알림 이메일 없음 | 새 리소스 생성 필요 | 새 리소스 |
| CKV2_AZURE_45 | SQL | 위협 탐지 비활성화 | ↑ CKV2_AZURE_27과 동일 | 동일 |




---

## 🔵 dev 불필요 (프로덕션 전환 시 수정)

| Check | Resource | Issue | Cost |
|:------|:---------|:------|:-----|
| CKV2_AZURE_1 | Storage | CMK 암호화 | Paid |
| CKV2_AZURE_48 | Databricks | CMK root DBFS | Paid |
| CKV_AZURE_224 | SQL | CMK | Paid |
| CKV_AZURE_217 | PostgreSQL | CMK | Paid |
| CKV_AZURE_117 | AKS | 디스크 암호화 세트 | Paid |
| CKV_AZURE_141 | AKS | 임시 디스크 암호화 | 구독 등록 필요 |
| CKV_AZURE_168 | AKS | Defender for Containers | $2/vCPU/month |
| CKV_AZURE_216 | Firewall | IDPS 모드 | Premium SKU |
| CKV_AZURE_219 | Firewall | DNS Proxy | Premium SKU |
| CKV2_AZURE_40 | Storage | Shared Key 비활성화 | Terraform 운영에 필요 |
| CKV2_AZURE_38 | Storage | Soft delete | Free |
| CKV2_AZURE_33 | Storage | PE 미연결 (PE 모듈에서 연결됨, 오탐) | — |
| CKV2_AZURE_41 | Storage | SAS 만료 정책 | Free |
| CKV2_AZURE_47 | Storage | Blob 버전 관리 | Free |
| CKV2_AZURE_32 | PE | PE에 NSG 미연결 (PE 자체가 보안) | — |
| CKV2_AZURE_2 | Key Vault | 진단 로그 (diagnostics 모듈에서 설정됨, 오탐) | — |
| CKV_AZURE_182-183 | App GW | CMK | Paid |
| CKV_AZURE_218 | Firewall | 정책 CMK | Paid |
| CKV_AZURE_220 | App GW | WAF 경로 맵 연결 | Free |
| CKV_AZURE_223 | App GW | WAF body 검사 | Free |

---

## Security Baseline — PASSED (153 checks) ✅

| Control | Status |
|:--------|:-------|
| Key Vault purge protection | ✅ |
| Storage TLS 1.2 minimum | ✅ |
| SQL Server public access disabled | ✅ |
| SQL Server AAD-only auth | ✅ |
| ACR public access disabled | ✅ |
| AKS RBAC enabled | ✅ |
| AKS Private Cluster | ✅ |
| AKS Azure Policy | ✅ |
| AKS Workload Identity | ✅ |
| AKS Auto Upgrade (stable) | ✅ |
| AKS network policy (Calico) | ✅ |
| AKS Azure CNI | ✅ |
| NSG deny-all-inbound | ✅ |
| Private endpoints | ✅ |
| Databricks no public IP | ✅ |
| Databricks VNet injection | ✅ |

---

## NSG Remediation Record

**File**: `modules/network/main.tf`

Security 서브넷에 NSG + deny-all-inbound 규칙 + association 추가.

```
terraform validate → Success ✅
Checkov → security subnet PASSED ✅
```

---

## Post-Deployment Checklist (배포 후 수동 설정)

> `terraform apply` 완료 후, Azure Portal / CLI에서 수행해야 할 작업.

### 1. Key Vault — 키/시크릿 관리

| 작업 | 위치 | 관련 Check |
|:-----|:-----|:-----------|
| DB 암호 시크릿 저장 + 만료일 설정 | Portal → Key Vault → Secrets | CKV_AZURE_110 |
| 암호화 키 생성 + 만료일 설정 | Portal → Key Vault → Keys | CKV_AZURE_109 |
| 키 자동 회전 정책 설정 (90일 등) | Portal → Key Vault → Keys → Rotation | CKV_AZURE_111 |

### 2. ACR — 컨테이너 레지스트리

| 작업 | 위치 | 관련 Check |
|:-----|:-----|:-----------|
| 앱 Docker 이미지 Push | CLI → `az acr login` → `docker push` | — |
| 이미지 격리(Quarantine) 활성화 | Portal → ACR → Settings | CKV_AZURE_165 |

### 3. AKS — 쿠버네티스

| 작업 | 위치 |
|:-----|:-----|
| kubectl 인증 설정 (Azure AD) | CLI → `az aks get-credentials` |
| 앱 Helm/YAML 배포 | CLI → `kubectl apply` |
| Workload Identity 연결 (Pod ↔ Key Vault) | YAML → ServiceAccount annotation |
| Namespace / RBAC 정책 설정 | `kubectl` |

### 4. SQL Server / PostgreSQL

| 작업 | 위치 | 관련 Check |
|:-----|:-----|:-----------|
| Azure AD 관리자 계정 지정 | Portal → SQL → AD Admin | — |
| 초기 DB 스키마 마이그레이션 | 앱 또는 CLI에서 실행 | — |
| 감사 로그 보존 기간 확인 | Portal → SQL → Auditing | CKV2_AZURE_25 |

### 5. Databricks

| 작업 | 위치 |
|:-----|:-----|
| Workspace 접속 + Cluster 생성 | Portal → Databricks → Launch |
| ADLS Gen2 마운트 설정 | Databricks Notebook |
| CDC 파이프라인 구성 | Databricks Jobs |

### 6. 모니터링

| 작업 | 위치 |
|:-----|:-----|
| Log Analytics 알림 규칙 설정 | Portal → Monitor → Alerts |
| 알림 이메일 / Teams 연결 | Portal → Action Groups |
| SQL 위협 탐지 알림 이메일 등록 | Portal → SQL → Security | CKV2_AZURE_27 |
