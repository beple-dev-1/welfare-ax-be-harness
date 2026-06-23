# /dev-ready 스킬

개발 시작 전 PostgreSQL DB 연결과 스코프 테이블 존재 여부를 점검한다.

## 사용법
```
/dev-ready [{스코프}]
```

예시: `/dev-ready ceremony`, `/dev-ready member`, `/dev-ready` (전체 점검)

스코프 목록: `ceremony`, `member`, `merchant`, `common`

## 절차

### 1단계: PostgreSQL MCP 연결 확인
db-meta-manager 에이전트를 호출하여 다음 테스트 쿼리를 실행한다.

```sql
SELECT current_database() AS db, current_schema() AS schema, now()::date AS today;
```

- **성공**: DB 이름·스키마·날짜 반환 → 2단계로 진행
- **실패**: 즉시 중단 후 다음을 안내한다
  - `.mcp.json`의 postgres 연결 문자열 확인
  - PostgreSQL 서버 실행 여부 확인
  - Claude Code 재시작 후 `/dev-ready` 재실행

### 2단계: 스코프 테이블 탐지
스코프가 지정된 경우, 해당 키워드로 public 스키마 테이블을 검색한다.

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name ILIKE '%{키워드}%'
ORDER BY table_name;
```

| 스코프 | 검색 키워드 |
|--------|------------|
| ceremony | `cer` |
| member | `mbr`, `member` |
| merchant | `mcht`, `merchant` |
| common | (전체 테이블 목록 출력) |

스코프 미지정 시: `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;`

### 3단계: 결과 출력

성공 예시:
```
## 개발 준비 점검 결과

| 항목 | 상태 |
|------|------|
| PostgreSQL MCP 연결 | ✅ 정상 (DB: welfare) |
| 스코프 테이블 탐지 (ceremony) | ✅ 3개 발견 |

### 발견된 테이블
- ceremony_application
- ceremony_approval
- ceremony_payment

### 판정
✅ 개발 시작 가능합니다. `/develop ceremony {과업번호}` 를 실행하세요.
```

실패 예시:
```
❌ DB 연결 실패 — PostgreSQL MCP를 확인 후 `/dev-ready` 를 재실행하세요.
```
```
⚠️ 스코프 'ceremony'에 해당하는 테이블이 없습니다.
   테이블이 생성되지 않았거나 키워드가 다를 수 있습니다. DB 담당자에게 확인하세요.
```
