# NSC Platform — 아키텍처 설명 스크립트

> **용도**: 팀원 앞에서 인프라를 설명할 때, 이 문서를 한번 읽고 나가면 자신감이 생기는 "구두 설명용 가이드"
> 
> **읽는 법**: 각 섹션의 💬 부분이 실제로 말할 내용. 📝 부분은 본인만 보는 배경지식.

---

## 도입부: 30초 요약

💬 **이렇게 시작하세요:**

> "우리 NSC 플랫폼 인프라는 크게 **4단계(Phase)**로 나뉘어져 있어요. 
> 1단계에서 네트워크 땅을 깔고, 
> 2단계에서 보안과 데이터베이스를 올리고, 
> 3단계에서 실제 서비스가 돌아가는 AKS랑 메시징을 배포하고, 
> 4단계에서 분석 환경이랑 모니터링을 붙여요.
> 
> 전체적으로 **약 50개의 Azure 리소스**가 **11개 Terraform 모듈**로 나뉘어져 있고, 
> **한 번의 `terraform apply`로 전부 올라갑니다.**"

---

## Phase 1: "먼저 땅을 깔아야 건물을 짓죠"

### 🌐 network 모듈

💬 **말할 내용:**

> "network 모듈은 전체 인프라의 **기초 공사**예요. 하나의 VNet(가상 네트워크) 안에 **서브넷 10개**를 만들어서, 각 서비스마다 '방'을 따로 줘요.
> 
> 왜 방을 나누냐면 — **보안** 때문이에요. 예를 들어 데이터베이스가 있는 방(data 서브넷)은 인터넷에서 직접 들어올 수 없게 막아놓고, 오직 AKS가 있는 방(app 서브넷)에서만 접근 가능하게 해둬요. 이걸 **NSG(Network Security Group)** 규칙으로 통제해요.
> 
> 쉽게 말하면 — **아파트 단지의 동 배치도**라고 생각하면 돼요. 1동은 상가(perimeter), 2동은 주민센터(bastion), 3동은 사무실(app)... 이런 식이에요."

📝 **혹시 물어보면:**
- "서브넷이 10개나 필요해?" → Azure Bastion이랑 Firewall은 **전용 서브넷 이름이 강제**(`AzureBastionSubnet`, `AzureFirewallSubnet`)라서, 합칠 수가 없어요. 나머지도 보안 격리를 위해 분리한 거예요.
- "NSG가 뭔데?" → 서브넷에 붙이는 **"출입 규칙"**이에요. "이 IP에서, 이 포트로, 들어오는 건 허용/차단" 같은 규칙을 정의하는 거예요. 아파트 출입 카드 시스템이라고 보면 돼요.

---

### 📊 monitoring 모듈

💬 **말할 내용:**

> "monitoring은 **Log Analytics Workspace**(LAW)랑 **Application Insights**를 만들어요.
> 
> LAW는 모든 리소스의 로그가 모이는 **중앙 관제실**이에요. AKS 로그, Firewall 로그, DB 로그 — 전부 여기로 보내요.
> Application Insights는 애플리케이션 레벨의 성능 모니터링이에요 — API 응답 시간, 에러율 같은 거.
> 
> 이걸 Phase 1에서 먼저 만드는 이유는, 나중에 AKS 같은 리소스를 만들 떄 **'로그를 어디로 보낼지'** LAW ID가 필요하거든요."

---

## Phase 2: "금고부터 만들고, 데이터를 넣을 곳을 준비"

### 🔒 security 모듈

💬 **말할 내용:**

> "security 모듈은 세 가지를 해요:
> 
> 1. **Key Vault** — 비밀번호, API 키, 인증서 같은 민감한 정보를 저장하는 **금고**예요. 코드에 비밀번호를 하드코딩 하는 대신, Key Vault에서 런타임에 꺼내 쓰는 거예요.
> 
> 2. **ACR (Azure Container Registry)** — 우리 마이크로서비스의 Docker 이미지를 저장하는 **개인 창고**예요. Docker Hub 같은 공개 저장소 대신, 우리만의 비공개 저장소를 쓰는 거죠.
> 
> 3. **Private DNS Zone** 7개 — 이건 좀 어려운 개념인데, 간단하게 말하면: Private Endpoint를 쓰면 `nsc-sql-dev.database.windows.net` 같은 주소가 공인 IP가 아니라 **우리 VNet 내부의 사설 IP로 해석**되게 해줘요. 그게 DNS Zone이 하는 일이에요."

📝 **혹시 물어보면:**
- "Key Vault purge_protection이 뭐야?" → 실수로 삭제해도 **90일간 복구 가능**하게 해주는 안전장치예요. 금고에 타이머 잠금장치 달아놓은 것.
- "ACR이 왜 Premium이야?" → Private Endpoint를 쓰려면 **Premium SKU가 필수**예요. Standard에서는 네트워크 격리를 못 해요.

---

### 💾 data 모듈

💬 **말할 내용:**

> "data 모듈에는 **데이터베이스 3종**이 있어요:
> 
> 1. **Azure SQL Server + Database** — 계정, 거래 같은 **핵심 비즈니스 데이터**가 여기 들어가요. MSSQL 기반이고, 암호화(TDE)가 기본 켜져 있어요.
> 
> 2. **PostgreSQL Flexible Server** — 암호화폐 시세, 환율 같은 **외부 데이터**를 저장해요. 오픈소스라서 비용도 절약되고, 앱 개발팀이 더 친숙한 DB예요.
> 
> 3. **Confidential Ledger** — 이건 좀 특별해요. **블록체인처럼 한번 기록하면 수정/삭제가 불가능**한 원장이에요. 규제 감사용 거래 기록을 여기에 넣어요. '우리가 데이터를 조작하지 않았다'는 걸 증명할 수 있는 거예요.
>
> 그리고 3개 DB 모두 **퍼블릭 접근이 차단**되어 있어요. Private Endpoint로만 접근 가능해요."

📝 **혹시 물어보면:**
- "Ledger가 왜 southeastasia에 있어?" → Korea Central에서 Confidential Ledger를 **아직 안 지원**해요. 가장 가까운 리전이 Southeast Asia예요.

---

### 🔗 private_endpoints 모듈

💬 **말할 내용:**

> "Private Endpoint는 **'서비스 전용 비밀 출입구'**예요. 
> 
> 보통 Azure 서비스들은 인터넷에서 접근 가능한 공개 엔드포인트가 있어요. 우리는 그걸 전부 끄고, 대신 **VNet 내부에 전용 NIC(네트워크 인터페이스)를 생성**해서, 우리 네트워크 안에서만 접근 가능하게 만든 거예요.
> 
> SQL, PostgreSQL, Key Vault, ACR, Event Hubs, ADLS — 이렇게 **6개** 서비스에 각각 PE를 붙였어요.
> 
> 비유하면 — 은행 VIP 전용 입구랑 비슷해요. 일반 손님(인터넷)은 오프라인 창구가 없고, VIP(우리 VNet)만 전용 문으로 들어갈 수 있는 구조."

📝 **혹시 물어보면:**
- "PE가 없으면 어떻게 되는데?" → DB에 퍼블릭 IP가 노출돼요. 해커가 IP 스캔으로 DB를 발견하고 brute force 공격을 시도할 수 있어요. PE는 그 가능성 자체를 없애는 거예요.
- "Ledger PE는 왜 주석처리야?" → 해당 구독에 `AllowPrivateEndpoints` 피처 플래그가 아직 등록이 안 돼 있어요. 등록 후 주석 해제하면 바로 작동해요.

---

## Phase 3: "이제 실제 서비스를 올리자"

### ⚙️ compute 모듈

💬 **말할 내용:**

> "compute는 **AKS(Azure Kubernetes Service)**예요. 우리 마이크로서비스 — Spring Boot로 만든 주문 서비스, FastAPI로 만든 시세 수집 서비스 — 이런 게 전부 여기서 돌아가요.
> 
> 핵심 설정을 말하면:
> - **Private Cluster** — API 서버가 공개 인터넷에 노출 안 되요. 오직 VNet 내부에서만 `kubectl`로 접근 가능해요.
> - **AutoScale 3~10노드** — 평소엔 3대, 트래픽 터지면 최대 10대까지 자동 확장.
> - **Managed Identity** — AKS가 ACR에서 이미지 당기고, Key Vault에서 시크릿 읽을 때, 비밀번호 없이 '신분증'으로 인증해요.
> 
> 비유하면 — AKS는 **공장**이에요. 원자재(컨테이너 이미지)는 ACR 창고에서 가져오고, 비밀 레시피(API 키)는 Key Vault 금고에서 꺼내 쓰는 거죠."

📝 **혹시 물어보면:**
- "왜 k8s 버전이 1.32야?" → 1.28~1.31은 LTS(장기지원) 전용이라 Standard tier에서 못 써요. 그래서 1.32로 올린 거예요.
- "Calico가 뭐야?" → Kubernetes **네트워크 정책 엔진**이에요. Pod 간 통신을 세밀하게 제어할 수 있게 해줘요. '이 Pod는 저 Pod랑만 통신 가능' 같은 규칙.

---

### 📨 messaging 모듈

💬 **말할 내용:**

> "messaging은 **Event Hubs**예요. Kafka 호환 프로토콜을 지원하니까, 우리 앱에서는 Kafka 클라이언트로 메시지를 보내고 받을 수 있어요.
> 
> 토픽이 2개 있어요:
> - **order-events** — 주문이 생성/변경될 때 이벤트를 발행. `sync-consumer`가 실시간 처리해요.
> - **cdc-events** — DB 변경 감지(Change Data Capture) 이벤트. `analytics-consumer`가 분석용으로 소비해요.
> 
> 왜 직접 API 호출 안 하고 Event Hubs를 쓰냐면 — **비동기 처리** 때문이에요. 주문 서비스가 결제 서비스한테 직접 API 콜 하면, 결제 서비스가 느려지면 주문도 같이 죽어요. Event Hubs에 메시지만 던져놓으면, 결제 서비스가 자기 속도에 맞춰 가져가니까 **서비스 간 결합도가 낮아져요.**"

---

### 🛡️ perimeter 모듈

💬 **말할 내용:**

> "perimeter는 **3방향 경비**예요:
> 
> **1. Application Gateway + WAF (입구)** 
> 외부 사용자의 HTTPS 요청이 제일 먼저 닿는 곳이에요. WAF(Web Application Firewall)가 OWASP 룰을 적용해서 SQL Injection, XSS 같은 **악성 요청을 자동 차단**해요. Prevention 모드라서, 의심스러우면 일단 막아요.
> 
> **2. Azure Bastion (관리자 출입구)**
> 개발자나 운영팀이 VM이나 AKS 노드에 SSH/RDP로 접속할 때 쓰는 **보안 게이트웨이**예요. 일반 SSH처럼 22번 포트를 인터넷에 열어두는 게 아니라, Azure Portal의 브라우저를 통해 접속하는 거라 **공격 표면이 사라져요**.
> 
> **3. Azure Firewall (출구)**
> AKS에서 인터넷으로 나가는 트래픽을 **검사하고 통제**해요. 허용된 FQDN(예: `login.microsoftonline.com`, `*.azurecr.io`, `api.upbit.com`)만 통과시키고, 나머지는 다 막아요. 혹시 악성코드가 AKS에 침투해도, C&C 서버로 통신하는 걸 차단할 수 있어요."

📝 **혹시 물어보면:**
- "Firewall FQDN에 왜 Upbit이랑 Naver가 있어?" → 우리 앱이 실시간 시세를 가져오려면 외부 API를 호출해야 하잖아요. Firewall에서 이 도메인만 명시적으로 허용해둔 거예요.

---

### 🔀 routing 모듈

💬 **말할 내용:**

> "routing은 **'모든 외부 통신은 Firewall을 거쳐라'**는 규칙을 강제하는 모듈이에요.
> 
> 기본적으로 Azure 서브넷은 인터넷으로 직접 나갈 수 있어요. 우리는 UDR(User Defined Route)을 써서, app/data/analytics 서브넷의 `0.0.0.0/0`(= 모든 외부 트래픽)을 **Firewall의 Private IP로 우회**시켜요.
> 
> 비유하면 — 건물 1층 로비에 경비실이 있는데, 모든 택배가 경비실을 거쳐야 하는 것처럼, 모든 외부 통신이 Firewall을 거치게 만든 거예요."

📝 **혹시 "왜 network 모듈 안에 안 넣었어?" 라고 물어보면:**

> "원래 network에 넣으려 했는데, UDR에는 Firewall의 Private IP가 필요해요. 근데 Firewall은 perimeter 모듈에 있잖아요. 그러면 **network → perimeter → network** 순환 참조가 돼서 Terraform이 에러를 내요. 그래서 routing을 별도 모듈로 빼서, network와 perimeter가 **둘 다 완료된 후에** 실행되게 만든 거예요. 이건 실제로 `terraform apply`에서 에러 나서 알게 된 거예요."

---

## Phase 4: "분석 환경 세팅 + 관측 체계 마무리"

### 📈 analytics 모듈

💬 **말할 내용:**

> "analytics는 두 가지예요:
> 
> 1. **Databricks** — 데이터 분석 워크스페이스. 우리 Data Engineer가 여기서 ETL 파이프라인을 만들고, 데이터 분석을 해요. **VNet Injection**으로 배포해서, Databricks 클러스터가 우리 VNet 안에서 돌아가요. 데이터가 외부 네트워크를 타지 않는 거죠.
> 
> 2. **ADLS Gen2 (Azure Data Lake Storage)** — 분석용 데이터를 저장하는 **데이터 레이크**예요. 일반 Blob Storage와 다른 점은, 폴더 구조를 지원하는 **Hierarchical Namespace**가 켜져 있다는 거예요. Big Data 처리에 최적화된 스토리지.
> 
> 이 둘이 합쳐져서 **Lakehouse Architecture**의 기반이 돼요."

📝 **혹시 물어보면:**
- "Databricks 서브넷이 왜 2개야?" → Databricks는 내부적으로 **Host 서브넷**(컨트롤러)과 **Container 서브넷**(워커)을 분리해요. VNet Injection 쓸 때 Azure가 요구하는 거예요. 우리가 선택한 게 아니라 Azure 규칙이에요.

---

### 🔍 diagnostics 모듈

💬 **말할 내용:**

> "diagnostics는 핵심 리소스 5개의 로그를 **Log Analytics Workspace로 자동 전송**하는 설정이에요:
> 
> - **AKS** → API 서버, 스케줄러, 감사(Audit) 로그
> - **Application Gateway** → 접근 로그, WAF 차단 로그
> - **Firewall** → 어떤 FQDN이 허용/차단됐는지
> - **Key Vault** → 누가 언제 어떤 시크릿을 조회했는지
> - **SQL Database** → 보안 감사, 쿼리 성능 통계
> 
> 이게 없으면 **문제가 생겨도 어디가 문제인지 몰라요**. diagnostics가 있어야 '언제, 어디서, 뭐가 잘못됐는지' 추적할 수 있어요."

---

## 마무리: RBAC (역할 기반 접근 제어)

💬 **말할 내용:**

> "마지막으로, main.tf에 **RBAC 2개**가 있어요:
> 
> 1. **AKS → ACR Pull** — AKS가 ACR에서 컨테이너 이미지를 가져올 수 있는 권한. 이거 없으면 AKS가 Pod를 못 띄워요.
> 2. **AKS → Key Vault Secrets User** — AKS가 Key Vault에서 비밀키를 읽을 수 있는 권한. DB 비밀번호, API 키 같은 걸 런타임에 주입하는 데 필요해요.
> 
> 둘 다 **Managed Identity** 기반이에요. 비밀번호를 코드에 넣는 대신, Azure가 '이 AKS는 이 ACR에 접근해도 돼'라고 신원 보증해주는 거예요."

---

## 🎤 종합 마무리 멘트

💬 **발표나 설명 끝에 이렇게 마무리하세요:**

> "정리하면, 이 인프라의 **핵심 설계 철학**은 세 가지예요:
> 
> 1. **격리(Isolation)** — 서브넷 분리, Private Endpoint, NSG 규칙으로 각 서비스가 **필요한 상대하고만 통신**할 수 있어요.
> 
> 2. **관측(Observability)** — 모든 핵심 리소스의 로그가 **한 곳(LAW)**에 모여서, 문제 발생 시 빠르게 추적할 수 있어요.
> 
> 3. **자동화(Automation)** — `terraform apply` 한 번으로 50개 리소스가 의존성 순서대로 자동 배포되고, `terraform destroy`로 깔끔하게 정리돼요.
> 
> 이 세 가지가 우리 인프라의 '뼈대'예요."

---

## 📌 예상 질문 & 대응 가이드

| 질문 | 대응 |
|------|------|
| "이거 비용 얼마나 나와?" | Firewall이 제일 비싸요 (월 ~100만원). AKS, AppGW, Bastion이 그 다음. 개발 환경이라 최소 스펙으로 잡았어요. |
| "DR(재해복구)은?" | SQL은 Zone Redundant, AKS/AppGW/Firewall은 Zone 1,2,3 분산. 리전 레벨 DR은 아직 미구현 — 프로덕션 단계에서 추가 예정. |
| "CI/CD 파이프라인은?" | 이 Terraform은 인프라만 다뤄요. 앱 배포는 GitHub Actions → ACR Push → AKS 배포 파이프라인이 별도로 있어요. |
| "보안 검증은 했어?" | Checkov(정적 분석) + TFLint로 검증했어요. 71개 항목 통과. CKV2_AZURE_31(NSG 연결) 같은 건 수동 확인 완료. |
| "이거 혼자 다 짠 거야?" | 아키텍처 설계와 의사결정은 제가 했고, 코드 생성에 AI를 활용했어요. **설계 의도, 배포 순서, 문제 해결(순환 의존성 등)은 직접 경험하면서 결정한 거예요.** |

---

*최종 업데이트: 2026-02-21 | 대상: 인프라팀 + 프로젝트 리더*
