---
name: input-validation-check
description: dev-frontend 4-1단계 진입 시점에 Read — HTML/JS 입력 필드 검증 자체 점검 (한국 도메인 정규식·3중 검증 시점·점검 항목).
---

# 4-1단계: 입력 필드 검증 자체 점검

생성한 화면에 *형식이 정해진 입력 필드*가 있으면 **즉시 아래 절차로 검증 룰 적용을 자체 점검**한다.

> **운영 사례**: 입력 필드를 만들면서 형식 검증을 적용하지 않은 사례가 있었다. 본 자체 점검 단계는 그 재발을 차단한다.

---

## 4-1-1. 한국 도메인 필수 검증 필드

| 필드 유형 | HTML5 native | JS 정규식 | 표시 형식 |
|---------|-------------|----------|---------|
| 핸드폰번호 | `type="tel"` `pattern="01[016789]-?\d{3,4}-?\d{4}"` `maxlength="13"` | `/^01[016789]-?\d{3,4}-?\d{4}$/` | `010-1234-5678` |
| 주민등록번호 | `pattern="\d{6}-?\d{7}"` `maxlength="14"` | `/^\d{6}-?\d{7}$/` (체크섬 권장) | `900101-1234567` |
| 사업자번호 | `pattern="\d{3}-?\d{2}-?\d{5}"` `maxlength="12"` | `/^\d{3}-?\d{2}-?\d{5}$/` (체크섬 권장) | `123-45-67890` |
| 법인번호 | `pattern="\d{6}-?\d{7}"` `maxlength="14"` | `/^\d{6}-?\d{7}$/` | `110111-1234567` |
| 우편번호 | `pattern="\d{5}"` `maxlength="5"` | `/^\d{5}$/` | `12345` |
| 카드번호 | `pattern="[\d-]{16,19}"` `maxlength="19"` | `/^\d{4}-?\d{4}-?\d{4}-?\d{4}$/` | `1234-5678-9012-3456` |
| 이메일 | `type="email"` `maxlength="100"` | `/^[\w.-]+@[\w.-]+\.\w{2,}$/` | `user@example.com` |
| 금액 | `inputmode="numeric"` `pattern="[\d,]+"` | 숫자만 추출 후 정수 검증 | `1,000,000` |
| 날짜 | `type="date"` 또는 `pattern="\d{4}-\d{2}-\d{2}"` | `/^\d{4}-\d{2}-\d{2}$/` | `2026-05-06` |

---

## 4-1-2. 검증 시점 (3중 적용)

1. **HTML5 native** — 브라우저 기본 검증 (`pattern` · `required` · `maxlength` · `type`)
2. **입력 중 (onblur 또는 input 이벤트)** — JS 정규식 형식 검증, 실패 시 인라인 에러 메시지 + 필드 스타일 변경
3. **제출 직전 (submit 이벤트)** — 전체 필드 일괄 검증, 실패 시 첫 번째 실패 필드로 포커스 이동 + `event.preventDefault()` 또는 `return false`로 폼 제출 차단

### 코드 예시

```javascript
(() => {
    "use strict";

    // 핸드폰번호 정규식
    const PHONE_REGEX = /^01[016789]-?\d{3,4}-?\d{4}$/;

    function init() {
        bindValidationEvents();
        bindSubmitEvent();
    }

    // 2) 입력 중 검증 (onblur)
    function bindValidationEvents() {
        $("#phone").on("blur", function() {
            const val = $(this).val().trim();
            if (val && !PHONE_REGEX.test(val)) {
                showError($(this), "올바른 핸드폰번호 형식이 아닙니다. (예: 010-1234-5678)");
            } else {
                clearError($(this));
            }
        });
    }

    // 3) 제출 직전 검증
    function bindSubmitEvent() {
        $("#btnSubmit").on("click", function(e) {
            e.preventDefault();
            if (!validateAll()) return;
            submitForm();
        });
    }

    function validateAll() {
        const $phone = $("#phone");
        if (!PHONE_REGEX.test($phone.val().trim())) {
            showError($phone, "핸드폰번호를 올바르게 입력해주세요.");
            $phone.focus();
            return false;
        }
        return true;
    }

    function showError($field, message) {
        $field.addClass("is-invalid");
        $field.siblings(".invalid-feedback").text(message).show();
    }

    function clearError($field) {
        $field.removeClass("is-invalid");
        $field.siblings(".invalid-feedback").hide();
    }

    $(document).ready(init);
})();
```

---

## 4-1-3. 검증 라이브러리 기준

we-adk-welfare-user는 BizJS를 사용하지 않으므로 **직접 정규식 검증 함수를 작성**한다.
공통 검증 함수가 `js/common/` 에 있다면 그것을 먼저 사용한다.

---

## 4-1-4. 점검 항목

| 점검 항목 | 체크 내용 |
|---------|---------|
| 형식 필드 검증 적용 | 핸드폰·이메일·사업자번호 등 형식 필드에 `pattern` 또는 JS 정규식 적용했는가 |
| `required` 속성 | 필수 입력 필드에 `required` 또는 JS 검증 적용했는가 |
| `maxlength` / `minlength` | 길이 제한 필드에 적용했는가 |
| 검증 시점 3중 적용 | HTML5 native + 입력 중 + 제출 직전 모두 적용했는가 |
| 에러 메시지 표시 | 검증 실패 시 어떤 항목이 잘못됐는지 사용자에게 명확히 표시했는가 |
| 포커스 이동 | 제출 시 첫 번째 실패 필드로 포커스 이동했는가 |
| 폼 제출 차단 | 검증 실패 시 폼 제출을 차단했는가 (`event.preventDefault()` / `return false`) |
| FE ≤ BE 검증 강도 | FE 정규식이 BE `@Pattern` 보다 좁지 않은가 |

검증 룰 누락이 발견되면 **수정 전/후를 5단계 보고에 포함**한다.
