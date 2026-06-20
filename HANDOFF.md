# HANDOFF

> 이 파일은 세션 종료 시 `/pack` 명령으로 자동 갱신됩니다.
> 진행 중인 작업의 상태를 다음 세션에서 이어받을 수 있도록 기록합니다.

## 진행 중인 작업
없음 — 멀티모듈 구조 전환 및 하네스 정합성 점검 완료

## 최근 작업 요약

### 멀티모듈 구조 전환
- 단일 모듈 → 5개 멀티모듈 구조로 전환
  - `welfare-ax-common` — 공통 인프라 라이브러리
  - `welfare-ax-domain` — 공통 도메인 라이브러리 (Entity, Repository)
  - `welfare-ax-user` — 사용자 API 실행 모듈 (port: 8080)
  - `welfare-ax-admin` — 관리자 API skeleton (port: 8081)
  - `welfare-ax-batch` — 배치 실행 모듈 skeleton (port: 8082, ax-be에서 배치 없음)
- 각 실행 모듈 `@SpringBootApplication(scanBasePackages = "com.beplepay.welfareaxbe")` 적용
- `@EnableJpaRepositories("com.beplepay.welfareaxbe")` — welfare-ax-user에만 적용

### 환경 설정
- 로컬 DB 접속정보 적용: `jdbc:postgresql://localhost:5432/welfare` (welfare/welfare1234)
- MCP postgres 연결 설정 완료 (`.mcp.json`)
- 환경 프로파일: local → dev → prod (stg 없음)
- Spring Batch 의존성 전면 제거 (ax-be에서 배치 없음, 별도 모듈 예정)

### 하네스 정합성 점검 (완료)
- `settings.json` — `application-dev*` 차단 제거 (security-policy.md와 일치)
- `check-file-access.sh` — `application-staging` 제거, prod만 차단
- `testing.md` — "정산 배치" DoD 항목 제거
- `qa-tester.md` — 테스트 명령 멀티모듈 형식으로 수정
- `convention.md`, `dev-guide.md`, `dev-backend.md` — 멀티모듈 패키지 구조 반영
- `scope.yaml` — 6개 스코프 모두 모듈별 경로로 업데이트
- `system.yaml` — stg → prod 환경 변경

## 다음 단계
1. `/dev-interview`로 첫 번째 기능 개발 시작 (경조사 신청 API)
2. 첫 Entity 추가 시 `welfare-ax-domain` 엔티티가 `welfare-ax-user`에서 자동 스캔되는지 확인 필요

## 미결 사항
- GitLab 연동 정보 미설정 (`system.yaml`의 gitlab.baseUrl, projectMappings)
- 첫 Entity 추가 전 `@EntityScan` 대안 확인 (Spring Boot 4.x에서 패키지 이동됨)
