# HANDOFF

> 이 파일은 세션 종료 시 `/pack` 명령으로 자동 갱신됩니다.
> 진행 중인 작업의 상태를 다음 세션에서 이어받을 수 있도록 기록합니다.

## 진행 중인 작업
없음 — COMMON-00004 완료, PR #5 main 머지 완료 (머지 커밋: `8ed6350`)

## 최근 작업 요약

### COMMON-00004: traceId 상수화 및 Swagger(OpenAPI 3.0) 연계 (커밋 완료)
브랜치: `feature/COMMON-00004/gkwns458`
커밋: `aa4088a`

**구현 내용**

- `welfare-ax-common`
  - `MdcConstants` 신규 추가 — `TRACE_ID_KEY = "traceId"` 단일 상수로 중앙화
    TraceIdFilter, HttpLoggingInterceptor에 분산된 리터럴을 모두 상수 참조로 변경
  - `TraceIdFilter` — 패키지 전용 `TRACE_ID_KEY` 제거, `MdcConstants.TRACE_ID_KEY` 참조
  - `HttpLoggingInterceptor` — `MDC.get("traceId")` → `MDC.get(MdcConstants.TRACE_ID_KEY)`
  - 관련 테스트(`TraceIdFilterTest`, `HttpLoggingInterceptorTest`, `MdcConstantsTest`) 갱신

- `welfare-ax-user`
  - `springdoc-openapi-starter-webmvc-ui:2.8.9` 의존성 추가 (`build.gradle.kts`)
  - `SwaggerConfig` 신규 추가 — JWT BearerAuth SecurityScheme 전역 등록, Authorize 버튼 사전 구성
  - `SecurityConfig` — `/swagger-ui/**`, `/v3/api-docs/**` permitAll 추가 (이중 차단 주석 포함)
  - `application.yaml` — `dev` 프로파일 그룹 추가, springdoc 기본 비활성화
  - `application-local.yaml`, `application-dev.yaml` — springdoc 활성화 설정 추가
  - `logback-spring.xml` — MdcConstants 키 동기화 주의사항 주석 추가
  - `SwaggerConfigTest` 신규 추가 — 순수 단위 테스트 (메타정보, BearerAuth, 전역 Security)

**코드 리뷰 지적사항 수정**
- CRITICAL: SwaggerConfig 개인 이메일 → `support@beple.co.kr` 교체
- WARNING: `HttpLoggingInterceptorTest` import 순서 정정 (org.springframework.* 뒤로 이동)
- INFO: `SwaggerConfig` import 순서 정정 (org.springframework.* → io.swagger.* 순서)

**테스트**: `welfare-ax-common` 전체 통과, `SwaggerConfigTest` 3건 통과
(TestApiClientIntegrationTest 4건 실패는 httpbin.org 503 기존 이슈 — COMMON-00004 무관)

## Git 커밋 현황
| 커밋 | 내용 |
|------|------|
| `aa4088a` | feat: traceId 상수화 및 Swagger 연계 (COMMON-00004) |
| `b9fa63b` | Merge PR #4 (COMMON-00003) → main |
| `69c487b` | feat: traceId 인프라 구현 (COMMON-00003) |
| `4149b15` | Merge PR #3 (COMMON-00002 추가 작업) → main |
| `701940e` | Merge PR #2 (COMMON-00002) → main |

## 다음 단계
1. **TestApiClientIntegrationTest 대응**: httpbin.org 대신 WireMock으로 목킹하거나 `build.gradle.kts`에서 `integration` 태그 기본 제외 처리 (별도 과업)
3. **로그인 API 과업 시작**: `Member` 도메인 Entity/Repository 구현 → 인증 API (`/dev-interview member`)
4. **경조사 신청 API 과업 시작**: `/dev-interview ceremony`
5. (선택) `admin`, `batch` 모듈에 `logback-spring.xml` 동일 설정 추가 — 현재 skeleton 상태

## 미결 사항
- `TestApiClientIntegrationTest`: httpbin.org 503 실패 (기존 이슈, COMMON-00002 때부터)
  → WireMock 도입 또는 `-Dgroups=!integration` 빌드 제외 처리 검토
- Member Entity/Repository `welfare-ax-domain` 미구현 (로그인 API 사전 조건)
- `TraceIdFilter` 비동기 환경(`@Async`, `DeferredResult`) MDC 미전파 — `MDCTaskDecorator` 향후 검토
- `gh` CLI PATH 미등록 — `setx PATH "%PATH%;C:\Program Files\GitHub CLI"` 실행 필요

## 보안 자가점검
- [x] 운영 설정 파일 변경 없음
- [x] 시크릿 정보 코드 포함 없음
- [x] 개인정보 로그 노출 없음 (리뷰에서 이메일 하드코딩 적발·수정 완료)
