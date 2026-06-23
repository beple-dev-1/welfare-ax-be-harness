# 프론트엔드 리뷰 규칙 (code-review 참조)

> we-adk-welfare-user 프론트엔드 코드 리뷰 기준.
> 기술 스택: jQuery 3.7.x, IIFE 모듈 패턴, `$.ajax()` + `ApiResponse{code, message, data}`.

---

## 프로젝트 JS 패턴

| 프로젝트 | JS 패턴 | AJAX 방식 | UI 컴포넌트 |
|---------|---------|----------|-----------|
| we-adk-welfare-user | IIFE 모듈 패턴 | `$.ajax()` + ApiResponse | 추후 확정 (현재 네이티브 alert/confirm) |

**핵심 원칙:** 신규 코드는 IIFE 모듈 패턴을 따른다. IIFE 없이 전역 변수·함수를 직접 선언하지 않는다.

---

## 정적 리소스 경로 (JAR)

| 리소스 | 경로 |
|--------|------|
| JS | `src/main/resources/static/js/{domain}/` |
| CSS | `src/main/resources/static/css/{domain}/` |
| 템플릿 | `src/main/resources/templates/{domain}/` |

---

## 심각도 매핑 (프론트엔드)

| 이슈 | severity ID | 설명 |
|------|------------|------|
| XSS (`.html(userInput)`, `innerHTML = userInput`) | **C04** | 사용자 입력 HTML 직접 삽입 |
| `th:utext` 사용자 입력 포함 | **C04** | 이스케이프 안 된 HTML 렌더링 |
| JS에 민감정보 하드코딩 (API Key, password) | **C06** | JS 민감 정보 노출 |
| POST/PUT/DELETE CSRF 토큰 누락 | **C05** | 인증/인가 누락 |
| `eval()` / `new Function()` 사용 | **C04** | XSS 취약점 |
| AJAX 중복 요청 방지 미적용 | **W02** | `isSubmitting` 플래그 없음 |
| `==` 대신 `===` 미사용 | **W03** | 타입 비교 누락 |
| `var` 사용 (신규 코드) | **W07d** | 컨벤션 위반 |
| IIFE 없이 전역 스코프에 변수·함수 직접 선언 | **W07e** | JS 패턴 불일치 |
| 서버 주입 변수 `_variableName_` 패턴 미준수 | **W07f** | Thymeleaf 컨벤션 위반 |
| `th:inline="javascript"` CDATA 미래핑 | **W07f** | 컨벤션 위반 |
| inline 이벤트 핸들러 (`onclick` 등) | **W07e** | 패턴 불일치 |
| `const` 대신 `let` (재할당 없는 변수) | **S02** | 코드 품질 |
| 코드 구조 (50줄 초과, 중첩 3단계 초과) | **S04** | 가독성 개선 |
| `console.log` 잔재 | **S05** | 디버그 코드 잔재 |
| jQuery 셀렉터 반복 호출 (캐싱 미적용) | **S04** | 성능·가독성 |

---

## Thymeleaf 규칙

| 규칙 | 판정 |
|------|------|
| POST/PUT/DELETE CSRF 토큰 누락 | **C05** |
| `th:utext` + 사용자 입력 | **C04** (XSS) — `th:text` 사용 권장 |
| `eval()` / `new Function()` | **C04** (XSS) |
| 서버 주입 전역변수 `_variableName_` 패턴 미준수 | **W07f** |
| `th:inline="javascript"` 블록 CDATA 미래핑 | **W07f** |
| inline 이벤트 핸들러 (`onclick` 등) 신규 추가 | **W07e** |
| `src/main/resources/static/` 외 경로에 JS/CSS 배치 | **W07f** |

---

## AJAX 오류 처리 점검

- `$.ajax()` 사용 시 → `error` 콜백 존재 확인
- `error` 콜백 미구현 → **W05** (예외 삼킴과 동일 맥락)
- ApiResponse 응답 처리 시 `res.code === "0000"` 분기 없이 `res.data` 직접 접근 → **W02** (오류 무시)

---

## JS 패턴 점검

- IIFE 외부에서 전역 변수·함수 선언 → **W07e**
- `bizjs.*` / `customAjax()` 등 다른 워크스페이스 라이브러리 참조 → **W07e**
- `var` 신규 사용 → **W07d**
- `==` / `!=` 비교 → **W03**
