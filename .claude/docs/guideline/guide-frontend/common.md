# 개발 가이드 — 프론트엔드 공통 (JS / CSS / Thymeleaf)

> **적용 대상:** we-adk-welfare-user (Spring Boot 4.1 JAR)
> **단일 출처:** `.claude/config/project.yaml` `projects[]` 프론트엔드 기술 스택 표
>
> JS 코딩 패턴(§4)과 패턴별 오류 처리(§7)는 별도 파일을 참조한다:
> - `iife-pattern.md` — IIFE 모듈 패턴 (we-adk-welfare-user 전체 적용)

---

## 1. 프론트엔드 기술 스택

> **단일 출처:** 본 표는 현재 워크스페이스의 스택 인벤토리. 신규 스코프·라이브러리 추가 시 `.claude/config/project.yaml` 갱신 + 본 표 동기.

| 프로젝트 | jQuery | UI 라이브러리 | JS 패턴 | 패키징 |
|---------|--------|--------------|---------|--------|
| we-adk-welfare-user | 3.7.x | Bootstrap 5.x | IIFE 모듈 패턴 | JAR |

> **원칙:** 확정된 스택 외 라이브러리를 임의 추가하지 않는다. 신규 라이브러리는 합의 후 본 표·CLAUDE.md에 반영한다.

---

## 2. 정적 리소스 디렉토리 구조

JAR 프로젝트(`guide-springboot-web.md`) 기준:

```
src/main/resources/
  ├── static/
  │   ├── css/
  │   │   ├── common/        ← 공통 스타일
  │   │   └── {domain}/      ← 도메인별 스타일 (예: ceremony/)
  │   ├── js/
  │   │   ├── common/        ← 공통 JS (유틸, AJAX 공통 설정 등)
  │   │   ├── lib/           ← 외부 라이브러리 (jQuery 등, 수정 금지)
  │   │   └── {domain}/      ← 도메인별 JS (예: ceremony/)
  │   └── images/
  └── templates/             ← Thymeleaf 템플릿 (.html)
      ├── common/
      ├── layout/
      └── {domain}/          ← 도메인별 템플릿 (예: ceremony/)
```

---

## 3. JavaScript 파일 구성 규칙

### 3-1. 파일 분류

| 디렉토리 | 용도 | 수정 허용 |
|---------|------|---------|
| `js/lib/` | 외부 라이브러리 (jQuery 등) | 금지 |
| `js/common/` | 공통 유틸, AJAX 공통 설정, 공통 UI | 신중하게 |
| `js/{domain}/` | 도메인별 페이지 JS | 자유 |

### 3-2. 파일 명명 패턴

- **소문자 + 하이픈** (kebab-case): `ceremony-apply.js`, `ceremony-approval.js`
- **HTML/JS 1:1 매칭**: Thymeleaf 템플릿과 JS 파일을 동일 경로·동일 이름으로 매칭한다.
  ```
  templates/ceremony/apply.html     →  js/ceremony/ceremony-apply.js
  templates/ceremony/approval.html  →  js/ceremony/ceremony-approval.js
  ```

### 3-3. 외부 라이브러리 수정 금지

`js/lib/` 하위 파일은 직접 수정하지 않는다. 기능 확장이 필요하면 `js/common/`에 래퍼를 작성한다.

---

## 4. JavaScript 코딩 패턴

→ **IIFE 모듈 패턴**: `iife-pattern.md` 참조.

---

## 5. 공통 코딩 규칙

### 5-1. 명명 규칙

| 대상 | 규칙 | 예시 |
|------|------|------|
| jQuery 객체 변수 | `$` 접두사 | `$btnSearch`, `$tableBody` |
| 이벤트 핸들러 | `on` + 동사 | `onClickSearch()`, `onChangeStatus()` |
| Boolean 변수 | `is` / `has` 접두사 | `isValid`, `hasPermission` |
| 상수 | UPPER_SNAKE_CASE | `PAGE_SIZE`, `MAX_RETRY` |

### 5-2. 변수 선언

```javascript
// ✅ 허용 — const 기본, let 필요시만
const PAGE_SIZE = 10;
const $table = $("#dataTable");
let currentPage = 1;

// ❌ 금지 — 신규 코드에서 var 사용
var count = 0;
```

- **`const`** 기본 사용.
- **`let`** 은 재할당이 필요한 경우에만 사용.
- **`var`** 는 신규 코드에서 사용하지 않는다.

### 5-3. 코드 품질

- **함수**: 최대 50줄, 중첩 3단계 이하 (early return 활용), 단일 책임.
- **비교 연산자**: `===` / `!==` 엄격 비교 필수 (`==` / `!=` 금지).
- **매직 넘버 금지**: `const PAGE_SIZE = 10` 등 명명된 상수로 정의한다.

---

## 6. AJAX 통신 패턴

### 6-1. AJAX 호출 방식

we-adk-welfare-user는 jQuery `$.ajax()`를 사용한다.

### 6-2. 공통 AJAX 규칙

1. **CSRF 토큰**: POST/PUT/DELETE 요청 시 반드시 포함한다 (§12-1 CSRF 설정 참조).
2. **오류 처리 필수**: `error` 콜백을 반드시 구현한다.
3. **중복 요청 방지**: 버튼 클릭 시 중복 AJAX 호출을 방지한다.

```javascript
// ✅ 중복 요청 방지 예시
let isSubmitting = false;

function submitForm() {
    if (isSubmitting) return;
    isSubmitting = true;

    $.ajax({
        url: "/api/v1/ceremony/apply",
        type: "POST",
        contentType: "application/json",
        data: JSON.stringify(data),
        success(res) {
            if (res.code === "0000") {
                // 성공 처리
            } else {
                alert(res.message);
            }
        },
        error() {
            alert("서버 오류가 발생했습니다.");
        },
        complete() {
            isSubmitting = false;
        }
    });
}
```

---

## 7. 오류 처리 (ApiResponse 코드 기반)

> 상세 패턴은 `iife-pattern.md §7` 참조.

백엔드 `ApiResponse<T>` 응답 포맷 `{code, message, data}` 기반:

```javascript
success: function(res) {
    if (res.code === "0000") {
        // 성공 처리
    } else {
        alert(res.message);
    }
},
error: function() {
    alert("서버 오류가 발생했습니다.");
}
```

---

## 8. DOM 조작 규칙

### 8-1. jQuery 셀렉터 캐싱

```javascript
// ❌ 금지 — 반복 셀렉터 호출
$("#dataTable tbody").empty();
$("#dataTable tbody").append(html);

// ✅ 권장 — 캐싱
const $tbody = $("#dataTable tbody");
$tbody.empty();
$tbody.append(html);
```

### 8-2. 이벤트 위임

동적으로 생성되는 요소에는 이벤트 위임을 사용한다.

```javascript
// ❌ 금지 — 동적 요소에 직접 바인딩
$(".btn-delete").on("click", deleteItem);

// ✅ 권장 — 이벤트 위임
$("#ceremonyTable").on("click", ".btn-delete", function() {
    const id = $(this).data("id");
    deleteItem(id);
});
```

### 8-3. XSS 방지

- 사용자 입력은 `$.html()` 대신 `$.text()`로 삽입한다.
- HTML 삽입이 불가피한 경우 `document.createTextNode()` 기반 escape 함수를 사용한다.

---

## 9. 라이브러리 사용 원칙

1. **직접 구현 전 `js/common/`에 기존 유틸이 있는지 확인한다.**
2. `js/lib/` 파일을 직접 수정하지 않는다.
3. 네이티브 `alert()` / `confirm()` 대신 **Bootstrap 컴포넌트**를 사용한다.

### 9-1. Bootstrap 5.x 모달

```javascript
// JS API 방식 (권장)
const modal = new bootstrap.Modal(document.getElementById('confirmModal'));
modal.show();

// 이벤트 리스너
document.getElementById('confirmModal').addEventListener('hidden.bs.modal', function() {
    // 모달 닫힌 후 처리
});
```

```html
<!-- HTML 선언 — data-bs-* 속성 방식 -->
<button type="button" data-bs-toggle="modal" data-bs-target="#confirmModal">열기</button>

<div class="modal fade" id="confirmModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">확인</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">내용</div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
                <button type="button" class="btn btn-primary" id="btnModalConfirm">확인</button>
            </div>
        </div>
    </div>
</div>
```

### 9-2. Bootstrap 5.x Toast

```javascript
const toastEl = document.getElementById('toastMsg');
const toast = new bootstrap.Toast(toastEl, { delay: 3000 });
toast.show();
```

```html
<div class="toast-container position-fixed bottom-0 end-0 p-3">
    <div id="toastMsg" class="toast" role="alert">
        <div class="toast-header">
            <strong class="me-auto">알림</strong>
            <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
        </div>
        <div class="toast-body">처리가 완료되었습니다.</div>
    </div>
</div>
```

### 9-3. Bootstrap 사용 원칙

- `js/lib/` 내 Bootstrap JS/CSS 파일을 직접 수정하지 않는다.
- Bootstrap 기본 스타일 오버라이드는 `css/common/` 또는 도메인별 CSS에서 수행한다.
- `bootstrap.Modal` / `bootstrap.Toast` 등 Bootstrap JS API를 직접 호출한다 (`$(...).modal()` jQuery 플러그인 방식보다 Bootstrap 5 native API 권장).

---

## 10. Thymeleaf 연동 규칙

### 10-1. 서버 데이터 → JavaScript 전달

`th:inline="javascript"`를 사용하여 서버 데이터를 JavaScript 변수로 전달한다.

```html
<script th:inline="javascript">
    /*<![CDATA[*/
    const _memberId_    = /*[[${memberId}]]*/ "";
    const _contextPath_ = /*[[${#request.contextPath}]]*/ "";
    const _csrfToken_   = /*[[${_csrf.token}]]*/ "";
    const _csrfHeader_  = /*[[${_csrf.headerName}]]*/ "X-CSRF-TOKEN";
    /*]]>*/
</script>
<script th:src="@{/static/js/ceremony/ceremony-apply.js}"></script>
```

### 10-2. 전역 변수 명명

서버에서 주입되는 전역 변수는 **`_variableName_`** (언더스코어 감싸기) 패턴을 사용한다.

```javascript
// ✅ 서버 주입 전역 변수
const _memberId_    = "...";
const _csrfToken_   = "...";
const _contextPath_ = "...";
```

### 10-3. inline 이벤트 핸들러 금지

```html
<!-- ❌ 금지 -->
<button onclick="deleteItem('id001')">삭제</button>

<!-- ✅ 권장 — data 속성 + JS 이벤트 바인딩 -->
<button class="btn-delete" data-ceremony-id="id001">삭제</button>
```

```javascript
// JS 파일에서 이벤트 바인딩
$(".btn-delete").on("click", function() {
    const id = $(this).data("ceremonyId");
    deleteItem(id);
});
```

### 10-4. Thymeleaf Fragment 활용

공통 레이아웃(헤더, 메뉴, 푸터)은 Fragment로 분리한다.

```html
<!-- layout/default.html -->
<div th:replace="~{layout/header :: header}"></div>
<div th:replace="~{layout/sidebar :: sidebar}"></div>
```

---

## 11. CSS 규칙

### 11-1. 디렉토리 구조

```
css/
  ├── common/
  │   ├── reset.css       ← 브라우저 초기화
  │   ├── layout.css      ← 공통 레이아웃
  │   └── common.css      ← 공통 스타일
  ├── lib/                ← 외부 CSS (수정 금지)
  └── {domain}/           ← 도메인별 스타일 (예: ceremony/)
```

### 11-2. 명명 규칙

- **클래스명**: kebab-case: `btn-primary`, `ceremony-form__section`
- **BEM 권장**: `.block__element--modifier`
  ```css
  .ceremony-form { }
  .ceremony-form__section { }
  .ceremony-form__btn--submit { }
  ```
- **ID 셀렉터**: camelCase: `#searchForm`, `#ceremonyTable`

### 11-3. 단위

- 폰트 크기: `rem` 권장
- 레이아웃: `px` 또는 `%`
- `!important` 최소화

### 11-4. CSS 수정 원칙

- `css/lib/` 수정 금지.
- 외부 라이브러리 스타일 오버라이드는 `css/common/` 또는 도메인별 CSS에서.

---

## 12. 보안 규칙

### 12-1. CSRF 토큰 전역 설정

Spring Security CSRF 토큰을 모든 POST/PUT/DELETE 요청에 자동 포함하도록 설정한다.

```javascript
// js/common/ajax-setup.js 또는 공통 레이아웃 스크립트
$.ajaxSetup({
    beforeSend: function(xhr, settings) {
        if (!/^(GET|HEAD|OPTIONS|TRACE)$/i.test(settings.type)) {
            xhr.setRequestHeader(_csrfHeader_, _csrfToken_);
        }
    }
});
```

### 12-2. 금지 사항

- `eval(userInput)`, `new Function(userInput)()` — 임의 코드 실행 금지
- `element.innerHTML = userInput`, `$.html(userInput)` — XSS 위험 (§8-3 참조)
- JS 코드에 API Key, 비밀번호, JWT 시크릿 하드코딩 금지

---

## 체크리스트

- [ ] JS 파일이 `src/main/resources/static/js/{domain}/` 구조를 따르는가
- [ ] JS 파일명이 kebab-case이며 HTML 템플릿과 1:1 매칭되는가
- [ ] IIFE 모듈 패턴을 따르는가 (`iife-pattern.md` 참조)
- [ ] `const` 기본, `let` 필요시만 (`var` 금지)
- [ ] `===` / `!==` 엄격 비교를 사용하는가
- [ ] AJAX 호출에 `error` 콜백이 구현되어 있는가
- [ ] 중복 AJAX 요청 방지(`isSubmitting`)가 적용되어 있는가
- [ ] ApiResponse `res.code === "0000"` 기반 응답 처리인가
- [ ] jQuery 셀렉터가 캐싱되어 있는가
- [ ] 동적 요소에 이벤트 위임을 사용하는가
- [ ] 사용자 입력을 HTML로 삽입 시 XSS 방지 처리가 되어 있는가
- [ ] Thymeleaf 서버 주입 변수가 `_variableName_` 패턴인가
- [ ] inline 이벤트 핸들러(`onclick` 등)를 사용하지 않았는가
- [ ] CSRF 토큰이 POST/PUT/DELETE 요청에 포함되는가
- [ ] JS에 민감 정보가 하드코딩되지 않았는가
