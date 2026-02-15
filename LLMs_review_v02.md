# LLM Review — Architecture Manual v02

---

Review time : 2026-02-15 07:51
Reviewer : GPT-5.2 Pro

I reviewed the manual end-to-end for cross-consistency between **(a) the declared resources**, **(b) the subnet/topology + traffic flows**, and **(c) the network/security controls (NSG/UDR/Private Endpoint/WAF/Firewall/RBAC)**. 

## Overall result

The document’s **high-level architecture is coherent** (single VNet, multi-subnet segmentation, AppGW/WAF ingress, AKS app subnet, private endpoints for data/security services, Azure Firewall for controlled egress). Most of the *core* data paths described in the diagrams are also represented in the NSG matrix.

However, there are several **hard inconsistencies** (and a few ambiguities) that would cause implementers to configure ports, identity, or ingress incorrectly unless they are resolved.

---

## What is internally consistent (good)

These elements line up across diagrams/tables/text:

* **Single VNet + multi-subnet model**: Perimeter / Application / Admin Portal / Messaging / Data / Security / Analytics / Egress / Operations are consistently used as logical zones, and the deployment matrices list matching components.
* **Main traffic paths vs NSG matrix** (as written):

  * Internet → Perimeter on 443 is allowed (matches “HTTPS 443” ingress).
  * Perimeter → Application on 8080 is allowed (matches AppGW routing to AKS backend port).
  * Perimeter → Admin Portal on 443 is allowed (matches AppGW routing to Admin UI).
  * Admin Portal → Application on 8080 is allowed (matches Admin UI calling Admin API).
  * Application ↔ Messaging on 9093 is allowed (matches “Kafka TLS 9093”).
  * Application → Data on 1433/5432/443 is allowed (SQL/Postgres/Ledger).
  * Application/Analytics → Egress is allowed (matches UDR-to-Firewall intent).

---

## Inconsistencies and ambiguities to fix

### 1) TLS baseline contradicts explicit “HTTP 8080” AppGW → AKS

* The manual explicitly states a baseline: `모든 서비스 간 통신: TLS 1.2 이상 강제`.
* But the NSG diagram labels **plain HTTP** from AppGW to AKS: `AppGW -->|"✅ HTTP 8080"| ...`.
* The NSG rules summary also uses “서비스 라우팅 … 8080” as the AppGW → AKS service port.

**Why this is inconsistent:** “HTTP 8080” is not TLS, so it violates the stated “TLS 1.2+ for all service-to-service traffic” baseline.

**How to resolve (choose one and align everywhere):**

* **Option A (strict baseline):** make AppGW → backend **HTTPS** (and update the NSG matrix/diagrams/ports accordingly).
* **Option B (relax baseline):** change baseline wording to explicitly allow “unencrypted inside VNet for AppGW→AKS,” but that contradicts the “금융 규제 수준” posture the document claims.

---

### 2) “Only ingress is Internet→Perimeter” contradicts the Bastion-based Ops ingress

* NSG rules summary says: `Ingress 허용 ... 유일한 외부 진입점`.
* But the design principles explicitly say there are **3 independent ingress paths**: `3개 독립 Ingress 경로` (User, Admin, Ops).
* RBAC matrix also states Ops access path: `Admin (Ops) | Internet → Bastion → AKS Node`.
* Deployment network config lists Bastion with a **public IP**: `Bastion ... ✅ (Bastion PIP)`.
* Yet the NSG matrix Internet row shows Ops as blocked: `| **Internet** | ✅ 443 | ... | ❌ (Ops) |`.

**Why this is inconsistent:** The manual simultaneously claims (a) Perimeter is the only external entry point and (b) Ops enters via Bastion from the Internet, and (c) Bastion has a public IP, while (d) the NSG matrix denies Internet→Ops entirely.

**How to resolve:**

* Split the concept explicitly into:

  * **Application-plane ingress:** Internet→Perimeter (AppGW/WAF) only.
  * **Management-plane ingress:** Internet→Bastion (typically HTTPS 443 to Bastion PIP) for Ops.
* Reflect that split in the NSG matrix (or add an “exceptions / management plane” section), and remove/qualify the phrase “유일한 외부 진입점.”

---

### 3) Event Hubs protocol is inconsistent across NSG rules vs Firewall rules

You describe Event Hubs as Kafka-based and use 9093 in NSG, but the firewall table uses AMQPS:

* NSG rules summary: `Kafka 통신 ... 9093 (TLS)`.
* Firewall allowlist row: `allow-eventhubs` uses protocol `AMQPS` while saying “Event Hubs Kafka 통신”.
* Security config later says Event Hubs access control: `Kafka SASL_SSL`.

**Why this is inconsistent:** “Kafka over TLS” (9093) and “AMQPS” are not the same protocol/port expectation. An engineer implementing firewall rules will not know which is authoritative.

**How to resolve:**

* Decide the *actual* client protocol for each producer/consumer path:

  * If you truly use **Kafka**, make the firewall guidance match **Kafka 9093** (and clarify whether the firewall is even in-path if Private Endpoint + VNet routing keeps it local).
  * If you use **AMQP/HTTPS-based Event Hubs clients**, update the NSG matrix and traffic-flow categories (which currently say Kafka).

---

### 4) “Passwordless Managed Identity everywhere” conflicts with the Key Vault secrets you list

The manual claims:

* `비밀번호 없는 인증: 모든 서비스-to-서비스 인증은 Managed Identity 사용`.

But the Key Vault secret inventory includes secrets that imply key/credential-based auth:

* `sql-connection-string`
* `postgresql-connection-string`
* `eventhubs-connection-string`
* `acr-login-credential (backup)`
* `databricks-token`

**Why this is inconsistent:** Connection strings and tokens are not “passwordless,” and storing them as secrets suggests the runtime depends on them.

**How to resolve (choose one stance):**

* **Stance A (true passwordless):** remove/avoid key-based credentials for Azure-native services and rewrite the secret inventory to only include *non-Azure* external API credentials (and possibly certificates).
* **Stance B (mixed mode):** rewrite the principle to: “Prefer Managed Identity; some integrations (Kafka/SAS, tokens, external APIs) use secrets stored in Key Vault.” Then ensure each service’s auth method is explicit and consistent in RBAC + security config.

---

### 5) Confidential Ledger authentication conflicts with “ledger-api-key”

* Key Vault secret list includes: `ledger-api-key | Confidential Ledger API 키`.
* Security configuration table says Confidential Ledger authentication is: `Certificate / AAD`.

**Why this is inconsistent:** “API key” vs “Certificate/AAD” are materially different auth models.

**How to resolve:**

* If you use **certificate-based auth**, replace “ledger-api-key” with certificate/credential artifacts and describe how they are stored and rotated.
* If you use **key-based auth**, update the security configuration row and RBAC notes accordingly.

---

### 6) Databricks identity is contradictory within the RBAC matrix row

RBAC row says:

* `Databricks ... Managed Identity 기반 | Service Principal`

That row states **two different** identity bases at the same time.

**How to resolve:**

* Make the Databricks line single-valued:

  * either “Managed Identity” (and remove SP references),
  * or “Service Principal” (and remove “Managed Identity 기반” wording).
* Then reconcile with the secrets list (`databricks-token`) and the security configuration table.

---

### 7) Data subnet UDR-to-Firewall conflicts with NSG matrix denying Data→Egress

* UDR table applies `route-to-firewall` to **Data** subnet (`0.0.0.0/0 → Firewall`).
* But NSG matrix says Data → Egress is blocked: `| **Data** | ... | ❌ (Egress) |`.

**Why this is inconsistent:** If Data subnet traffic is supposed to be forced through the firewall, the NSG matrix should not categorically block Data→Egress, unless you explicitly intend “Data subnet must never initiate outbound at all.”

**How to resolve:**

* If Data subnet contains **only Private Endpoints** (no compute), say explicitly that UDR is “defensive/unused in practice,” and keep NSG strict.
* If Data subnet can originate traffic (e.g., VM-based tooling, future components), allow Data→Egress (to firewall) and rely on firewall allowlist.

---

### 8) Bastion subnet CIDR differs across sections

* NSG diagram implies Bastion source range: `source 10.0.1.0/24`
* Network configuration table lists Bastion subnet CIDR: `10.0.1.0/26`

**Why this matters:** CIDR mismatches will break rule implementation and troubleshooting.

**Fix:** pick one CIDR and update all references (diagrams + tables + any Terraform excerpts).

---

### 9) Resource count line likely miscounts application components

The manual states:

* `애플리케이션 서비스 5종`

But the architecture describes **Account, Commerce, Crypto, Sync Consumer, Admin API, Admin UI** (6 logical app components) across core + backoffice + admin portal.

**Fix:** clarify what you count as “애플리케이션 서비스” (exclude Admin UI explicitly, or update the count).

---

### 10) Minor editorial inconsistencies (lower severity)

These won’t break a deployment, but they reduce clarity:

* Duplicate/misaligned numbering: there is a “### 4. 트래픽 흐름 분류” inside section 2 context.
* Data flow diagram labels user ingress as `1. HTTP Request` while the rest of the doc uses HTTPS 443.
* Observability diagram labels a node as `Slack["💬 Teams"]` (mixed channel naming).

---

## Quick “flow vs NSG” sanity table (as the doc currently defines it)

This is **not** what Azure necessarily requires; it is what *your manual* claims.

| Flow described in diagrams/text            | Manual’s NSG matrix support? | Notes                                                            |
| ------------------------------------------ | ---------------------------- | ---------------------------------------------------------------- |
| Internet → Perimeter (AppGW/WAF)           | Yes (443)                    | Consistent                                                       |
| Perimeter → Application (AKS services)     | Yes (8080)                   | Conflicts with TLS baseline because NSG diagram says “HTTP 8080” |
| Perimeter → Admin Portal (Admin UI)        | Yes (443)                    | Consistent                                                       |
| Admin Portal → Application (Admin API)     | Yes (8080)                   | Port/protocol not fully specified beyond “8080”                  |
| Application ↔ Messaging (Event Hubs Kafka) | Yes (9093)                   | Conflicts with firewall table listing AMQPS                      |
| Application → Data (SQL/Postgres/Ledger)   | Yes (1433/5432/443)          | Consistent                                                       |
| Application/Analytics → Egress (Firewall)  | Yes (“Any”)                  | Consistent with UDR intent                                       |
| Data → Egress (Firewall)                   | **No** (blocked)             | Conflicts with Data subnet UDR-to-firewall                       |
| Ops ingress (Internet→Bastion)             | **Not represented**          | Conflicts with RBAC + Bastion public IP statement                |

---

## Minimal change set to make the manual consistent

If you want the smallest edits that eliminate most contradictions:

1. **Decide AppGW→AKS encryption** (HTTP vs HTTPS) and align:

   * TLS baseline statement,
   * NSG matrix (port),
   * NSG mermaid labels (“HTTP 8080”),
   * any “TLS everywhere” claims.

2. **Separate application-plane ingress from management-plane ingress**:

   * Keep “Perimeter is the only ingress” only for application-plane,
   * Add explicit Bastion ingress notes (and fix the NSG matrix Internet→Ops representation).

3. **Choose Event Hubs client protocol(s)** (Kafka 9093 vs AMQP/HTTPS) and align NSG + firewall tables.

4. **Make identity/auth decisions explicit**:

   * If “passwordless” is truly required, remove key/token dependencies from the secret inventory (except third-party APIs).
   * Otherwise, soften the principle statement and document which services use MI vs secrets.

5. **Unify CIDRs** (especially Bastion subnet) and fix the resource/app count line.

If you want, I can also produce a “single source of truth” section (one consolidated table for each subnet’s: CIDR, NSG allow rules, UDR, private endpoints, and expected ports) derived from your existing tables and diagrams, so contradictions become impossible to miss.




---
---

Review time : 2026-02-15 07:52
Reviewer : Antigravity (Google DeepMind)

## GPT-5.2 Pro 리뷰에 대한 Antigravity 검토

GPT-5.2 Pro의 리뷰는 전체적으로 **정확하고 깊이 있는 분석**입니다. 10건 중 대부분 동의하며, 일부 항목에 대해 보완 의견과 구체적 해결 방안을 제시합니다.

---

## 항목별 검토 (Agree / Partially Agree / Disagree)

### 1) TLS baseline vs HTTP 8080 — ✅ Agree

GPT의 지적이 정확합니다. 금융 규제 수준의 보안을 표방하면서 HTTP 8080은 모순입니다.

**Antigravity 제안: Option A (strict) 채택**

```
현재: Client → HTTPS 443 → AppGW → HTTP 8080 → AKS Pod
수정: Client → HTTPS 443 → AppGW → HTTPS 8443 → AKS Pod (mTLS)
```

* AKS Ingress Controller에 TLS 인증서 바인딩 (cert-manager + Key Vault CSI Driver)
* NSG 매트릭스: Perimeter → Application 포트를 `8080` → `8443` 으로 변경
* TLS baseline 문구 수정 불필요 (이미 올바른 원칙)

> **근거**: Azure Application Gateway v2는 Backend Pool에 HTTPS를 네이티브 지원하며, `backend_http_settings`에서 `protocol = "Https"`로 설정하면 됩니다. 추가 비용 없음.

---

### 2) Bastion Ops ingress vs "유일한 외부 진입점" — ✅ Agree

GPT 분석이 정확합니다. "유일한 외부 진입점"이라는 표현이 Bastion PIP의 존재와 모순됩니다.

**Antigravity 제안: 2-plane 분리 + NSG 매트릭스 보완**

문서에서 "유일한 외부 진입점" 문구를 다음으로 수정: `유일한 애플리케이션 트래픽 진입점 (Application-Plane Ingress)`

> **보충**: Azure Bastion의 NSG는 Azure가 관리하며, AzureBastionSubnet에는 Microsoft 공식 필수 NSG 규칙이 자동 적용됩니다. 따라서 Management-Plane 예외 섹션을 별도로 두는 것이 더 깔끔합니다.

---

### 3) Event Hubs Kafka 9093 vs AMQPS — ✅ Agree

**Antigravity 제안: Kafka 9093으로 통일**

* Firewall 테이블: `allow-eventhubs`의 Protocol을 `AMQPS` → `Kafka (SASL_SSL, 9093)` 으로 수정
* 단, Event Hubs가 **Private Endpoint**를 통해 접근되면 Firewall을 경유하지 않으므로 이 규칙은 **사실상 dead rule**
* **Defense-in-Depth** 원칙에 따라 유지하되 프로토콜을 Kafka로 통일

---

### 4) Passwordless vs Key Vault secrets — ⚠️ Partially Agree

GPT의 지적은 논리적으로 타당하지만, **실무적 맥락을 고려하면 Stance B (mixed mode)가 현실적**입니다.

**Antigravity 제안:**

| Secret Name | 분류 | 설명 |
|:---|:---|:---|
| `sql-connection-string` | **제거 가능** → MI로 대체 | `DefaultAzureCredential` 사용 |
| `postgresql-connection-string` | **제거 가능** → MI로 대체 | `azure.identity` 라이브러리 사용 |
| `acr-login-credential` | **제거** | `az aks update --attach-acr`로 MI 연결 |
| `eventhubs-connection-string` | **유지** | Kafka SASL_SSL 필요 |
| `databricks-token` | **유지** | REST API PAT 필요 |
| `upbit-api-key` | **유지** | 외부 API 인증 |

> **결론**: 6개 시크릿 중 3개(`sql`, `postgresql`, `acr`)는 MI로 대체 가능. 나머지 3개는 유지.

---

### 5) Confidential Ledger: API key vs Certificate/AAD — ✅ Agree

Azure Confidential Ledger는 공식적으로 **Certificate/AAD 인증**만 지원합니다. "API key" 개념 자체가 존재하지 않습니다.

수정: `ledger-api-key` → `ledger-client-cert` (PEM 인증서)

---

### 6) Databricks identity: MI vs Service Principal — ✅ Agree

**Antigravity 제안: Managed Identity 채택** (Unity Catalog 이후 System-assigned MI 지원)

단, `databricks-token`(PAT)은 외부에서 REST API 호출 시 (CI/CD) 여전히 필요. #4의 mixed mode와 일관적.

---

### 7) Data UDR-to-Firewall vs NSG deny — ✅ Agree (중요)

**Antigravity 제안: Data 서브넷은 PE Only → UDR 방어적 유지, NSG deny 유지**

Data 서브넷에는 **컴퓨트 리소스가 없습니다** (SQL DB, PostgreSQL, Confidential Ledger 모두 PaaS). 아웃바운드 트래픽 발생 이유 없음. UDR은 미래 방어, NSG deny-all-outbound가 사실상 정확. 문서에 **"PaaS Only" 주석 추가** 제안.

---

### 8) Bastion CIDR 10.0.1.0/24 vs /26 — ✅ Agree

`10.0.1.0/26` 채택 (Azure Bastion 최소 /26, /24는 과도). 이미 식별된 CIDR 통일 항목.

---

### 9) 애플리케이션 서비스 5종 vs 6개 — ✅ Agree

**"5종"이 맞음**: Account, Commerce, Crypto, Sync Consumer, Admin API (AKS 내). Admin UI는 Admin Portal 서브넷(AKS 외부)이므로 별도 카운트.

---

### 10) Minor editorial — ✅ Agree

* `Slack["💬 Teams"]` → `Teams["💬 Teams"]` (변수명 불일치)
* `HTTP Request` → `HTTPS Request` (#1 TLS baseline 연동)
* 섹션 넘버링 충돌 일괄 해결

---

## Antigravity 최종 판정 요약

| GPT 항목 | Antigravity 판정 | 제안 방향 |
|:---|:---|:---|
| 1) HTTP 8080 vs TLS | ✅ Agree | **HTTPS 8443** 채택 |
| 2) Bastion ingress | ✅ Agree | **2-plane 분리** + NSG 보완 |
| 3) Kafka vs AMQPS | ✅ Agree | **Kafka 9093 통일** + PE dead rule 주석 |
| 4) Passwordless vs secrets | ⚠️ Partially | **Mixed mode** + 3개 시크릿 MI로 대체 |
| 5) Ledger API key | ✅ Agree | **Certificate auth** 채택 |
| 6) Databricks MI vs SP | ✅ Agree | **MI 채택** + PAT은 CI/CD용 유지 |
| 7) Data UDR vs NSG | ✅ Agree | **둘 다 유지** + "PaaS Only" 주석 추가 |
| 8) Bastion CIDR | ✅ Agree | **/26 채택** (이미 식별됨) |
| 9) 서비스 카운트 | ✅ Agree | **5종 + Admin UI 별도** 명시 |
| 10) Editorial | ✅ Agree | 일괄 수정 |

> **GPT-5.2 Pro와의 합의점**: 10건 중 **9건 완전 동의**, **1건 부분 동의** (#4 — 원칙상 동의하나 실무적으로 mixed mode 제안). 전체적으로 GPT의 리뷰 품질은 **매우 높음** (Antigravity 자체 검증 시 누락한 항목 4건 — #1 TLS, #4 Secrets, #5 Ledger auth, #6 Databricks identity — 을 GPT가 추가 발견).

Review time : 2026-02-15 08:55
Reviewer : GPT-5.2 Pro


LLMs_review_v02.md(리뷰/권고) 10개 항목을 기준으로, README.md(v02)의 **리소스·네트워크·보안 규칙 기술이 “리뷰에서 제안한 방향과 일관되게 반영되었는지”**를 항목별로 대조했습니다.

## 결론 요약

* **10개 중 7개는 README에서 “리뷰 권고대로” 반영되어 정합**합니다. (TLS 백엔드 포트, Kafka 9093 통일, Ledger 인증서, Databricks MI, Data UDR 주석, Bastion CIDR 등)
* **3개는 “부분 반영” 상태**입니다. 남은 불일치는 대부분 **문구/표기 레벨(정책 해석이 갈리는 부분)**이라, README에서 몇 줄만 정리하면 리뷰와 완전히 정합해집니다.

---

## 리뷰 항목별 정합성 체크 결과 (LLMs_review_v02 → README v02)

아래는 LLMs_review_v02.md의 10개 지적사항을 README에 매핑한 결과입니다.

1. **AppGW→AKS “HTTP 8080” vs TLS 베이스라인**

* README: **Perimeter→Application이 8443(TLS)로 통일**되고, 8080 언급이 제거되어 리뷰 권고와 정합합니다.

2. **“유일한 외부 진입점” 문구 vs Bastion(운영) 인입 경로**

* README: NSG 규칙 설명에서 **Application-plane(AppGW) vs Management-plane(Bastion)**로 분리한 문구가 있어 방향은 맞습니다.
* 다만, README 내부에 **여전히 상충하는 문구/표기**가 남아 있어 “부분 정합”입니다(아래 ‘남은 불일치’ 참고).

3. **Event Hubs: Kafka 9093 vs AMQPS 혼재**

* README: Firewall Allowlist와 NSG가 **Kafka(SASL_SSL, 9093)**로 통일되고, **PE 구성 시 dead rule 주석**도 추가되어 리뷰 권고와 정합합니다.

4. **“Passwordless(MI everywhere)” 주장 vs Key Vault 시크릿 목록(ConnStr/Token)**

* README: “MI 우선 + 일부는 시크릿”의 **mixed mode 원칙**으로 정리되고, 시크릿 목록도 “MI 대체 가능/유지/제거 예정”으로 정돈되어 큰 방향은 리뷰·Antigravity 제안과 정합합니다.
* 다만 RBAC/보안표 일부 표기가 아직 완전히 일치하지 않아 “부분 정합”입니다(아래 참고).

5. **Confidential Ledger 인증: API key(부정확) vs Certificate/AAD**

* README: `ledger-client-cert`로 바뀌고, Ledger 인증이 Certificate/AAD로 정리되어 정합합니다.

6. **Databricks: Managed Identity vs Service Principal 혼재**

* README: Databricks를 **Managed Identity(Unity Catalog)로 단일화**하고, 외부 호출용 토큰만 남겨 정합합니다.

7. **Data Subnet: UDR(→Firewall) vs NSG(Data→Egress 차단) 모순 가능성**

* README: Data UDR을 **“PaaS Only, 방어적 설정”**으로 주석 처리해 리뷰 권고대로 정합합니다.

8. **Bastion CIDR: /24 vs /26 혼재**

* README: Bastion CIDR이 **10.0.1.0/26**으로 통일되어 정합합니다.

9. **총 리소스 카운트(애플리케이션 5 vs 6)**

* README: “AKS Pods”에 5개(Account/Commerce/Crypto/SyncConsumer/AdminAPI)로 명시하고 Admin UI를 별도(Web Dashboard)로 둬서, **5개로 해석 가능**해 정합한 편입니다.

10. **Editorial: 섹션 넘버/HTTP↔HTTPS/Slack↔Teams 표기**

* README: 섹션/HTTPS 표기는 정리됐지만, **Slack/Teams 표기가 혼재**되어 “부분 정합”입니다.

---

## 남아있는 “부분 정합” 3건 — README에서 정리하면 리뷰와 완전 일치

아래 3건은 README 문서 내부에서 상충하는 문구가 남아 있어서, LLMs_review_v02의 “정합성 개선” 의도와 100% 맞지 않는 지점입니다.

### A) Ingress(외부 진입점) 설명: AppGW-only vs Bastion 경로 문구 충돌

* README는 NSG 설명에서 **“유일한 애플리케이션 트래픽 진입점”**으로 한정하여 리뷰 권고를 반영했습니다.
* 그런데 같은 README의 Azure Firewall DNAT 섹션에
  **“모든 인바운드는 AppGW 경유”** 문구가 남아 있습니다. 이 문구는 Bastion 기반 운영 인입과 충돌합니다. 

**권장 수정(문구만 교체하면 됨)**

* DNAT 행 설명을 아래처럼 바꾸면 문서 메시지가 일관됩니다.

  * 예: “Firewall DNAT는 사용하지 않음. **애플리케이션 인바운드 = AppGW**, **운영(Management) 인바운드 = Bastion Public IP(HTTPS 443)** 경유.”

---

### B) Bastion “프로토콜/표기”가 리뷰 문구와 다름

* LLMs_review_v02는 Ops 경로를 “Internet→Bastion(통상 HTTPS 443)”로 설명했습니다. 
* README 다이어그램은 Admin→Bastion을 **“Secure SSH”**로 표기합니다. 이 표기는 “사용자가 SSH 세션을 연다”는 의미로는 맞을 수 있지만, 네트워크/보안 구현 관점에서는 **Bastion 인입은 보통 443**이므로 리뷰와 표기 레벨에서 어긋납니다.

**권장 수정(표기 정밀화)**

* 다이어그램 라벨을 “HTTPS 443 (Bastion)”으로 바꾸고, Bastion→AKS Node만 “SSH 22(터널)”로 두면 리뷰와 더 정확히 일치합니다.

---

### C) “mixed mode( MI 우선 + 일부 시크릿 )”는 반영됐지만, RBAC 표가 아직 완전히 일치하지 않음

* README는 원칙 문장에서 mixed mode를 명시하고, `eventhubs-connection-string`을 “Kafka SASL_SSL 필수”로 유지한다고 적었습니다.
* 그런데 README의 RBAC 매트릭스에는 **Service(AKS Pod)가 Event Hubs에 Managed Identity 기반으로 접근**한다고 되어 있어, 같은 README의 시크릿 목록/원칙과 **표 수준에서 충돌**합니다. 

또한, Antigravity 제안표는 “eventhubs-connection-string 유지(Kafka SASL_SSL 필요)”를 명시했습니다. 

**권장 수정(선택지 중 하나로 단일화)**

* 선택지 1(가장 단순): RBAC 행에서 “Event Hubs”를 빼고, Event Hubs는 “Kafka SASL_SSL(시크릿)”로 별도 행/주석으로 분리.
* 선택지 2(둘 다 허용): RBAC/보안표에 “Event Hubs (Kafka)=SAS, Event Hubs (AMQP/HTTPS)=MI”처럼 **클라이언트 방식별로 분리**하고, 문서 전체에서 “Kafka 사용”을 주로 한다는 점을 명확화.

**추가로 확인이 필요한(불확실) 부분**

* README는 `api.upbit.com`, `openapi.naver.com`을 Allowlist로 명시하지만, **외부 API 인증 키/토큰을 Key Vault에 저장한다는 항목은 시크릿 목록에 없습니다.**

  * 외부 API가 **인증 키가 필요 없는 공개 엔드포인트만 사용**한다면 누락이 아닐 수 있습니다.
  * 외부 API가 **키가 필요한 엔드포인트를 사용**한다면 README 시크릿 목록이 빠진 것입니다.
    이 부분은 README가 “키가 필요/불필요”를 명시하면 리뷰 문서의 mixed mode 의도와도 더 잘 맞습니다. (현재 상태만으로는 “불확실”입니다.)

---

## 마지막으로: “Slack vs Teams” 표기만 통일하면 문서가 더 깔끔해짐

* README는 Observability 다이어그램에서 Teams를 쓰지만, Error/Retry·Alert Rule 표에는 Slack이 남아 있습니다. 이는 LLMs_review_v02의 editorial 지적과 아직 완전 정합하지 않습니다.
* **한 쪽(Teams 또는 Slack)으로 용어를 통일**하면 해결됩니다.

---

원하면, 위 3개(ingress 문구/DNAT, Bastion 라벨, RBAC(Event Hubs) 정리 + Slack/Teams 통일)에 대해 **README.md에 바로 붙여넣을 수 있는 “수정 diff(교체 문장)”** 형태로 정리해줄게.


---
---

Review time : 2026-02-15 09:00
Reviewer : Antigravity (Google DeepMind)

## GPT-5.2 Pro 2차 리뷰에 대한 Antigravity 검토

GPT-5.2 Pro의 2차 리뷰(정합성 체크)를 대조 검증했습니다. 결과는 아래와 같습니다.

---

### GPT 2차 리뷰 반영 상태 (A/B/C + Slack)

| GPT 지적 항목 | 반영 여부 | 검증 결과 |
|:---|:---|:---|
| **A) DNAT 문구 — "모든 인바운드는 AppGW 경유"** | ✅ 해결 | `Firewall DNAT 미사용. 애플리케이션 인바운드 = AppGW(443), 운영 인바운드 = Bastion PIP(443)` 으로 수정 완료 |
| **B) Bastion 라벨 — "Secure SSH" → HTTPS 443** | ✅ 해결 | Mermaid 다이어그램 4곳 + 라벨 설명표 모두 `HTTPS 443 (Bastion)` → `SSH 22 (터널)` 2단계로 수정 완료 |
| **C) RBAC Event Hubs — MI vs Connection String 충돌** | ✅ 해결 | RBAC 매트릭스에서 `Service (AKS Pod)` 행을 **2행으로 분리** — MI 대상(KV/ACR/SQL) vs Kafka SASL_SSL(Event Hubs) |
| **Slack/Teams 표기 혼재** | ✅ 해결 | README 전체에서 `Slack` 0건 확인 (grep 결과). 모든 알림 채널이 `Teams`로 통일 |

---

### 잔여 사항 (Minor)

| 항목 | 상태 | 비고 |
|:---|:---|:---|
| ASCII art (L617) `Secure SSH Tunnel` | ⚠️ 잔존 | ASCII 다이어그램 내부 텍스트. Mermaid 아님. 수정 가능하나 **영향 없음** (렌더링 X) |
| 외부 API 인증 키 (`upbit`, `naver`) | ⚠️ 미기재 | Firewall Allowlist에 `api.upbit.com`, `openapi.naver.com` 있으나 Key Vault 시크릿 목록에 해당 키 없음 |
| README 수정일 | ⚠️ 갱신 필요 | 현재 `08:19` → 실제 최종 수정 `09:00`으로 업데이트 필요 |

---

### Antigravity Action Plan

**즉시 실행 (이번 커밋):**

1. ✅ ASCII art L617 `Secure SSH Tunnel` → `Bastion (HTTPS 443 → SSH)` 수정
2. ✅ 외부 API 키를 Key Vault 시크릿 목록에 추가: `upbit-api-key`, `naver-api-key` (공개 API면 "인증 불필요" 주석)
3. ✅ README 수정일 `08:19` → `09:00` 갱신
4. ✅ Git commit

**향후 (Terraform IaC 작성 시):**

- 위 Architecture Manual v02를 **Single Source of Truth**로 삼아 `main.tf` 모듈 구조 설계
- 각 서브넷별 `variables.tf` → Manual의 CIDR/NSG/UDR/PE 테이블과 1:1 대응
- Checkov/tfsec 기반 보안 검증 → Manual의 Security Baseline 체크리스트 자동화

---

### 정합성 최종 판정

| 기준 | 결과 |
|:---|:---|
| **1차 GPT 리뷰 10건** | ✅ **10/10 반영** |
| **2차 GPT 리뷰 3건 + Slack** | ✅ **4/4 반영** (minor 2건 잔존 → 이번 커밋에서 해결) |
| **문서 내부 자기일관성** | ✅ 확보 (NSG ↔ UDR ↔ RBAC ↔ Firewall ↔ 다이어그램 모두 정합) |

> **결론**: Architecture Manual v02는 **리뷰 지적 사항이 모두 반영**되었으며, minor 2건(ASCII art + 외부 API 키)만 이번 커밋에서 마무리하면 **완전 정합** 상태입니다.
