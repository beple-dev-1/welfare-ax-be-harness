# 보안 정책 (공통)

모든 에이전트가 준수해야 하는 보안 규칙이다.

## 절대 금지 항목

### 운영 설정 접근
- `application-prod*`, `application-production*` 파일 읽기·수정 금지
- `.env`, `.env.*` 파일 읽기·수정 금지

### 보안 자산 접근
- `*.pem`, `*.p12`, `*.jks`, `*.keystore` 파일 접근 금지
- `id_rsa`, `id_rsa.pub` 접근 금지
- `credentials.json` 접근 금지

### 암호화 값 처리
- 암호화된 값을 코드 내에서 복호화 시도 금지
- JWT 시크릿, 암호화 키를 코드·주석에 하드코딩 금지

### 실제 데이터 처리
- 회원 개인정보(이름, 연락처, 주민번호, 계좌번호)를 코드나 테스트에 삽입 금지
- 실제 업무 데이터(거래 내역, 혜택 지급 이력)를 DB에서 직접 조회 금지

### DB 변경
- INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE 쿼리 실행 금지
- DB 스키마 변경은 JPA Entity + Flyway 마이그레이션 스크립트로만 수행

## 허용 예외
- `application.yaml`, `application-local.yaml`, `application-dev.yaml` — 개발 설정 파일
- `.claude/` 내 하네스 설정 파일
- DB 메타 조회 (information_schema, pg_catalog): 테이블·컬럼·인덱스 구조만
