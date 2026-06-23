# /dev-ready 스킬

개발 워크플로와 독립적으로 동작하는 **개발 환경 사전 점검** 스킬.
PostgreSQL MCP 연결, Git 브랜치 상태, 스코프 테이블 존재 여부를 확인하여 환경 이상 여부를 보고한다.

## 실행 시점

| 시점 | 예시 상황 |
|------|----------|
| 최초 세션 | 프로젝트 개발 환경을 처음 구성한 후 |
| 환경 변경 시 | DB 서버 재시작, MCP 설정 변경, 네트워크 환경 변경 후 |
| 문제 발생 시 | DB 연결 오류, 스키마 불일치, 쿼리 실패 등 이상 징후 감지 시 |

## 사용법

```
/dev-ready [{스코프}]
```

- 스코프 생략: DB 연결 + Git 브랜치 + 전체 테이블 목록 점검
- 스코프 지정: 위 항목에 추가로 해당 스코프의 테이블 존재 여부 점검

스코프 목록: `ceremony`, `member`, `merchant`, `common`, `admin`, `batch`

---

## 절차

### 1단계: PostgreSQL MCP 연결 확인

MCP postgres 도구로 직접 실행한다 (db-meta-manager 에이전트 경유 금지).

```sql
SELECT current_database() AS db, current_schema() AS schema, now()::date AS today;
```

- **성공**: DB 이름·스키마·날짜 반환 → 2단계로 진행
- **실패**: 즉시 중단 후 아래를 안내하고 종료

```
❌ DB 연결 실패 — 환경 확인 후 `/dev-ready` 를 재실행하세요.

점검 항목:
  1. .mcp.json postgres 연결 문자열
  2. PostgreSQL 서버 실행 여부
  3. Claude Code 재시작
```

---

### 2단계: Git 브랜치 상태 확인

```bash
git branch --show-current
git status --porcelain
```

| 브랜치 상태 | 판정 |
|------------|------|
| `feature/*` / `hotfix/*` | ✅ 정상 |
| `main`, `develop`, `release-*`, `internal-*` | ⚠️ 경고 — 보호 브랜치, 개발 작업 전 작업 브랜치 생성 필요 |
| detached HEAD | ⚠️ 경고 — 브랜치 상태 확인 필요 |

uncommitted changes가 있어도 중단하지 않는다 — 정보로만 출력한다.

---

### 3단계: 스코프 테이블 탐지

스코프를 지정한 경우에만 실행한다.

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name ILIKE '%{키워드1}%' OR table_name ILIKE '%{키워드2}%')
ORDER BY table_name;
```

| 스코프 | 탐지 키워드 | 비고 |
|--------|------------|------|
| `ceremony` | `cer` | 경조사 전용 테이블 |
| `member` | `mbr`, `member` | 회원 공통 도메인 |
| `merchant` | `mcht`, `merchant` | 가맹점 공통 도메인 |
| `common` | — | 인프라 스코프 — 테이블 탐지 해당 없음, 스킵 |
| `admin` | `admin` | skeleton — 테이블 0개여도 ⚠️ 경고 처리 후 계속 진행 |
| `batch` | `batch` | skeleton — 테이블 0개여도 ⚠️ 경고 처리 후 계속 진행 |

스코프 미지정 시 전체 테이블 목록 조회:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

---

### 4단계: 결과 출력

결과는 **환경 상태 보고** 형식으로 출력한다.
다음 워크플로 단계를 안내하지 않는다.

**정상 (스코프 지정):**
```
## 개발 환경 점검 결과

| 항목 | 상태 |
|------|------|
| PostgreSQL MCP 연결 | ✅ 정상 (DB: welfare, schema: public) |
| Git 브랜치 | ✅ feature/057/gkwns458 |
| 스코프 테이블 탐지 (ceremony) | ✅ 3개 발견 |

### 발견된 테이블 (ceremony)
- ceremony_application
- ceremony_approval
- ceremony_payment

### 판정
✅ 개발 환경 이상 없음.
```

**보호 브랜치 경고:**
```
⚠️ 현재 브랜치: main (보호 브랜치)
   개발 작업 전 작업 브랜치를 생성하세요. (/git 스킬 참고)
```

**스코프 테이블 미발견 (ceremony/member/merchant):**
```
⚠️ 스코프 'ceremony' 테이블이 없습니다.
   DDL 생성 여부를 DB 담당자에게 확인하세요.
```

**스코프 테이블 미발견 (admin/batch — skeleton):**
```
⚠️ 스코프 'admin' 테이블이 없습니다. (skeleton 단계 — 정상일 수 있음)
```

**common 스코프:**
```
ℹ️ 'common'은 인프라 스코프입니다 — DB 테이블 점검 해당 없음.
```
