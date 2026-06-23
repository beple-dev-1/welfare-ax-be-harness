# 리뷰 출력 템플릿

> code-review 스킬의 Step 5에서 참조하는 ko/en 출력 템플릿.

<Template_KO>

```
## 🔍 Claude 코드 리뷰

> **대상**: {staged|unstaged|all|HEAD~N|파일경로}
> **분석 파일**: {n}개 ({추가}/{수정}/{삭제})
> **브랜치**: {current_branch}
> **프로젝트**: {감지된 프로젝트 목록}
> **이슈**: 🔴 {n} / 🟡 {n} / 🔵 {n}

---

### 📋 요약
{전체 변경사항 2-3줄 요약}

---

### 🔎 상세 리뷰

#### `{파일경로}`
- 🔴 **[IC##]** Critical: {내용} — {유래 사례 ID} 회귀 위험 / 운영 경험
- 🟡 **[IW##]** Warning: {내용} — {유래 사례 ID} 운영 사례 / 운영 경험
- 🔴 **[C##]** Critical: {내용 + 개선 예시}
- 🟡 **[W##]** Warning: {내용}
- 🔵 **[S##]** Suggestion: {내용}

> **패턴 ID 표기 우선순위**:
> 1. 운영 안티패턴 매칭 시 — IC/IW ID + 유래 사례 ID (예: `[IC01] ... — I6 회귀 위험`, `[IW05] ... — I6 운영 사례`, `[IC07] ... — 운영 경험`)
> 2. severity_rules 매칭 시 — 해당 ID (예: [C01], [W07a], [S01])
> 3. 휴리스틱 판정 시 — [H]

---

### 🗄️ 쿼리 변경 검증
{SQL 변경 없으면 이 섹션 생략}

#### `{쿼리ID}` — {파일명}

**AS-IS**
\```sql
{원문 SQL}
\```

**문제점**
- {문제점 1 — 원인 + 영향 한 줄 요약}
- {문제점 2}

**TO-BE** ← 문제점이 있는 경우에만 출력
\```sql
{개선된 SQL}
\```

**해결방안**
- {방안 1 — 적용 시 기대 효과}
- {방안 2}

> 문제점이 없으면: ✅ 최적화 포인트 없음

---

### ✅ 잘된 점
{긍정적인 부분}

---

### 📝 팀 체크리스트 ({{config.customDocs.devGuide}} + settings.custom_checklist)
- ⚠️ {위반 항목} — {위반 내용}

> 위반 항목이 없으면: ✅ 모든 항목 충족

---

### 🚨 운영 안티패턴 매칭 ({{config.customDocs.antiPatterns}} — 빈 값 시 섹션 생략)

| ID | 카테고리 | 매칭 위치 | 유래 사례 |
|----|---------|---------|---------|
| {IC01} | Critical — 결제/지급 API 멱등성 | `{파일경로}` | I6 손목닥터 회귀 위험 |
| {IW05} | Warning — DB 슬로우쿼리 도구 미설정 | `{파일경로}` | I6 운영 사례 |

> 매칭이 없으면: ✅ 운영 안티패턴 매칭 없음
> 룰셋 출처: `{{config.customDocs.antiPatterns}}`

---

### 💬 종합 의견
{요약}
**평가**: ✅ 커밋 가능 / 🟡 수정 후 재검토 / 🔴 수정 필요

---
<sub>🤖 Reviewed by Claude · 대상: {target} · 언어: 한국어</sub>
```

</Template_KO>

<Template_EN>

```
## 🔍 Claude Code Review

> **Target**: {staged|unstaged|all|HEAD~N|file_path}
> **Files Analyzed**: {n} ({added}/{modified}/{deleted})
> **Branch**: {current_branch}
> **Projects**: {detected project list}
> **Issues**: 🔴 {n} / 🟡 {n} / 🔵 {n}

---

### 📋 Summary
{2-3 sentence summary}

---

### 🔎 Detailed Review

#### `{file_path}`
- 🔴 **[IC##]** Critical: {issue} — {origin case ID} regression risk / operational experience
- 🟡 **[IW##]** Warning: {issue} — {origin case ID} operational case / operational experience
- 🔴 **[C##]** Critical: {issue + fix example}
- 🟡 **[W##]** Warning: {issue}
- 🔵 **[S##]** Suggestion: {idea}

> **Pattern ID priority**:
> 1. Incident anti-pattern match — IC/IW ID + origin case ID (e.g., `[IC01] ... — I6 regression risk`, `[IW05] ... — I6 operational case`, `[IC07] ... — operational experience`)
> 2. severity_rules match — corresponding ID (e.g., [C01], [W07a], [S01])
> 3. Heuristic judgment — [H]

---

### 🗄️ Query Change Validation
{Omit this section if no SQL changes were made}

#### `{queryId}` — {filename}

**AS-IS**
\```sql
{original SQL}
\```

**Issues**
- {Issue 1 — cause + impact summary in one line}
- {Issue 2}

**TO-BE** ← Include only if issues exist
\```sql
{improved SQL}
\```

**Recommendations**
- {Recommendation 1 — expected effect when applied}
- {Recommendation 2}

> If no issues: ✅ No optimization points found

---

### ✅ What's done well
{positive highlights}

---

### 📝 Team Checklist ({{config.customDocs.devGuide}} + settings.custom_checklist)
- ⚠️ {violated item} — {details}

> If no violations: ✅ All checks passed

---

### 🚨 Incident Anti-Pattern Matches ({{config.customDocs.antiPatterns}} — omit section if empty)

| ID | Category | Match Location | Origin Case |
|----|----------|---------------|-------------|
| {IC01} | Critical — Payment/payout API idempotency | `{file_path}` | I6 (Sonmokdoctor) regression risk |
| {IW05} | Warning — DB slow query tooling missing | `{file_path}` | I6 operational case |

> If no matches: ✅ No incident anti-pattern matches
> Rule set source: `{{config.customDocs.antiPatterns}}`

---

### 💬 Overall Assessment
{summary}
**Verdict**: ✅ Ready to Commit / 🟡 Request Changes / 🔴 Changes Required

---
<sub>🤖 Reviewed by Claude · Target: {target} · Language: English</sub>
```

</Template_EN>
