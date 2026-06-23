---
name: develop
description: 프로젝트/모듈의 개발 스코프를 설정하고, 설정 파일 접근을 차단하며, 세션 종료 시 스코프 자가 점검을 수행한다. 사용자가 "ceremony 개발 시작", "member 작업할게", "common 작업", "batch 개발 세팅", "ceremony 작업하면서 common 참고", "--ref-read로 열어줘" 등 특정 프로젝트나 모듈에서 개발을 시작하려 할 때 반드시 이 스킬을 사용한다.
argument-hint: "{스코프} [과업번호] [--refresh|--full-rescan|--fe|자동]"
---

# /develop {스코프}

워크스페이스 내 모든 프로젝트/모듈에 대해 개발 작업 시 스코프를 명시적으로 제한하는 **오케스트레이터 스킬**.

> 본 스킬은 sub-skill 위임 중심: scope 데이터 검증, 보안 차단, 브랜치 처리, 계획서 로드, 모듈 캐싱 등은 모두 외부 sub-skill / script 가 담당한다. develop 자체는 흐름 제어와 접근 제어 알고리즘만 보유한다.

## 위임 맵

| 단계 | 위임 대상 |
|---|---|
| 1·2 — 스코프 파싱·경로 해석 | `.claude/config/scope.yaml` (데이터) + `references/scope-registry.md` (스키마) |
| 3 — 기밀 보호 | `/secrets-guard` 마이크로 스킬 |
| 4 — 가이드라인 로드 | `.claude/rules/dev-guide.md` + `.claude/docs/guideline/*` (lazy FE) |
| 5 — 브랜치 처리 | `/git` 스킬 (`checkout -b`) |
| 6 — 계획서·페이즈 디스패치 | `/plan-loader` 마이크로 스킬 |
| 7 — 모듈 캐싱 | `scripts/scan-module.ps1` (결정론) |
| 8·8.5·10 — 접근 제어·점검 | 본 스킬 내부 (조직 무관 알고리즘) |
| 9 — 출력 | `templates/output-templates.md` |
| 11 — 세션 마무리 | `/pack` 스킬 |

---

## 입력 형식 ($ARGUMENTS)

```
{스코프 식별자}                       예: ceremony, member, common
{스코프 식별자} {subScopeParam}        하위 스코프 (scope.yaml subScope.paramName 정의 시)
{스코프 식별자} {과업번호}             예: ceremony 057
{스코프 식별자} {과업번호} 자동         플랜 자동 모드 (plan-loader §7)
{스코프 식별자} --refresh             증분 재스캔
{스코프 식별자} --full-rescan         전체 재캐싱
{스코프 식별자} --ref-read=s1,s2      특정 스코프 읽기 참조 허용 (콤마 리스트)
{스코프 식별자} --fe                 FE 가이드 즉시 로드 (기본 lazy)
```

> **하위 스코프 지원 여부**는 `.claude/config/scope.yaml` 의 해당 entry `subScope.paramName` 정의 유무로 결정된다. 정의된 스코프는 `{스코프} {paramValue}` 형태로 호출 가능. 검증·탐색 규칙은 `references/sub-scope-rules.md` 의 generic 알고리즘.
> 인수에 3자리 숫자 → 과업번호. 미지정 시 6단계서 브랜치명 자동 추출 (plan-loader §1).

---

## 경로 표기 규칙 (전 단계 공통)

- bash/PowerShell 모두 워크스페이스 루트 기준 **상대경로** 사용 (`git -C we-adk-welfare-user ...`).
- 절대경로 불가피 시 **forward slash** (`C:/Users/.../we-adk-welfare-user`). 백슬래시 금지.
- `{projectRoot}` = 상대경로 디렉토리명 (예: `we-adk-welfare-user`).

---

## 실행 절차

### 0단계: 스코프 기능 토글 확인

`.claude/config/system.yaml` `features.scope.enabled` 를 먼저 읽는다.

- **`true`** (기본): 아래 1~11단계 전체 수행 (스코프 식별·allowedPaths 제한).
- **`false`**: **스코프 미지정 — 전체 소스 기준**. 1·2단계(스코프 파싱·경로 해석)와 `scope.yaml` 참조를 건너뛴다. 작업 대상은 전체 소스이며 8단계 스코프 외 쓰기 차단(`DENY_OUT_OF_SCOPE`)·10단계 스코프 자가 점검을 적용하지 않는다. 3단계 기밀 보호(`/secrets-guard`)는 **항상 적용**. 사용자가 특정 프로젝트를 지정하면 4~7·9·11단계는 그 `{projectRoot}` 기준으로, 미지정 시 워크스페이스 전체 기준으로 수행한다.

### 1단계: 인수 파싱 및 검증

`$ARGUMENTS` 에서 스코프 식별자 + `{paramValue}`(선택) + 과업번호 + 플래그 추출.

- 스코프 식별자는 `.claude/config/scope.yaml` `groups.*.scopes[].id` 와 대조.
- 두 번째 인자(`paramValue`)는 entry `subScope.paramName` 정의된 경우만 허용 → `references/sub-scope-rules.md` §1 generic 알고리즘으로 검증.
- 스코프 미존재 → `templates/output-templates.md` 의 "스코프 미존재 시 오류 메시지" 출력 후 중단.

**플래그:**

| 플래그 | 동작 |
|---|---|
| `--refresh`, `재스캔` | 증분 재스캔 |
| `--full-rescan`, `전체 재캐싱` | 전체 재캐싱 |
| `--ref-read=s1,s2,...` | 참조 스코프 읽기 허용 (콤마 리스트) |
| `--fe` | FE 가이드 즉시 로드 |

**`--ref-read` 검증**: 값은 `scope.yaml` 최상위 `id` 만 허용. 매칭 실패 토큰 1개라도 → "유효하지 않은 참조 스코프" 오류 후 중단. 메인 스코프 동일 식별자 포함 시 무시 + 경고 1줄. 하위 스코프 식별자는 값으로 받지 않음.

### 2단계: 경로 해석

`scope.yaml` 매칭 entry + `project.yaml` `projects[]` 조회로 결정:

| 변수 | 출처 |
|---|---|
| `{projectRoot}` | entry `project` (= project.yaml `projects[].name`) |
| `{projectType}` | project.yaml `projects[].guideline.backend` 기반 분류 (derived by name) |
| `{multiModule}` | project.yaml `projects[].multiModule` |
| `{effectiveAllowedPaths}` | `paramValue` 없음 → entry `allowedPaths` / `paramValue` 있음 → `subScope.allowedPaths` 변수 치환 결과 (`sub-scope-rules.md` §1-2) |
| `{sharedModule}` | entry `sharedModule` (또는 null) |
| `{groupSharedRange}` | `paramValue` 있고 `scanPaths == "@inherit-shared"` 시 그룹 `sharedCodeRange` 확장 결과 (`sub-scope-rules.md` §2-2). 그 외 빈 집합 |
| `{guideline}` | project.yaml `projects[].guideline` (= `{backend, frontend?}`) |
| `{refReadScopes}` | `--ref-read` 값 |
| `{refReadPaths}` | `--ref-read` 각 스코프의 allowedPaths 합집합 |

### 3단계: 기밀 보호 활성

`/secrets-guard` 호출. 세션 전체 차단 정책: YML/YAML/properties (`src/**/resources/**`), Jasypt `ENC(...)` 복호화 금지, 민감 파일(`.env`, `credentials.json`, `*.pem`, `*.p12`, `id_rsa*`). 참조 스코프에도 동일 적용. 설정 값 필요 시 사용자에게 직접 요청.

### 4단계: 가이드라인 로드

본 단계 진입 시 `.claude/config/project.yaml` Read (lazy load — develop 진입 시점 아니라 4단계 진입 시점).

1. `.claude/rules/dev-guide.md` (필수 — 공통 정책)
2. **가이드라인 결정**: project.yaml `projects[].guideline` 의 `{backend, frontend?}` 사용
3. **로드 규칙**:
   - `backend` → 필수, 즉시 Read
   - `frontend[]` (배열) → 기본 lazy: FE 파일(`*.html`, `*.js`, `*.css`, `views/`, `static/`) 첫 Read/Edit 시점 로드. `--fe` 플래그 시 즉시. 로드 시 "📘 FE 가이드 로드: {파일}" 1줄 출력
4. `{projectRoot}/CLAUDE.md` (필수)

가이드 파일 경로: `.claude/docs/guideline/{filename}` (project.yaml `projects[].guideline` 값은 파일명만).
파일 미존재 → "⚠️ {파일명}을 찾을 수 없습니다." 출력 후 진행.

### 5단계: 브랜치 확인 및 생성

```bash
git -C {projectRoot} branch --show-current
```

- `feature/*` / `hotfix/*` → "🌿 현재 브랜치: {branch}", 종료.
- 그 외 → 사용자에게 작업 유형(feature / feature/internal / hotfix) 확인 → `/git checkout {project} -b {branch} [--from {parent}]` 위임.

> 브랜치 전략 규격: `.claude/rules/base-rule.md` §2. 생성 절차: `/git` 스킬.

### 5.5단계: HANDOFF 컨텍스트 surface (develop 고유)

세션 재시작·브랜치 전환 대비 메인 스코프 컨텍스트 surface. **데이터 변경 없음** — stale 보존은 `/pack` 0단계 P2 담당.

> **외부 공유 의존성**: 본 단계는 워크스페이스 루트 `HANDOFF.md` + `HANDOFF_HISTORY.md` 포맷(`projects:` frontmatter, `## {project} @ \`{branch}\`` 섹션, `### Plan/Next/Caution`)에 의존한다. 다른 워크스페이스로 이식 시 `.claude/CLAUDE.md` 의 HANDOFF 규약 + `/pack` 스킬을 동반 이식해야 한다. HANDOFF 파일 부재 환경에서는 본 단계 결과가 "이전 컨텍스트 없음" 으로 분기되어 다른 단계 동작에는 영향 없음.

#### 5.5-a. 브랜치 정합성 검사

1. 워크스페이스 루트 `HANDOFF.md` frontmatter `projects:` 표에서 `{projectRoot}` 항목 추출. 항목 없음 → "활성 부재".
2. 현재 git 브랜치 확인 (detached HEAD → `_detached_{short-sha}`).
3. 비교:
   - 섹션 있음 + 브랜치 일치 → **정상 분기**
   - 섹션 없음 또는 브랜치 불일치 → **HISTORY 분기**

#### 5.5-b. 컨텍스트 surface

**정상 분기**: 루트 HANDOFF.md `## {projectRoot} @ \`{branch}\`` 섹션의 `### Plan` / `### Next` (최대 5) / `### Caution` (최대 3) 을 9단계 "이전 세션 컨텍스트" 로 출력.

**HISTORY 분기**: `HANDOFF_HISTORY.md` 에서 `## {ts} — {projectRoot} @ {cur-branch}` 매칭 가장 최근 entry 1개를 `grep -m 1 -A 30` 으로 read. 매칭 시:
- `### Done` 전체 surface
- `### In-progress (snapshot)` Plan / Next / Caution surface
- "루트 HANDOFF.md 활성 섹션 부재/stale, HANDOFF_HISTORY.md `{entry-ts}` entry 에서 surface" 1줄
- stale 경우: "stale 프로젝트 섹션은 다음 pack 시 HISTORY 로 자동 보존됩니다 (pack 0단계 P2)" 1줄

매칭 없음 → "이전 컨텍스트 없음 (브랜치 신규 또는 첫 작업)".

**`--ref-read` 활성 시**: 참조 스코프 프로젝트들도 동일 분기 적용, "[참조 — {프로젝트명}]" 태그로 메인과 구분 (쓰기 차단 강조).

### 6단계: 개발 계획서 확인

`/plan-loader` 위임. 인자: 추출한 과업번호 + 진행 모드(`자동` 어휘 포함 여부).

반환:
- 페이즈 목록 (BE/FE 영역·슬러그·의존)
- 사용자 선택 → dev-backend / dev-frontend sub-agent 디스패치 지시
- 계획서 부재 시 분기 안내

과업번호 추출 불가 → 본 단계 skip.

### 7단계: 모듈 구조 캐싱

```powershell
powershell .claude/skills/develop/scripts/scan-module.ps1 -Scope {스코프} [-SubScopeParam {paramValue}] -Mode {init|full|incremental}
```

`-SubScopeParam` 은 1단계에서 검증된 `paramValue` (`scope.yaml` `subScope.paramName` 정의된 스코프에 한해). 탐색 대상 경로는 `subScope.scanPaths` + `allowedPaths` 합산 → `references/sub-scope-rules.md` §2.

모드 결정:
- 캐시 없음 → `init`
- `--refresh` → `incremental`
- `--full-rescan` 또는 frontmatter `branch:` 불일치 → `full`
- 7일 경과 + branch 일치 → 자동 `incremental`

참조 스코프(`--ref-read`)는 자동 스캔 제외. 기존 캐시 있으면 Lazy Load (branch 일치 시만).

### 8단계: 스코프 접근 제어 알고리즘

```
judgeAccess(filePath, operation):
  # 0. 보편적 차단 (secrets-guard 정책)
  if filePath under (**/src/**/resources/**/*.yml|*.yaml|*.properties):
    return DENY_ALWAYS

  # 1. 메인 스코프 (읽기+쓰기)
  # paramValue 활성 시 effectiveAllowedPaths = subScope.allowedPaths 변수 치환 결과 (entry.allowedPaths 의 `**` 무시)
  # paramValue 비활성 시 effectiveAllowedPaths = entry.allowedPaths
  if filePath under {effectiveAllowedPaths} OR mainScope.sharedModule OR {groupSharedRange}:
    return ALLOW

  # 2. 참조 스코프 (읽기만)
  if filePath under any({refReadPaths}):
    return (operation == "read") ? ALLOW_REF_READ : DENY_REF_WRITE

  # 3. 워크스페이스 메타 (항상 허용)
  if filePath under workspaceMetaPaths:
    return ALLOW

  # 4. 그 외
  return DENY_OUT_OF_SCOPE
```

**워크스페이스 메타 경로** (항상 허용):
- `{workspaceRoot}/.claude/**` (스킬·규칙·가이드라인·메모리)
- `{workspaceRoot}/target/**` (계획서·작업 결과)
- `{workspaceRoot}/HANDOFF.md`, `HANDOFF_HISTORY.md`, `CLAUDE.md`
- 각 프로젝트 `CLAUDE.md` (가이드라인 로드용)

**Glob/Grep**: `path` 명시 시 허용 경로 검증. 미지정 시 쿼리 허용 + 결과 필터링.

> 판정 결과별 출력: `templates/output-templates.md` "스코프 외 접근 차단 (8단계)".

### 8.5단계: 세션 중 참조 스코프 동적 변경

트리거 키워드에 `참조` 또는 `ref-read` 포함 필요. 모호 시 확인 우선.

| 의도 | 예시 | 동작 |
|---|---|---|
| 추가 | "참조 X 추가" | `{refReadScopes}` 에 추가 |
| 제거 | "참조 X 제거", "ref-read에서 X 빼줘" | `{refReadScopes}` 에서 제거 |

승인 후 `{refReadScopes}`·`{refReadPaths}` 갱신 + 1줄 요약. 영구 저장 ❌ — 현재 세션만.

> 이미 컨텍스트에 로드된 참조 스코프 파일은 제거 후에도 기억에서 사라지지 않는다 (이후 새 Read 만 차단).

### 9단계: 세션 시작 요약 출력

스코프 테이블(프로젝트·브랜치·허용 범위)만 간결 출력. 컴포넌트·아키텍처·규칙은 내부 로드만, 출력 ❌.

추가 행:
- 계획서 로드 시 → 계획서 정보 1줄
- `{refReadScopes}` 비어있지 않음 → "참조 범위 (읽기 전용)" 행
- 5.5단계 surface 결과 있음 → "이전 세션 컨텍스트" 섹션 (Plan / Next 최대 5 / Caution 최대 3, ref 시 별도 그룹)

> 형식: `templates/output-templates.md` "세션 시작 요약 (9단계)".

### 10단계: 스코프 자가 점검

커밋·종료 전 점검:

- **#1**: 메인 스코프 외 쓰기 시도 (Edit/Write)
- **#2**: 허용되지 않은 스코프 파일 읽기 (ref-read 미포함). ref-read 허용 읽기는 "참조 목적 읽기: N건 ({스코프})" 비고 기록.

> 기밀(YML/Properties/ENC) 점검은 `/secrets-guard` 정책으로 정상 흐름에서 위반 발생 안 함.
> 출력: `templates/output-templates.md` "스코프 자가 점검 (10단계)".

### 11단계: 세션 마무리

10단계 통과 → `/pack` 호출. 워크스페이스 루트 `HANDOFF.md` + `HANDOFF_HISTORY.md` 자동 갱신.

위반 잔여 시 → 수정 → 재점검 → `/pack`.
