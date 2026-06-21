# 기본 규칙

## 작업 범위

- 운영·통합 브랜치(main, develop, release-*, internal-*)는 직접 수정하지 않는다.
- 모든 작업은 `feature/{과업번호}/{사용자ID}` 형식의 작업 브랜치에서 수행한다.
- 커밋 전 반드시 `/code-review`로 변경 사항을 검토한다.

## 보안 기준

- 비밀번호, API 키, DB 접속 정보, JWT 시크릿, 암호화 키는 코드·문서·주석에 절대 포함하지 않는다.
- 운영/스테이징 환경 설정 파일(application-prod.yaml 등)은 읽기·수정하지 않는다.
- 개인정보(이름, 연락처, 주민번호 등)가 포함된 실제 데이터는 코드에 삽입하지 않는다.

## 산출물 위치

- 개발 브리프: `target/works/{과업번호}_dev_brief.md`
- 개발·테스트 계획서: `target/plans/{과업번호}/`
- 테스트 결과서: `target/test-reports/{과업번호}_test_result.md`
- 세션 인수인계: `HANDOFF.md`, `HANDOFF_HISTORY.md`

### target/ 관리 원칙
- `target/`은 git으로 추적한다 (소스 레포 `.gitignore` 제외 대상 아님).
- 각 개발자는 자신의 feature 브랜치에서만 `target/` 문서를 생성·수정한다.
- 타 개발자의 feature 브랜치 `target/` 문서를 수정하지 않는다.
- PR 머지 시 코드와 산출물(브리프·계획서·테스트 결과서)이 함께 main에 반영된다.

## AI 작업 책임

- AI가 제안하거나 수정한 코드도 담당자가 브랜치·커밋·MR에서 검토 책임을 진다.
- 스코프 외 파일 수정은 명시적 승인 없이 진행하지 않는다.
