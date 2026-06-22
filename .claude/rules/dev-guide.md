# 개발 가이드

## 아키텍처 원칙: 공통 vs 경조사 전용 분리

복지AX-BE는 현재 **경조사지원**을 첫 번째 업무로 개발하며, 향후 다른 성격의 복지 업무가 추가된다.
소스 코드는 다음 멀티모듈 원칙으로 분리한다:

| 모듈 | 패키지 루트 | 설명 |
|------|-----------|------|
| `we-adk-welfare-common` | `com.beplepay.weadk.welfare.common` | 모든 모듈에서 사용하는 공통 인프라 (라이브러리) |
| `we-adk-welfare-domain` | `com.beplepay.weadk.welfare.domain` | Entity·Repository — 모든 실행 모듈이 의존 (라이브러리) |
| `we-adk-welfare-user` | `com.beplepay.weadk.welfare.user` | 사용자 API — 경조사 신청·승인·지급 (실행 모듈) |
| `we-adk-welfare-admin` | `com.beplepay.weadk.welfare.admin` | 관리자 API (실행 모듈, skeleton) |
| `we-adk-welfare-batch` | `com.beplepay.weadk.welfare.batch` | 배치 처리 (실행 모듈, skeleton, 별도 개발) |

새로운 복지 업무 추가 시: 새 실행 모듈(예: `welfare-ax-housing`)을 추가하고 `we-adk-welfare-common`, `we-adk-welfare-domain`의 공통 기능을 활용한다.

## 새 구현 전 확인 사항

1. `we-adk-welfare-common` 모듈에 공통 기능이 이미 있는지 확인한다.
2. 신규 코드가 domain(entity/repo), user(controller/service/dto), common(공통 인프라) 중 어디에 속하는지 먼저 판단한다.
3. 프로젝트 유형에 맞는 가이드 문서를 먼저 읽는다.
4. 기존 유사 구현이 있으면 패턴을 맞춘다 — code-investigator 에이전트 활용.

## Spring Boot 4.1.0 주의사항

- Spring Boot 4.x는 Jakarta EE 10 기반: `javax.*` → `jakarta.*`
- Spring Security 6.x 이상 사용 중: 보안 설정은 `SecurityFilterChain` Bean 방식
- Spring Data JPA 3.x: Hibernate 6 기반, native query 작성 시 방언(dialect) 확인

## API 구현 기준

- 모든 API 응답은 공통 응답 래퍼(예: `ApiResponse<T>`)를 사용한다.
- 예외 처리는 `@RestControllerAdvice`를 통해 일관되게 처리한다.
- 입력값 검증은 `@Valid` + Bean Validation을 사용하고, 서버 검증을 반드시 수행한다.
- 경조사 지급·취소·정산 API는 반드시 멱등성 키 또는 중복 처리 방지 로직을 포함한다.

## JPA 사용 기준

- 복잡한 조회는 `@Query` JPQL 또는 QueryDSL 사용
- 대용량 데이터 처리: `@Query` + `Pageable` 또는 Scroll API 사용
- N+1 문제: `@EntityGraph` 또는 `fetch join` 명시적 사용
- 트랜잭션 범위: `@Transactional`은 Service 레이어에서 관리
- 트랜잭션 내 외부 REST 호출 금지 (DB 커넥션풀 고갈 위험)

## 보안 구현 기준

- 인증은 JWT 기반 구현 (Spring Security 6.x 필터 체인)
- 권한 검사는 메서드 레벨 `@PreAuthorize` 또는 컨트롤러 레벨 `.requestMatchers()` 사용
- 민감 정보(주민번호, 계좌번호 등)는 암호화하여 저장
