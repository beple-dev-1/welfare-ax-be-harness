# HANDOFF_HISTORY.md 형식

> pack 스킬 **0단계(P2)** 와 **5단계** 에서 참조하는 워크스페이스 루트 `HANDOFF_HISTORY.md` 작성 형식.
> 이 파일은 **단일 파일** 이며 프로젝트별 분리 없이 모든 프로젝트의 entry 가 시간 역순으로 누적된다 (새 entry 는 파일 최상단에 prepend).
> frontmatter 없음.

<Header_Format>

각 entry 의 헤더는 정확히 아래 형식을 따른다:

```
## {ISO 8601 타임스탬프} — {project} @ {branch}
```

- 타임스탬프 형식: **KST, 초 생략** `yyyy-MM-ddTHH:mm+09:00` (예: `2026-05-05T17:42+09:00`). 0단계 P2 스크립트·4단계 `updated:` 와 동일.

- 예: `## 2026-05-05T17:42+09:00 — {프로젝트명} @ develop`
- **`{project}` 는 반드시 실제 프로젝트 디렉토리명.** `workspace`, `meta`, `multi`, `common`, `all` 등 가상 이름 금지. branch/project 별 awk 조회가 깨지므로 절대 사용하지 않는다.
- `{branch}` 는 작성 시점의 git 브랜치. detached HEAD 시 `_detached_{short-sha}`.
- 한 세션에서 멀티 프로젝트 작업 시 **프로젝트별 별도 entry** (같은 타임스탬프 사용, 자연스럽게 인접하여 prepend 됨).

</Header_Format>

<Body_Structure>

본문은 `### Done` (bullet list) + `### In-progress (snapshot)` (Plan/Next/Caution) 두 섹션으로 구성된다.

```markdown
## 2026-05-05T17:42+09:00 — {프로젝트명} @ develop

### Done
- 중복 클릭 가드 17건 중 CRITICAL 8건 적용
- DuplicateClickGuard 인터셉터 등록

### In-progress (snapshot)
**Plan**: 가드 적용 범위를 WARNING 등급 9건까지 확장
**Next**:
1. WARNING 9건 분류
2. 가드 적용 PR 분리
**Caution**: KMC 결제 페이지는 별도 검증 필요

---
```

- **In-progress (snapshot)** 은 그 entry 작성 시점의 HANDOFF.md 해당 프로젝트 섹션의 Plan/Next/Caution 을 **요약 복제** 한 것. 이후 HANDOFF.md 가 갱신되어도 이 스냅샷은 변하지 않는다 — 그래서 "그 시점의 진행중 컨텍스트" 가 영구 보존된다.
- **Plan / Caution 미사용 시** 해당 줄 생략.

</Body_Structure>

<Termination_Marker>

각 entry 의 끝(다음 `## ` 헤더 직전)에 **빈 줄 + `---` + 빈 줄** 형태의 종결 마커를 둔다.

```
...본문 마지막 줄
                      ← 빈 줄
---                   ← 종결 마커
                      ← 빈 줄
## 2026-05-04T...     ← 다음 entry 헤더
```

**왜 종결 마커가 필요한가**: entry 길이가 들쭉날쭉이라 `grep -A {N}` 같은 고정 라인 수 추출은 부정확하다. 종결 마커가 있어야 awk/sed 로 정확한 entry 경계 추출이 가능하다.

**조회 명령**:

| 목적 | 명령 |
| ---- | ---- |
| 단일 entry (가장 최근) | `awk '/— {project} @ {branch}$/{f=1} f; f && /^---$/{exit}' HANDOFF_HISTORY.md` |
| 브랜치별 모든 entry | `awk '/@ {branch}$/,/^---$/' HANDOFF_HISTORY.md` |
| 특정 시점 entry | `awk '/^## {ISO타임스탬프}.*— {project}.*@ {branch}$/,/^---$/' HANDOFF_HISTORY.md` |
| 상단 5개 entry (세션 시작 규칙) | `awk '/^## /{c++} c>5{exit} {print}' HANDOFF_HISTORY.md` |

</Termination_Marker>

<Entry_Conditions>

5단계에서 entry 추가 여부 판정:

| 조건 | entry 추가? |
| ---- | ----------- |
| 이번 세션 Done 1건 이상 | ✅ 정상 entry (Done + In-progress snapshot) |
| Done 0건 | ❌ HANDOFF.md 만 갱신, entry 없음 |
| 0단계 P2 발동 (stale 보존) | ✅ 별도 entry — `### In-progress (snapshot)` 만, **`### Done` 섹션 없음** |
| 영향 받은 프로젝트 0개인 공통 경로(`.claude/`, `target/` 등)만 변경 | ❌ HISTORY entry 자체 생략, `Common Files` 만 추적 |

**P2 stale 보존 entry 변형**:

0단계에서 stale 프로젝트 섹션을 보존할 때는 Done 이 없는 변형 entry 를 prepend 한다 (헤더의 `{branch}` 는 frontmatter 에 기록돼 있던 옛 브랜치):

```markdown
## {now-ISO} — {project} @ {기록된 옛 브랜치}

### In-progress (snapshot)
**Plan**: ...
**Next**:
1. ...
**Caution**: ...

---
```

0단계 P2 entry 가 prepend 된 후 5단계의 정상 entry 도 prepend 되면, 시간 역순 정렬 상 정상 entry 가 최상단, P2 stale 보존 entry 가 그 아래에 위치한다.

</Entry_Conditions>

<Multi_Project_Rule>

한 세션에서 멀티 프로젝트를 작업한 경우 **프로젝트별 별도 entry** 를 작성한다 (같은 타임스탬프).

**각 entry 는 자체로 독립적**이어야 한다 — 다른 entry 를 참조해야 의미가 통하는 작성은 금지. 그 프로젝트에서 일어난 변경의 핵심을 entry 안에서 완결적으로 기술한다.

**워크스페이스 공통 작업이 N 프로젝트에 영향을 미친 경우**: 공통 작업의 **한 줄 요약** 을 각 entry Done 에 그 프로젝트 한정 영향과 함께 포함한다.

예시:
```
- 메타 작업 ({프로젝트명} CLAUDE.md 압축) 일환 — {프로젝트명}/CLAUDE.md 312→245줄, -67줄. 캐시백 정책 표 별도 doc 분리.
```

**공통 경로(`.claude/`, `target/` 등) 만의 변경**:
- 영향 받은 프로젝트가 0개 → HISTORY entry 자체 생략. `HANDOFF.md` 의 `Common Files` 섹션에서만 추적.
- 영향 받은 프로젝트가 1개 이상 → 각 프로젝트 entry 의 Done 안에 짧게 언급.

</Multi_Project_Rule>

<Scope_Detection>

프로젝트 식별: 세션 중 생성/수정한 파일의 경로에서 **워크스페이스 루트 기준 첫 번째 디렉토리** 가 프로젝트명.

| 파일 경로 | 프로젝트 | HISTORY entry? |
| --------- | -------- | -------------- |
| `{프로젝트명A}/src/.../Foo.java` | `{프로젝트명A}` | ✅ (Done 있으면) |
| `{프로젝트명B}/src/.../bar.java` | `{프로젝트명B}` | ✅ (Done 있으면) |
| `.claude/skills/pack/SKILL.md` | (공통, 어느 프로젝트도 아님) | ❌ 단독으로는 생략 |
| `HANDOFF.md`, `HANDOFF_HISTORY.md` | (워크스페이스 루트 직접) | ❌ pack 산출물 자기 자신 |

</Scope_Detection>

<Overflow_Notice>

`## ` 시작 헤더를 카운트하여 100개 초과 시 5단계 마지막에 안내 메시지 1줄을 출력한다 (자동 회전 없음).

```
⚠️ HANDOFF_HISTORY.md 에 entry 가 {N}개 누적되어 있습니다. 비대해지면 직접 잘라내거나 분리 파일로 옮기세요. 자동 회전은 없습니다.
```

</Overflow_Notice>
