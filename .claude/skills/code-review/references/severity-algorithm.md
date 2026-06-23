# 심각도 분류 알고리즘

> code-review 스킬의 Step 3에서 참조하는 4-step 심각도 분류 절차 (STEP 0~3).

<Algorithm>

아래 **4-step 심각도 분류 알고리즘**을 반드시 순서대로 적용한다:

## STEP 0: incident-antipatterns IC/IW 매칭 (최우선, customDocs 의존)

`{{config.customDocs.antiPatterns}}` 가 빈 값이면 STEP 0 **skip → STEP 1 로 진행**. 값이 있으면 해당 파일의 IC/IW 패턴(*탐지 키워드*·*안티패턴 코드 예시*)과 발견된 이슈를 대조한다.

- **IC 매칭** → **Critical 확정** (STEP 1·2 건너뜀, **STEP 3 교차 검증도 면제** — 이미 운영 사례로 검증된 안티패턴). 패턴 ID = `[ICnn]` + 유래 사례 ID 표기 (예: `[IC01] ... — I6 회귀 위험`, `[IC07] ... — 운영 경험`).
- **IW 매칭** → **Warning 확정** (STEP 1·2 건너뜀). 패턴 ID = `[IWnn]` + 유래 사례 ID 표기.
- **여러 IC/IW 동시 매칭** → 모두 표기하되, 가장 높은 심각도(IC)를 1차 표기로 채택.
- **매칭 없음** → STEP 1로 진행.

## STEP 1: severity_rules 패턴 매칭 (severity-rules.md 단일 출처)

[`severity-rules.md`](severity-rules.md) 의 Critical/Warning/Suggestion 패턴 `keywords` 와 발견된 이슈를 대조한다.

- **매칭 있음** → 해당 severity의 패턴 ID를 부여하고 심각도 확정. **STEP 2를 건너뛴다.**
- **여러 severity에 동시 매칭** → **높은 심각도를 채택**한다 (Warning보다 Critical 우선).
- **매칭 없음** → STEP 2로 진행.
- **변수 치환**: `severity-rules.md` 의 `{{config.commonUtilsArtifact}}` 등은 `project.yaml` 값으로 치환한 뒤 매칭한다.

## STEP 2: 휴리스틱 판정 (패턴 매칭 없을 때만)

패턴 ID 대신 `[H]`를 부여하고, 아래 기준으로 판정한다:

| 심각도        | 기준                                                 |
| ------------- | ---------------------------------------------------- |
| 🔴 Critical   | 운영 환경에서 **즉시** 장애 발생 또는 보안 사고 직결 |
| 🟡 Warning    | 특정 조건에서 문제 가능 (성능, 유지보수, 잠재 버그)  |
| 🔵 Suggestion | 기능 무관한 품질/가독성 개선                         |

## STEP 3: Critical 교차 검증 (필수 — STEP 0 IC 매칭은 면제)

STEP 1 또는 STEP 2에서 Critical로 판정된 모든 이슈에 대해 아래 질문을 검증한다:

1. "이 이슈가 운영에서 **즉시** 장애 또는 보안 사고를 유발하는가?"
2. "severity_rules의 **warning 또는 suggestion** 패턴에 더 적합하지 않은가?"

→ 하나라도 **"아니오"** → Warning 또는 Suggestion으로 **하향 조정**한다.

> **STEP 0 IC 매칭은 본 교차 검증에서 면제**된다. IC는 이미 운영 장애 사례로 검증된 안티패턴이므로 *즉시 장애 직결성*이 룰 정의 자체에 보장되어 있다. 하향 조정 금지.

</Algorithm>

<Absolute_Rules>

> **`import *`, 네이밍 위반, 브레이스 스타일, JavaDoc 미작성 등 코딩 컨벤션/문서화 이슈는 어떤 경우에도 Critical이 아니다.**
> 이러한 이슈는 severity_rules에서 Warning[W07a~f] 또는 Suggestion[S01]으로 명시되어 있으며, 반드시 해당 심각도를 따른다.

</Absolute_Rules>

<Calibration_Examples>

자주 발생하는 **오분류 사례**와 올바른 판정. 심각도 판정 시 반드시 참조한다.

| 발견 이슈                                          | ❌ 잘못된 판정 | ✅ 올바른 판정          | 이유                                               |
| -------------------------------------------------- | -------------- | ----------------------- | -------------------------------------------------- |
| `import java.util.*` (스타 임포트)                 | 🔴 Critical    | 🟡 **[W07a]** Warning   | 컨벤션 위반, 런타임 장애 무관                      |
| 네이밍 규칙 위반 (lowerCamelCase 등)               | 🔴 Critical    | 🟡 **[W07b]** Warning   | 컨벤션 위반, 런타임 장애 무관                      |
| K&R 브레이스 스타일 미준수                         | 🔴 Critical    | 🟡 **[W07c]** Warning   | 컨벤션 위반, 런타임 장애 무관                      |
| JavaDoc 미작성                                     | 🟡 Warning     | 🔵 **[S01]** Suggestion | 기능 무관한 문서화 이슈                            |
| `catch (Exception e) {}` (빈 catch)                | 🔵 Suggestion  | 🟡 **[W05]** Warning    | 예외 삼킴으로 장애 추적 불가                       |
| `console.log()` 잔재                               | 🟡 Warning     | 🔵 **[S05]** Suggestion | 기능 무관한 디버그 코드                            |
| `new Thread()` 내부에서 MDC 미전파                 | 🔴 Critical    | 🟡 **[W11]** Warning    | 추적 누락이나 즉시 장애는 아님                     |
| Factory에서 `return null`                          | 🔴 Critical    | 🟡 **[W12]** Warning    | NPE 가능성이나 호출부 null 체크에 따라 다름        |
| `StringUtils` 직접 구현 (`{{config.commonUtilsArtifact}}` 에 존재) | 🔵 Suggestion  | 🟡 **[W13]** Warning    | 공통 라이브러리 중복 구현, 유지보수 비용 증가      |
| `@Transactional` on private method                 | 🟡 Warning     | 🔴 **[C10]** Critical   | Spring 프록시 무시 → 트랜잭션 미적용 → 데이터 손실 (연계 IC07) |
| `Optional.get()` without isPresent                 | 🟡 Warning     | 🔴 **[C11]** Critical   | NPE 직결                                           |
| `th:utext` with user input                         | 🟡 Warning     | 🔴 **[C04]** Critical   | XSS 취약점                                         |
| `@Transactional` 메서드 내 `RestTemplate.exchange()` 등 외부 호출 | 🟡 [W04] Warning | 🔴 **[IC07]** Critical (STEP 0 우선) | 트랜잭션 구간 내 외부 호출 → 응답 지연 시 DB 커넥션풀 고갈 — 운영 경험 |
| AJAX 버튼 클릭 시 `disabled` 처리 / 로딩바 누락 | 🟡 [W02] Warning | 🔴 **[IC03]** Critical (STEP 0 우선) | UI 더블클릭 방어 누락 → 중복 지급 — I5 회귀 위험 |
| 외부 거래번호 중복 체크 없는 `/pay/auto` 엔드포인트 | 🟡 [W04] Warning | 🔴 **[IC01]** Critical (STEP 0 우선) | 멱등성 미적용 → 외부 재시도 시 중복 처리 — I6 회귀 위험 |
| `generate_series(#{startDate}, #{endDate}, '1 day')` 범위 검증 없음 | 🟡 [W04] Warning | 🔴 **[IC06]** Critical (STEP 0 우선) | 사용자 입력 기반 무제한 범위 → DoS / DB 부하 — 운영 경험 |

</Calibration_Examples>
