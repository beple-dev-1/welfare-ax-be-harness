# 스코프 레지스트리 — 스키마 문서

> **데이터 위치**: `.claude/config/scope.yaml` (조직별 교체 가능)
>
> 본 문서는 스코프 레지스트리의 **데이터 스키마와 사용법**을 정의한다. 데이터 추가·변경 시 `scope.yaml` 만 수정한다.

---

## 1. 데이터 파일 형식

```yaml
groups:
  {GroupKey}:                          # A-K 그룹 (조직 자유)
    name: {그룹명}                      # 사용자 표시용
    scopes:
      - id: {스코프 식별자}             # 사용자가 /develop 인자로 입력
        project: {프로젝트명}            # project.yaml `projects[].name` 참조
        allowedPaths: [{허용 경로 목록}] # 메인 스코프 쓰기 허용 범위 (프로젝트 루트 기준)
        sharedModules: [{공유 모듈 경로 목록}]   # 없으면 []
        subScope:                       # 선택 — 하위 스코프 지원 시
          paramName: {파라미터명}        # 예: jobId — /develop 두 번째 인자명
          validatePath: {경로}           # paramValue 유효성 검증 디렉토리 (변수 치환 후 존재 확인)
          allowedPaths: [...]            # paramValue 지정 시 메인 쓰기 허용 경로 (변수 치환)
          scanPaths: "@inherit-shared" | [...]  # 7단계 스캔 대상. "@inherit-shared" 시 그룹 sharedCodeRange 상속
          cacheFileSuffix: "--{paramValue}"     # 캐시 파일명 접미사 패턴
    sharedCodeRange:                    # 선택 — 하위 스코프 시 항상 허용 코드
      java: [...]
      javaRootFiles: ...
      resources: [...]
```

> **truth source 분리**: 프로젝트 정보(`name/shortName/multiModule/role/guideline`)는 `project.yaml` `projects[]` 가 마스터. 본 파일의 `project:` 는 그 name 을 참조하며, derived 정보가 필요하면 project.yaml 에서 조회.

---

## 2. 가이드라인 결정 (project.yaml 단일 출처)

`scope.yaml` 에는 `guideline:` 필드가 없다. 가이드는 `project.yaml projects[].guideline` 에서 derived:

형식 (project.yaml 측):

```yaml
projects:
  - name: we-adk-welfare-user
    guideline:
      backend: guide-springboot-web.md
      frontend: [guide-frontend/common.md]
```

→ `backend` 즉시 로드. `frontend[]` 는 lazy (FE 파일 첫 Read/Edit 시점 또는 `--fe` 플래그 시 즉시).

---

## 3. 하위 스코프 (subScope)

식별자 + 파라미터 구조의 generic 하위 스코프 (조직별 어휘 무관).

| 필드 | 용도 |
|---|---|
| `paramName` | `/develop` 두 번째 인자명 (사용자 표시 + 검증 메시지). |
| `validatePath` | `paramValue` 유효성 검증 디렉토리. 존재하지 않으면 오류. |
| `allowedPaths` | `paramValue` 지정 시 메인 쓰기 허용 경로 리스트. `{paramValue}`·`{basePackagePath}` 변수. |
| `scanPaths` | 7단계 스캐너 대상. 명시적 리스트 또는 `"@inherit-shared"` 토큰. |
| `cacheFileSuffix` | 캐시 파일명 접미사 (`{scopeId}{suffix}.md`). |

**그룹 sharedCodeRange**: `scanPaths: "@inherit-shared"` 시 그룹 단위 공통 코드 정의가 상속된다.

**검증·탐색 규칙**: `sub-scope-rules.md` 의 generic 알고리즘 참조.

---

## 4. 변수 참조

`scope.yaml` 내 변수는 `.claude/config/project.yaml` 에서 주입:

| 변수 | 출처 |
|---|---|
| `{basePackagePattern}` | project.yaml `basePackagePattern` 키 (예: `com.beplepay.weadk.welfare.{module}`) |
| `{workspaceName}` | project.yaml `workspaceName` 키 |

---

## 5. 스코프 추가 절차

1. `.claude/config/scope.yaml` 적절한 그룹 (또는 신규 그룹) 에 entry 추가
2. 하위 스코프 필요 시 `subScope` + `sharedCodeRange` 작성
3. 가이드라인 파일이 `.claude/docs/guideline/` 에 존재하는지 확인
4. 신규 가이드가 필요하면 `.claude/docs/guideline/` 에 guide 파일 추가 + `project.yaml` `guideline.backend` 지정

---

## 6. 외부 조직 도입

스킬 본문(`SKILL.md`, `references/*`) 수정 불필요. 아래 두 파일만 교체:

| 파일 | 내용 |
|---|---|
| `.claude/config/scope.yaml` | 조직 프로젝트 인벤토리 |
| `.claude/config/project.yaml` | 패키지 패턴, DB 메타 등 워크스페이스 글로벌 |

---

## 7. 그룹 정의 (현 프로젝트)

현 프로젝트(`we-adk-welfare`)의 `scope.yaml` 은 3개 그룹으로 구성된다.

### service — 서비스 도메인

플랫폼이 사용자에게 제공하는 **업무 단위**. 비즈니스 요구사항이 직접 구현되는 레이어.

| 스코프 | 주 프로젝트 | 설명 |
|---|---|---|
| `ceremony` | `we-adk-welfare-user` | 경조사지원 — 신청·승인·지급·정산 |

> 새 서비스 도메인(병원비 지원, 주거비 지원 등) 추가 시 이 그룹에 scope entry를 추가한다.

### core — 복지 공통 도메인

**모든 서비스 도메인이 공통으로 의존하는 핵심 도메인 엔티티**.
서비스가 추가되어도 이 그룹의 구성원은 플랫폼 전체 기반으로 유지된다.

| 스코프 | 주 프로젝트 | 설명 |
|---|---|---|
| `member` | `we-adk-welfare-domain` | 혜택을 받는 회원 엔티티·레포지토리 |
| `merchant` | `we-adk-welfare-domain` | 혜택을 사용하는 가맹점 엔티티·레포지토리 |

### infra — 공통 인프라·실행

비즈니스 로직과 무관하게 **플랫폼 전체를 가동시키는 기반**.
어떤 서비스 도메인이 추가되어도 이 그룹은 변경되지 않는다.

| 스코프 | 주 프로젝트 | 설명 |
|---|---|---|
| `common` | `we-adk-welfare-common` | 예외·응답 래퍼·JWT·보안 설정 등 기술 인프라 |
| `admin` | `we-adk-welfare-admin` | 관리자 API 실행 모듈 (skeleton) |
| `batch` | `we-adk-welfare-batch` | 배치 처리 실행 모듈 (skeleton) |

### 의존 방향

```
service (ceremony, ...)
    ├──→ core   (sharedModules 참조)
    └──→ infra/common

core (member, merchant)
    └──→ infra/common

infra/admin, infra/batch
    ├──→ core 전체   (sharedModules 참조)
    └──→ infra/common
```

의존은 항상 단방향(`service → core → infra`). 역방향 참조는 발생하지 않는다.

### we-adk-welfare-user 모듈의 스코프 분산

`we-adk-welfare-user` 는 실행 모듈로, 내부 패키지 성격에 따라 두 스코프로 분산된다.

| 패키지 | 담당 스코프 |
|---|---|
| `user/ceremony/**` | `ceremony` (service 그룹) |
| `user/config/**`, `user/security/**`, `user/client/**` | `common` (infra 그룹) |
