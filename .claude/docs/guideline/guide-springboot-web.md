# Spring Boot Web 개발 가이드

복지AX-BE Spring Boot 4.1.0 기반 REST API 개발 가이드이다.

## 패키지 구조 (멀티모듈)

코드는 역할에 따라 모듈을 나눠 작성한다.

**welfare-ax-domain** — Entity, Repository
```
com.beplepay.welfareaxbe.domain.{도메인}/
├── entity/       @Entity, @Table
└── repository/   JpaRepository<Entity, ID>
```

**welfare-ax-user** — Controller, Service, DTO
```
com.beplepay.welfareaxbe.user.{도메인}/
├── controller/   @RestController, @RequestMapping
├── service/      인터페이스 + Impl
└── dto/          Request/Response (Lombok @Builder)
```

**welfare-ax-common** — 공통 인프라
```
com.beplepay.welfareaxbe.common/
├── exception/    공통 예외, @RestControllerAdvice
└── response/     ApiResponse<T> 래퍼
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

## Spring Security 6.x 설정
```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/v1/auth/**").permitAll()
            .anyRequest().authenticated())
        .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
        .build();
}
```
