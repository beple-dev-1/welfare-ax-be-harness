# Spring Boot Web 개발 가이드

복지AX-BE Spring Boot 4.1.0 기반 REST API 개발 가이드이다.

## 패키지 구조 (멀티모듈)

코드는 역할에 따라 모듈을 나눠 작성한다.

**we-adk-welfare-domain** — Entity, Repository
```
com.beplepay.weadk.welfare.domain.{도메인}/
├── entity/       @Entity, @Table
└── repository/   JpaRepository<Entity, ID>
```

**we-adk-welfare-user** — Controller, Service, DTO
```
com.beplepay.weadk.welfare.user.{도메인}/
├── controller/   @RestController, @RequestMapping
├── service/      인터페이스 + Impl
└── dto/          Request/Response (Lombok @Builder)
```

**we-adk-welfare-common** — 공통 인프라 (새 공통 기능은 반드시 여기에 작성)
```
com.beplepay.weadk.welfare.common/
├── exception/    ErrorCode, WelfareException, GlobalExceptionHandler(@RestControllerAdvice)
├── filter/       TraceIdFilter — 모든 요청에 UUID traceId 부여, MDC 저장, X-Trace-Id 헤더 반환
├── http/         CommonHttpClient(RestClient 래퍼), HttpLoggingInterceptor(요청·응답 자동 로깅)
├── response/     ApiResponse<T> 래퍼 (code/message/data)
└── util/         MdcConstants — MDC 키 상수 (TRACE_ID_KEY = "traceId")
```

**경조사 전용**: `user/ceremony/`, `domain/ceremony/` 하위
**복지 공통 도메인**: `domain/member/`, `domain/merchant/`

## Controller 작성 기준
- `@RestController` + `@RequestMapping("/api/v1/{도메인}")`
- 메서드 레벨 매핑: `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, `@PatchMapping`
- 입력 검증: `@Valid` + `@RequestBody`
- 응답: `ResponseEntity<ApiResponse<T>>` 형식 (공통 래퍼)

```java
@PostMapping("/apply")
public ResponseEntity<ApiResponse<CeremonyApplyResponse>> apply(
    @Valid @RequestBody CeremonyApplyRequest request) {
    return ResponseEntity.ok(ApiResponse.success(ceremonyService.apply(request)));
}
```

## Service 작성 기준
- 인터페이스 + Impl 분리
- `@Transactional(readOnly = true)` 기본, 쓰기 메서드에 `@Transactional`
- 도메인 비즈니스 로직은 Service에서 처리
- 외부 API 호출은 트랜잭션 밖에서 수행

## Repository 작성 기준
- `JpaRepository<Entity, Long>` 확장
- 복잡한 조회: `@Query` JPQL 또는 QueryDSL
- 페이징: `Pageable` 파라미터 사용
- N+1 방지: `@EntityGraph` 또는 fetch join 명시

## DTO 작성 기준
- 요청 DTO: `{기능}Request` (예: `CeremonyApplyRequest`)
- 응답 DTO: `{기능}Response` (예: `CeremonyApplyResponse`)
- Lombok: `@Getter`, `@Builder`, `@AllArgsConstructor`, `@NoArgsConstructor`
- 검증 어노테이션: `@NotNull`, `@NotBlank`, `@Size`, `@Min`, `@Max`

## 예외 처리
- 도메인 예외: `{원인}Exception extends RuntimeException`
- 전역 처리: `@RestControllerAdvice` + `@ExceptionHandler`
- HTTP 상태코드: 400 (검증 실패), 404 (리소스 없음), 409 (중복), 422 (비즈니스 규칙 위반), 500 (서버 오류)

## 외부 HTTP 호출 기준

`CommonHttpClient`를 반드시 경유한다. `RestTemplate`, `RestClient` 직접 사용 금지.

```java
// CommonHttpClient 주입 후 호출
Map<String, String> headers = Map.of("Authorization", "Bearer " + token);
String result = httpClient.get(url, headers, String.class);
```

- 트랜잭션 내 외부 호출 금지 (DB 커넥션풀 고갈 위험)
- 외부 호출 실패 시 `WelfareException(ErrorCode.EXTERNAL_API_ERROR)` 로 래핑됨
- 요청·응답 로깅은 `HttpLoggingInterceptor`가 자동 처리 (별도 로그 코드 작성 불필요)
- MDC traceId는 외부 요청 헤더 `X-Trace-Id`로 자동 전파

## 분산 추적 (traceId)

모든 인바운드 요청에 `TraceIdFilter`가 UUID traceId를 자동 부여한다.

- **MDC 키**: `MdcConstants.TRACE_ID_KEY` (`"traceId"`) — 리터럴 문자열 직접 사용 금지
- **로그**: logback 패턴 `%X{traceId:-NO_TRACE}`로 자동 포함
- **응답 헤더**: `X-Trace-Id`로 반환
- **외부 API 전파**: `HttpLoggingInterceptor`가 `X-Trace-Id` 헤더로 자동 전파

```java
// 올바른 사용
MDC.get(MdcConstants.TRACE_ID_KEY);

// 금지 — 리터럴 하드코딩
MDC.get("traceId");
```

## Spring Security 6.x 설정

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/v1/auth/**").permitAll()
            .requestMatchers("/actuator/health").permitAll()
            // Swagger UI — 운영 환경은 springdoc.swagger-ui.enabled=false로 이중 차단
            .requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**").permitAll()
            .anyRequest().authenticated())
        .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
        .build();
}
```

## Swagger UI 환경별 제어

운영 환경 Swagger 노출을 방지하기 위해 **기본값 비활성화 + 환경별 활성화** 이중 구조를 사용한다.

`application.yaml` (기본 — 운영 포함 모든 환경):
```yaml
springdoc:
  swagger-ui:
    enabled: false
  api-docs:
    enabled: false
```

`application-local.yaml` / `application-dev.yaml` (로컬·개발만 활성화):
```yaml
springdoc:
  swagger-ui:
    enabled: true
    path: /swagger-ui.html
    try-it-out-enabled: true
  api-docs:
    enabled: true
    path: /v3/api-docs
```

- SecurityConfig의 `permitAll()` 추가만으로는 부족 — `enabled: false` 설정이 반드시 병행되어야 함
- 새 실행 모듈(admin 등) 추가 시 동일 패턴 적용 필수
