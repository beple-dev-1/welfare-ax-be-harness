# 복지AX 프로젝트 코드 리뷰 기준

## 복지혜택 도메인 규칙

### 지급 API
- 멱등성 키 또는 unique 제약으로 중복 지급 방지 필수
- 지급 전 잔액/한도 검증 로직 존재 확인
- 지급 결과는 이력 테이블에 기록

### 취소 API
- 원거래 조회 후 취소 처리
- 이미 취소된 거래의 재취소 방지
- 부분 취소 지원 여부 명시

### 정산 배치
- Job 단위 멱등성 (동일 날짜 재실행 시 중복 없음)
- 처리 상태 컬럼으로 재처리 대상 구분
- 실패 레코드 별도 관리

## Spring Boot 4.1.0 규칙

### Jakarta EE
- `javax.*` 대신 `jakarta.*` 사용 확인
- Spring Security 6.x: WebSecurityConfigurerAdapter 미사용 확인

### JPA/Hibernate
- Entity에 `@Data` 사용 금지
- 양방향 관계 `mappedBy` 명시
- `@Column(nullable = false)` 등 제약조건 명시

### Lombok
- Entity: `@NoArgsConstructor(access = AccessLevel.PROTECTED)` 사용
- `@RequiredArgsConstructor`는 Service/Controller DI에 활용

## 공통 모듈 사용 규칙
- 응답 래퍼: 프로젝트 공통 `ApiResponse<T>` 사용
- 예외: 커스텀 예외 클래스 + `@RestControllerAdvice`
- 공통 기능 중복 구현 금지

### MDC traceId 키
- `MDC.get/put/remove` 호출 시 문자열 리터럴(`"traceId"`) 직접 사용 금지
- 반드시 `MdcConstants.TRACE_ID_KEY` 상수 참조
- 위반 시 WARNING

### 외부 HTTP 호출
- `CommonHttpClient` 경유 필수. `RestClient`, `RestTemplate` 직접 사용 금지
- 트랜잭션 내 외부 호출 금지 (CRITICAL)

## Swagger UI 보안

### 운영 환경 노출 방지
- `application.yaml` (기본): `springdoc.swagger-ui.enabled: false` 확인 필수
- SecurityConfig `permitAll` 추가만으로는 부족 — `enabled: false` 기본값과 병행 필수
- 새 실행 모듈(admin 등)에 Swagger 설정 추가 시 동일 패턴 적용 확인
- 위반 시 CRITICAL (운영 Swagger 노출은 API 구조 및 JWT 인증 방식 노출로 이어짐)
