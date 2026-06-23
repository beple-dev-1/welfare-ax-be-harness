# 모듈 구조 캐시 전략

> `/develop` 스킬 7단계에서 호출된다.
> 캐시 생성·갱신은 **결정론적 스크립트**(`scripts/scan-module.ps1`) 가 담당한다. AI 추론 의존 없음 — 동일 입력 → 동일 출력.
>
> **참조 스코프 (`--ref-read`) 는 자동 스캔에서 제외된다.** 캐시 생성/갱신은 메인 스코프만 대상으로 한다. 참조 스코프 파일은 세션 중 필요 시점에 직접 Read 한다.
> 단, 이미 `scopes/{식별자}.md` 캐시가 존재하는 참조 스코프는 해당 캐시를 **읽기 전용으로 Lazy Load** 하여 구조 파악에 활용할 수 있다.
> **참조 스코프 캐시도 frontmatter `branch:` 를 검사한다.** 해당 참조 프로젝트의 현재 git 브랜치와 일치할 때만 lazy load 를 사용하고, 불일치 시 lazy load 를 포기하여 직접 Read 로 fallback 한다 (참조 스코프는 자동 재캐싱 대상이 아니므로 재생성하지 않는다).

---

## 1. 캐시 저장 경로

```
$HOME/.claude/projects/{workspace-slug}/memory/scopes/{스코프 식별자}.md
```

하위 스코프 캐시 파일명:

| 스코프 형태 | 캐시 파일명 |
|---|---|
| `batch {jobId}` | `scopes/batch--{jobId}.md` |

`scopes/` 디렉토리 미존재 시 스크립트가 자동 생성한다.

---

## 2. 스캔 모드 (스크립트 인자)

| 모드 | 트리거 | 동작 |
|---|---|---|
| `init` | 캐시 파일 없음 | 전체 스캔 → 캐시 저장 |
| `incremental` | `--refresh`, `재스캔` | `git diff --name-only HEAD` 결과 파일만 부분 업데이트 |
| `full` | `--full-rescan`, `전체 재캐싱`, frontmatter `branch:` 불일치 | 전체 재스캔 → 캐시 전체 덮어쓰기 |

---

## 3. 호출 방법

```powershell
# 메인 스코프 최초 스캔
powershell .claude/skills/develop/scripts/scan-module.ps1 -Scope ceremony -Mode init

# 증분 갱신
powershell .claude/skills/develop/scripts/scan-module.ps1 -Scope batch -Mode incremental
```

스크립트가 수행하는 것:

1. `.claude/config/scope.yaml` 에서 entry 추출 (`projectRoot`, `allowedPaths`, `sharedModule`)
2. `.claude/config/project.yaml` `basePackagePattern` → `{basePackagePath}` 변환
3. 현재 git 브랜치 확인 (`git branch --show-current`, detached HEAD → `_detached_{short-sha}`)
4. 스캔 대상 디렉토리 결정 (allowedPaths + sharedModule 의 `src/main/java`, `src/test/java`, `src/main/resources/**/*Mapper.xml`)
5. Java 파일 카운트 + 패키지 분류 (controller/service/mapper/model/config/util)
6. 캐시 파일 작성 (frontmatter `scope`, `scanned_at`, `project_root`, `branch`, `mode`)

---

## 4. 캐시 로드 흐름 (메인 Claude 측 절차)

```
1. 강제 재스캔 의도 없음:
   → scopes/{스코프 식별자}.md Read 시도 + 현재 git 브랜치 확인

   파일 없음:
     → scan-module.ps1 -Mode init 호출

   파일 있음 → frontmatter `branch:` 검사:
     a. branch 다름 또는 `branch:` 필드 없음 (구버전 캐시):
        → "⚠️ 캐시 브랜치 불일치 — 자동 전체 재캐싱" 출력
        → scan-module.ps1 -Mode full 호출
     b. branch 일치 → scanned_at 검사:
        - 7일 이상 경과: "⚠️ 캐시가 {N}일 전 생성됨. 자동 증분 재스캔"
                         → scan-module.ps1 -Mode incremental
        - 7일 미만: "📦 캐시 로드 (branch: {branch}, scanned_at: {scanned_at})"
                   ⚠️ 안내: "구조 변경 시 /develop {스코프} --refresh 요청"

2. `--refresh` / `--full-rescan` 인자:
   → 각각 -Mode incremental / -Mode full 로 스크립트 호출
```

---

## 5. 캐시 파일 형식 (스크립트 출력)

```markdown
---
scope: {스코프 식별자}
scanned_at: {ISO 8601}
project_root: {프로젝트 루트}
branch: {git 브랜치}
mode: {init|full|incremental}
---

## 스캔 결과 요약

- Java 파일: N개
- Mapper XML: M개

## 패키지 분류

| 분류 | 카운트 |
|-----|-------|
| controller | N |
| service (interface) | N |
| service (impl) | N |
| mapper | N |
| model/dto/vo | N |
| config | N |
| util | N |
| other | N |

## 스캔 대상 경로

- {경로 1}
- {경로 2}
...
```

> **상세 클래스 목록은 캐시에 저장하지 않는다** (토큰 절약). 필요 시 메인 Claude 가 Grep/Glob 으로 on-demand 조회한다 (예: `Grep "class.*Controller" {projectRoot}/src/main/java/{basePackagePath}/{module}/controller`).

---

## 6. 외부 공유

스크립트는 yaml 파싱 + 파일 시스템 스캔만 수행 — 조직 무관. 외부 조직 도입 시:

- `scope.yaml` / `project.yaml` 만 교체하면 스크립트 unchanged
- Windows PowerShell 5.1 (`powershell`, 기본 내장) 표준, PowerShell 7 호환
