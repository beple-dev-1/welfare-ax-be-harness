---
name: dev-interview
description: 기획서·주제를 받아 자율 인터뷰로 업무↔코드·DB 매핑을 완성하고 11섹션 개발 브리프를 생성한다. **Composable 오케스트레이터** — Phase 0-2 기획서 파싱은 parse-spec-doc sub-skill, 자율 선탐색은 code-investigator/db-meta-manager/security-auditor 3 sub-agent 를 병렬 dispatch 로 위임. 모든 질문은 1:1 대화형. 인터뷰 종료 후 텍스트 확인 1회로 브리프 저장(+Q&A 로그 부록 자동 첨부) → 후속 스킬(`.claude/config/project.yaml` 의 `planSkill`) 즉시 연계 가능. 사용자가 "dev-interview", "개발 인터뷰", "요구사항 인터뷰", "요구사항 정리", "기능 구체화", "기획서 분석", "뭘 만들어야 할지 정리해줘", "요구사항이 모호해", "어떻게 만들어야 할지 모르겠어" 등을 언급하면 이 스킬을 사용한다.
argument-hint: "[기획서 경로 | 주제]"
---

# /dev-interview [기획서 경로 | 주제]

기획서·주제를 받아 **자율 인터뷰**로 업무↔코드·DB 매핑을 완성하고 **11섹션 개발 브리프** (+ Q&A 로그 부록) 를 생성한다.

**Composable 오케스트레이터** — 토픽별 탐색은 sub-agent (code-investigator·db-meta-manager·security-auditor) 로, 문서 파싱·출력 스키마는 sub-skill / references 로 위임. 본 스킬은 dispatch + 통합 + 1:1 인터뷰 + 검토 게이트만 담당.

모든 질문은 **1:1 (한 번에 1질문)**. 선택지가 있는 질문(STRONG/MEDIUM 갭·프로젝트 선택·Escalate·저장 확인)은 네이티브 `AskUserQuestion` 클릭형으로, 근거 빈약한 WEAK 갭은 텍스트 열린 질문으로 전달. 인터뷰 종료 후 **확인 1회로 마감** → `.claude/config/project.yaml` 의 `planSkill` 즉시 연계 가능.

---

## ★ 사전 로드 (반드시 첫 단계)

본 스킬 진입 즉시 다음 **1개 파일만** Read (변수화 동작 결정):

| 파일 | 용도 |
|------|------|
| `.claude/config/project.yaml` | 프로젝트 인벤토리·outputDir·DB·후속스킬 등 전 동작 변수 |

이후 본문에서 `{{config.xxx}}` 표기는 `project.yaml` 의 해당 키 값으로 치환.

### Lazy-load (사용 직전 Read)

| 파일 | Read 시점 |
|------|----------|
| `references/phase01-checklist.md` | Phase 0-1 진입 시 |
| `.claude/docs/agents/common/security-policy.md` | 자율 선탐색 dispatch 직전 |
| `references/missing-topic-reminders.md` | 자율 선탐색 통합 단계 |
| `references/round-header-formats.md` | 첫 1:1 라운드 진입 시 |
| `references/gap-categories.md` | 첫 1:1 라운드 진입 시 |
| `references/brief-schema.md` | Stage 1 형식 게이트 직전 |
| `scripts/validate-brief.ps1` | Stage 1 결정론 검증 (브리프 임시 작성 직후) |
| `.claude/config/system.yaml` | Stage 2 진입 시 (`reviewerAgent` 값 확인) |
| `references/codex-output-contract.md` | Stage 2 진입 시 (reviewerAgent != none) |
| `templates/qna-log-appendix.md` | Stage 2 통과 후 부록 생성 시 |
| `references/completion-hooks.md` | 저장 후 안내 직전 |

> references 본문은 사용 시점까지 메인 컨텍스트 미진입.

---

## 핵심 원칙

1. **모든 질문 1:1 대화형 — 한 번에 1질문.** STRONG/MEDIUM 갭·Phase 0-1 프로젝트 선택·Escalate·저장 확인은 네이티브 `AskUserQuestion` (질문 객체 **1개**, 클릭형 선택지). WEAK 소크라테스식은 텍스트 열린 질문. 도구는 호출당 4질문까지 허용하나 본 스킬은 1질문 고정 (연쇄 영향·근거 갱신 보존).
2. **자율 판단** — 탐색 깊이·질문 방식·갭 식별을 Claude 가 결정. 8-Phase 스크립트 없음.
3. **사용자 입력 그대로** — `$ARGUMENTS` 이전 대화 맥락 추측 채움 금지.
4. **매끄러운 후속 연계** — 인터뷰 종료 후 시스템 승인 게이트 없이 텍스트 확인 1회로 저장 → `{{config.planSkill}}` 즉시 호출 가능.
5. **자율 선탐색 자동 트리거** — Phase 0-1 (+ 0-2) 컨디션 만족 시 사용자 컨펌 없이 즉시 3 sub-agent 병렬 dispatch. "탐색할까요?" 질문 금지.

---

## 입력 형식

```
$ARGUMENTS = 기획서 파일 경로 | 주제 문자열 | (빈 값)
```

| 모드 | 인자 예시 | 초기 동작 |
|------|----------|----------|
| 기획서 파일 | `c:/docs/기획서.pdf` (확장자 `.pdf` / `.pptx` / `.docx` / `.xlsx` + 존재 확인) | Phase 0-1 (5번 skip) → 0-2 parse-spec-doc → 자율 선탐색 |
| 주제 | `경조사 지급 처리` (길이 ≥ 3자) | Phase 0-1 (4번 확장) → 0-2 skip → 자율 선탐색 |
| 대화형 | (빈 값) | Phase 0-1 전체 → 기획서 유무 분기 → 자율 선탐색 |

---

## 실행 규칙

### 보안·접근 제약

전체 정책은 **`.claude/docs/agents/common/security-policy.md` 단일 출처** (자율 선탐색 dispatch 직전 lazy Read). 본 스킬 + parse-spec-doc sub-skill + 3 sub-agent(code-investigator·db-meta-manager·security-auditor) 공통 적용.

핵심 요약:

- 워크스페이스 루트 read-only. 쓰기는 `{{config.outputDir}}` / `{{config.tempDir}}` 하위만.
- 금지 파일 패턴(`src/**/resources/**/*.yml` 등) Read 금지.
- 암호화 마커(`ENC(...)` 등) 복호화 시도 금지.
- DB 실데이터 SELECT 금지 (메타만 — sub-agent `db-meta-manager`).
- 자기 참조 금지 (`target/designs/`, `target/sim/`, `target/samples/`).

### 인터뷰 진행 규칙

- 모든 질문 1:1 (한 번에 1질문). 갭 묶음 금지. STRONG/MEDIUM 갭은 `AskUserQuestion`, WEAK 갭은 텍스트 열린 질문.
- 가설 기반 질문은 근거 1줄 제시.
- 코드/DB/기획서에서 파악 가능한 내용은 질문하지 않음 — 가설 제시 후 확인만.
- "별첨 스펙 필요" 단정 전 sub-agent `code-investigator` 호출.

---

## 전체 플로우

```
1. 인자 해석 → 모드 결정
2. Phase 0-1: 기본 정보 수집 (references/phase01-checklist.md)
3. Phase 0-2: 기획서 파싱 (Skill(parse-spec-doc) — 파일 있을 때만)
4. **자율 선탐색 (자동 트리거)** — Phase 0-1 (+ 0-2) 직후 다음 응답에서 사용자 확인 없이 즉시 3 sub-agent 병렬 dispatch (code-investigator / db-meta-manager / security-auditor)
5. 갭 식별 + 1:1 질문 (한 갭당 한 메시지, 라운드 메타 누적)
6. 모든 갭 해소 → 11섹션 브리프 임시 작성 (사용자 미노출)
6.1 Stage 1: 형식 게이트 self-check (references/brief-schema.md)
6.2 Stage 2: reviewerAgent 정성 검토 (references/codex-output-contract.md)
    ├─ RED + 라운드 < 3: 재인터뷰 1-by-1 → 6 복귀
    ├─ RED + 라운드 = 3: 사용자 escalate
    ├─ YELLOW: 코멘트 노출 후 진행
    └─ GREEN: 진행
6.5 Q&A 로그 부록 자동 생성 (templates/qna-log-appendix.md)
6.6 사용자에게 브리프 + 부록 + 검토 결과 제시 → "이 내용으로 저장할까요?" 1회 확인
7. 사용자 OK → Write `{{config.outputDir}}/{taskId}_dev_brief.md`
8. 임시 파일 정리 안내 + 다음 단계 안내 (references/completion-hooks.md)
```

**총 예산**: 선탐색 5~10분 + 인터뷰 10~30분 + Stage 2 검토 5~15분 = **약 20~55분**

---

## Phase 0-1: 기본 정보 수집

5항목을 **1개씩 순서대로** 질문. 항목 1(프로젝트)은 `AskUserQuestion` 클릭형(options = `{{config.projects[].name}}`), 항목 2~5는 텍스트 질문. 상세 항목·도구 호출 규격·모드별 사전 보유는 **`references/phase01-checklist.md`** 참조.

---

## Phase 0-2: 기획서 파싱 (parse-spec-doc 위임)

```
Skill(skill="parse-spec-doc",
      args="filePath={경로} outputDir={{config.tempDir}}/pre_exp_{N}/ taskNumber={N}")
```

반환 status 별 분기:
- `success` → parsed_doc.txt 경로 사용 (자율 선탐색의 한 입력)
- `ocr_required` / `empty_text_likely_image_pdf` → 사용자에게 OCR 또는 화면 설명 요청
- `error_*` → 사용자에게 정정 요청

실패 처리 로직은 sub-skill 내부 책임. 본 스킬은 status 분기만.

> 기획서는 내부 문서이므로 민감정보 취급 대상 아님.

---

## 자율 선탐색 (2단 분리: 메인 → sub-agent 직접 dispatch)

**자동 트리거 — 사용자 승인 불요.** Phase 0-2 완료 (또는 기획서 없을 시 Phase 0-1 종료) 직후 **메인은 다음 응답에서 즉시** 3 sub-agent 를 **단일 응답 내 다중 Agent 호출 블록**으로 병렬 dispatch 한다.

### 자동 트리거 규칙 (필수)

- **컨디션**: Phase 0-1 완료 (5항목 답변 누적) **AND** (기획서 모드일 경우 Phase 0-2 success / OCR fallback 완료).
- **타이밍**: 컨디션 만족 직후 메인의 다음 단일 응답 안에서 3 Agent 호출. 그 응답에는 다른 텍스트·질문 없이 dispatch 만 포함 (한 줄 진행 안내 허용).
- **사용자 확인 금지**: "탐색 시작할까요?" / "Y/N?" 같은 컨펌 질문 금지. dispatch 가 곧 진행 신호.
- **skip 금지**: 3 sub-agent 중 하나라도 빠뜨리면 통합 단계 결과 불완전. project.yaml 의 `db.vendor` 미설정 등 사전 미충족이면 그 agent 만 skip + 통합 단계에 "{agent} skipped — {사유}" 표기.
- **재호출 금지**: 동일 taskNumber 로 중복 dispatch 금지. 결과 미흡 시 통합 단계 §3 inline Grep 백업 또는 1:1 라운드에서 보강.

### 책임 분리 원칙

- **메인 (dev-interview)** = sub-agent 3개 dispatch + 결과 통합. agent 내부 playbook 모름.
- **sub-agent** = `.claude/agents/{code-investigator,db-meta-manager,security-auditor}.md` 정의에 따라 playbook 실행 (references/templates/scripts Read 포함) + 마크다운 결과 반환.

### Dispatch 템플릿

각 Agent 호출은 `subagent_type` 으로 직접 지정. prompt 는 입력 계약(key=value) 만 전달:

> ```
> Agent(subagent_type="code-investigator",
>       prompt="primary={대상 프로젝트} related={연동 후보 JSON} topicHints={키워드 JSON} taskNumber={N}")
> Agent(subagent_type="db-meta-manager",
>       prompt="topicHints={키워드 JSON} taskNumber={N}")
> Agent(subagent_type="security-auditor",
>       prompt="primary={대상 프로젝트} related={연동 후보 JSON} taskNumber={N}")
> ```

3 sub-agent: `code-investigator` · `db-meta-manager` · `security-auditor`.

> **금지 패턴 (anti-pattern)**: `Skill(skill='explore-*', args='...')` 또는 `Agent(subagent_type='explore-*', ...)` — 둘 다 deprecated. 반드시 신규 직업명(`code-investigator`/`db-meta-manager`/`security-auditor`) subagent_type 사용.
> **금지 패턴 (anti-pattern)**: `"Read .claude/agents/{job}.md and execute"` — agent dispatch 가 아니라 파일 Read. 격리 격실 깨짐.
> **금지 패턴 (anti-pattern)**: "탐색 시작해도 될까요?" 사용자 컨펌 질문. 자율 선탐색은 자동 트리거 — 컨디션 만족 시 즉시 dispatch.

### 통합 단계 (메인 스레드)

3 응답 수신 후:
1. **교차 점검** — 토픽 격리로 놓친 신호 1회 보강 (코드↔보안↔DB 매칭 확인).
2. **자주 놓치는 토픽 교차** — `references/missing-topic-reminders.md` Read 후 8항목 대조. 3 결과 어디에도 없으면 갭 등록.
3. **메인 inline Grep 백업** — 좁은 범위 누락 보강 시에만.
4. gap list 확정 → 1:1 라운드 진입.

### 재사용 (선택적 패턴 — 권고)

이 4 위임 컴포넌트 (`parse-spec-doc` sub-skill + 3 sub-agent `code-investigator`/`db-meta-manager`/`security-auditor`) 는 dev-interview 전용 아니다. `dev-plan` · `code-review` · `develop` 에서 동일 패턴으로 호출 가능:
- `parse-spec-doc` → `Skill(skill='parse-spec-doc', args='...')`
- 3 sub-agent → `Agent(subagent_type='{job}', prompt='primary=... topicHints=... taskNumber=...')`

> **선택적 패턴**: 본 항목은 권고 — 다른 스킬 본문에 강제 인터페이스 없음. 각 호출 스킬이 필요 시점에만 dispatch 한다. 본 스킬의 자율 선탐색 자동 트리거 규칙(컨디션·재호출 금지 등)은 dev-interview 내부 정책이므로 다른 스킬에서 재사용 시 해당 스킬의 정책으로 재정의한다.

---

## 1:1 질문 라운드

자율 선탐색 결과 + 사용자 입력에서 갭 식별. **갭마다 한 번에 1질문**. STRONG/MEDIUM 갭은 `AskUserQuestion` 클릭형(추천=`options[0]`), WEAK 갭은 텍스트 열린 질문 — "그 외" 여지는 도구 Other 선택지가 보장.

- 라운드 전달 방식·도구 호출 규격 → `references/round-header-formats.md`
- 갭 우선순위·카테고리·라운드 메타·종료 조건 → **`references/gap-categories.md`**

---

## Stage 1 — 형식 게이트 (결정론 + self-check)

모든 갭 해소 후 11섹션 브리프를 **임시 파일로 작성** (예: `{{config.tempDir}}/brief_draft_{N}.md`, 사용자 미노출).

**Layer 3 script 선행 검증**:

```powershell
powershell .claude/skills/dev-interview/scripts/validate-brief.ps1 `
     -BriefFile {{config.tempDir}}/brief_draft_{N}.md
```

`scripts/validate-brief.ps1` 가 9개 체크(섹션 헤더·메타 표·시스템 결정·하위 절·미결사항·Phase·TBD 금지·메타 footer·Q&A 부록)를 결정론 검증하여 `{pass, failed, checks: [...]}` JSON 을 반환한다.

- `pass: false` → `checks[]` 의 실패 항목 보정 후 재실행 (자율 선탐색 추가 또는 1-by-1 추가 질문). 모두 통과(`pass: true`) 전까지 Stage 2 진입 금지.
- `pass: true` → `references/brief-schema.md` 의 self-check 잔여 항목(근거 1줄 충족·정성 일관성)을 본인이 추가 검토 후 Stage 2 진입.

> 결정론 검증으로 LLM 추론 부담 감소 + 동일 입력 → 동일 PASS/FAIL 보장.

---

## Stage 2 — 정성 검토 (reviewerAgent)

`.claude/config/system.yaml` `reviewerAgent` 값에 따라 분기:

- `codex:rescue` / `claude-sonnet` / 기타 agent → Agent tool, `subagent_type` 에 해당 `reviewerAgent` 값 위임.
- `none` → Stage 2 skip → Stage 1 통과 시 6.6 사용자 제시로 바로 진행.

출력 계약·점검 관점·등급 기준 → **`references/codex-output-contract.md`**.

---

## 재인터뷰 1-by-1 루프 (Stage 2 RED 시)

```
헤더 알림: "검토 결과 RED. 재인터뷰 {n}/3 라운드. 보정 갭 {k}개"
    ↓
재인터뷰_갭 리스트 추출
    ↓
갭 1번 → 한 번에 1질문 (STRONG/MEDIUM=AskUserQuestion, WEAK=텍스트, 라운드 메타 누적)
    ↓
사용자 응답 → 해당 §섹션 갱신 → 다음 갭 (모든 갭 해소까지)
    ↓
브리프 갱신 → Stage 1 → Stage 2 재실행
    ↓
GREEN/YELLOW → 6.6 진행
RED + 라운드 < 3 → 다음 라운드
RED + 라운드 = 3 → escalate
```

재인터뷰 라운드도 Q&A 로그 메타에 누적. "반영" 컬럼에 `§X (재인터뷰 R{n})` 표기.

### Escalate (3라운드 후 RED)

남은 RED 코멘트를 텍스트로 노출한 뒤 `AskUserQuestion` 1질문:

```jsonc
{
  "questions": [{
    "header": "진행 방식",
    "question": "3라운드 후에도 RED. 남은 항목: {RED 코멘트 요약}. 어떻게 진행할까요?",
    "multiSelect": false,
    "options": [
      { "label": "§9 기록 후 저장 (추천)", "description": "남은 RED 항목을 §9 미결사항으로 기록하고 저장" },
      { "label": "인터뷰 계속", "description": "4라운드+ 재인터뷰 진행" },
      { "label": "중단", "description": "저장하지 않고 종료" }
    ]
  }]
}
```

라운드 카운트는 내부 변수 (대화 휘발, 파일 저장 없음).

---

## 사용자 제시 + Q&A 로그 부록 (Stage 2 통과 후)

11섹션 본문 + Q&A 로그 부록을 사용자에게 텍스트로 제시:

```
## 인터뷰 결과 — {과업번호} {주제}

[11섹션 브리프 본문 — references/brief-schema.md 스키마]

## 인터뷰 Q&A 로그 (부록)

[라운드 메타 표 — templates/qna-log-appendix.md 형식]

---

**검토 등급**: GREEN | YELLOW
{YELLOW 시: MED/LOW 코멘트 요약 (관점별 1줄)}
```

> 11섹션 본문 + Q&A 부록 + 검토 등급은 **텍스트로 먼저 전부 제시** (긴 내용은 도구 옵션에 담지 않음). 제시 직후 저장 확인만 `AskUserQuestion` 1질문:

```jsonc
{
  "questions": [{
    "header": "저장",
    "question": "이 내용으로 {{config.outputDir}}/{taskId}_dev_brief.md 에 저장할까요?",
    "multiSelect": false,
    "options": [
      { "label": "저장 (추천)", "description": "본문 + 부록 그대로 저장 후 다음 단계 안내" },
      { "label": "수정 요청", "description": "수정 사항 입력 → 반영 후 재제시" }
    ]
  }]
}
```

**시스템 승인 게이트 없음** — Plan Mode 미사용. 확인 1회로 마감하여 `{{config.planSkill}}` 즉시 연계.

사용자 응답:
- "저장" → `Write {{config.outputDir}}/{taskId}_dev_brief.md` (본문 + 부록 모두 포함)
- "수정 요청" 또는 Other(자유 입력) → 해당 섹션 갱신 후 재제시

---

## 완료 후 안내

전체 안내 텍스트는 **`references/completion-hooks.md` 단일 출처**. 4 hook 순차 실행:

1. 브리프 생성 완료 안내 — `{{config.outputDir}}/{taskId}_dev_brief.md` 경로 + 부록 라운드 수.
2. 다음 단계 — `{{config.planSkill}}` 값에 따라 분기.
3. 임시 파일 정리 — `{{config.tempDir}}/pre_exp_{taskId}/` 유지/삭제 확인.
4. `.gitignore` 에 `{{config.tempDir}}/` 포함 여부 확인 권장.

---

## 원칙 요약

1. 모든 질문 1:1 — 한 번에 1질문. 선택지 있으면 `AskUserQuestion` 클릭형, 근거 빈약하면 텍스트 열린 질문.
2. 자율 판단 — 깊이·질문 방식 LLM 결정. 8-Phase 스크립트 없음.
3. 사용자 입력 그대로 — `$ARGUMENTS` 임의 주입 금지.
4. 근거 명시 — 가설 기반 질문에 근거 1줄. 근거 없으면 열린 질문.
5. 다중 키워드 탐색 — sub-agent `code-investigator` 의 3관점 사전 위임.
6. 기존 구현 우선 — "별첨 스펙 필요" 단정 전 `code-investigator` 호출.
7. DB 메타가 강력 — sub-agent `db-meta-manager` 위임 (실데이터 금지).
8. 빈 섹션 "해당 없음" — 11섹션 채움 강박 금지.
9. 확증 편향 방지 — 사용자가 "그 외" 답할 여지 보장 (`AskUserQuestion` 의 자동 Other 선택지가 네이티브 보장). 가설 없으면 억지 객관식 금지 — 텍스트 열린 질문.
10. 매끄러운 후속 연계 — 인터뷰 종료 → Stage 1·2 통과 → 텍스트 확인 1회 → Write → `{{config.planSkill}}`.
11. 2단계 검토 게이트 — Stage 1 self-check + Stage 2 reviewerAgent. RED 시 1-by-1 재인터뷰 (최대 3라운드).
12. 2단 분리 오케스트레이션 — 메인은 dispatch + 통합, sub-agent (code-investigator·db-meta-manager·security-auditor) / sub-skill (`parse-spec-doc`) 가 playbook + references/templates/scripts Read 직접 수행.
13. Composable — 토픽 탐색은 sub-agent, 문서 파싱·출력 스키마는 sub-skill / references 위임.
14. Q&A 로그 부록 자동 첨부 — 라운드 메타 누적 → 부록 표. **사용자 원문 인용 금지** (결정 사실만 1줄).
15. Layer 3 자산 별도 파일 — SQL·키워드·스키마·라운드 헤더·예시 인라인 금지. references/templates/scripts 만.

---

## 사용 예시 · 버전 히스토리

- 사용 예시 3종 → `references/usage-examples.md`
- 버전 히스토리 → `README.md` §9
