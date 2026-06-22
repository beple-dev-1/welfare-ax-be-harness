# 코드 컨벤션

## Java 코드 스타일

- 들여쓰기: 스페이스 4칸
- 최대 줄 길이: 120자
- 클래스·인터페이스: PascalCase
- 메서드·변수: camelCase
- 상수: UPPER_SNAKE_CASE
- 패키지: lowercase

## 네이밍 규칙

### 레이어별 클래스 접미사
- Controller: `*Controller` (예: `CeremonyController`)
- Service 인터페이스: `*Service` (예: `CeremonyApplicationService`)
- Service 구현체: `*ServiceImpl` (예: `CeremonyApplicationServiceImpl`)
- Repository: `*Repository` (예: `CeremonyRepository`)
- Entity: 도메인 명사 그대로 (예: `Ceremony`, `Member`, `Merchant`)
- DTO 요청: `*Request` 또는 `*Req` (예: `CeremonyApplyRequest`)
- DTO 응답: `*Response` 또는 `*Res` (예: `CeremonyApplyResponse`)
- 예외: `*Exception` (예: `CeremonyNotFoundException`)

### 패키지 구조 기준 (멀티모듈)

**we-adk-welfare-common** — 공통 인프라 라이브러리
```
com.beplepay.weadk.welfare.common
├── exception/    # 공통 예외, @RestControllerAdvice
├── response/     # ApiResponse 래퍼
└── util/         # 유틸리티
```

**we-adk-welfare-domain** — 공통 도메인 라이브러리
```
com.beplepay.weadk.welfare.domain
├── member/
│   ├── entity/       # @Entity
│   └── repository/   # JpaRepository
├── merchant/
│   ├── entity/
│   └── repository/
└── ceremony/
    ├── entity/
    └── repository/
```

**we-adk-welfare-user** — 사용자 API 실행 모듈
```
com.beplepay.weadk.welfare.user
├── config/           # Security, Web 설정
├── security/         # JWT 필터, 토큰 처리
└── ceremony/
    ├── application/  # 경조사 신청 (controller, service, dto)
    ├── approval/     # 승인 처리
    └── payment/      # 지급 처리
```

**모듈 분리 규칙:**
- Entity·Repository → `we-adk-welfare-domain` 모듈에만 위치
- Controller·Service·DTO → 각 실행 모듈(`we-adk-welfare-user` 등)에 위치
- 실행 모듈은 `we-adk-welfare-domain`을 Gradle 의존으로 참조 (직접 패키지 import 아님)
- 업무 간 공유가 필요한 코드는 반드시 `we-adk-welfare-common`으로 이동

## import 순서
1. java.*
2. javax.*, jakarta.*
3. org.*
4. com.*(외부 라이브러리)
5. com.beplepay.*(내부)

(각 그룹 사이 빈 줄)

## 주석

### 기본 원칙
- 모든 주석과 Javadoc은 한국어로 작성한다.

### Javadoc (클래스·메서드)
- **모든 클래스**에 클래스 역할을 설명하는 Javadoc을 작성한다.
- **모든 public·protected 메서드**에 Javadoc을 작성한다.
- private 메서드도 로직이 복잡하면 Javadoc을 작성한다.
- Javadoc 필수 태그:
  - `@param` — 각 파라미터의 의미와 허용 범위
  - `@return` — 반환값의 의미 (void 제외)
  - `@throws` — 발생 가능한 예외와 발생 조건

```java
/**
 * JWT 액세스 토큰을 생성한다.
 *
 * @param memberId 회원 식별자
 * @param role     권한 (예: USER, ADMIN)
 * @return 서명된 JWT 문자열
 */
public String generateToken(Long memberId, String role) { ... }
```

### 인라인 주석
- 메서드 내부의 **주요 처리 단계**마다 한 줄 주석으로 흐름을 설명한다.
- 조건 분기·예외 처리에는 해당 분기의 의미를 주석으로 명시한다.
- 비즈니스 규칙, 제약 조건, 주의사항은 WHY까지 함께 기록한다.

```java
// Bearer 접두사 제거 후 순수 토큰 추출
String token = header.substring(7);

// 만료·변조·형식 오류 모두 false로 통일 처리 (상세 원인은 로그로만 기록)
} catch (JwtException e) {
    return false;
}
```

## Lombok 사용 기준
- Entity: `@Getter`, `@NoArgsConstructor(access = PROTECTED)` 기본
- DTO: `@Getter`, `@Builder`, `@AllArgsConstructor`, `@NoArgsConstructor`
- `@Data`는 Entity에 사용 금지 (equals/hashCode 문제)
- `@RequiredArgsConstructor`는 Service/Controller DI에 사용

## JPA Entity 기준
- `@Entity` 클래스는 `public`이며 `protected` 기본 생성자 필수
- ID 생성 전략: `@GeneratedValue(strategy = GenerationType.IDENTITY)`
- 양방향 관계는 필요한 경우에만 사용, 무한 순환 주의
- `@Column(nullable = false)` 등 제약조건 명시
