# 개발 가이드 — 프론트엔드 IIFE 모듈 패턴

> **적용 대상:** we-adk-welfare-user 전 스코프 (ceremony / 추후 추가 스코프)
> **단일 출처:** `.claude/config/project.yaml` `projects[]` (`common.md` §1 기술 스택 표 참조)
>
> 공통 규칙(디렉토리, AJAX, DOM, 라이브러리, Thymeleaf, CSS, 보안)은 `common.md`를 참조한다.

---

## 스코프 → 패턴 매핑

| 스코프 | JS 패턴 | AJAX 방식 |
|--------|---------|----------|
| `ceremony` | IIFE 모듈 패턴 | `$.ajax()` + ApiResponse |
| *(추가 스코프)* | IIFE 모듈 패턴 | `$.ajax()` + ApiResponse |

---

## 4. JavaScript 코딩 패턴

### 4-1. IIFE 모듈 패턴 — 기본 구조

모든 페이지 JS는 IIFE로 감싸 전역 스코프 오염을 방지한다.

```javascript
(() => {
    "use strict";

    // 상수 정의
    const PAGE_SIZE = 10;

    /**
     * 페이지 초기화.
     */
    function init() {
        bindEvents();
        loadList();
    }

    /**
     * 이벤트 바인딩.
     */
    function bindEvents() {
        $("#btnSearch").on("click", loadList);
        $("#btnReset").on("click", resetForm);
    }

    /**
     * 목록 조회.
     */
    function loadList() {
        const data = {
            pageSize: PAGE_SIZE,
            pageNo: 1
        };

        $.ajax({
            url: "/api/v1/ceremony/list",
            type: "GET",
            data: data,
            success(res) {
                if (res.code === "0000") {
                    renderList(res.data);
                } else {
                    alert(res.message);
                }
            },
            error() {
                alert("서버 오류가 발생했습니다.");
            }
        });
    }

    /**
     * 목록 렌더링.
     *
     * @param {Array} list - 조회된 목록
     */
    function renderList(list) {
        const $tbody = $("#ceremonyTable tbody");
        $tbody.empty();

        if (!list || list.length === 0) {
            $tbody.append('<tr><td colspan="5">조회 결과가 없습니다.</td></tr>');
            return;
        }

        list.forEach(item => {
            $tbody.append(buildRow(item));
        });
    }

    /**
     * 폼 초기화.
     */
    function resetForm() {
        $("#searchForm")[0].reset();
    }

    $(document).ready(init);
})();
```

### 4-2. POST 요청 + 중복 제출 방지 패턴

```javascript
(() => {
    "use strict";

    let isSubmitting = false;

    function init() {
        bindEvents();
    }

    function bindEvents() {
        $("#btnSubmit").on("click", onClickSubmit);
    }

    /**
     * 경조사 신청 제출.
     */
    function onClickSubmit() {
        if (!validateForm()) return;
        if (isSubmitting) return;
        isSubmitting = true;

        const data = {
            eventType: $("#eventType").val(),
            eventDate: $("#eventDate").val(),
            applicantName: $("#applicantName").val()
        };

        $.ajax({
            url: "/api/v1/ceremony/apply",
            type: "POST",
            contentType: "application/json",
            data: JSON.stringify(data),
            success(res) {
                if (res.code === "0000") {
                    alert("신청이 완료되었습니다.");
                    location.href = "/ceremony/list";
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

    /**
     * 폼 유효성 검증.
     *
     * @returns {boolean} 유효 여부
     */
    function validateForm() {
        const eventType = $("#eventType").val();
        if (!eventType) {
            alert("경조사 유형을 선택해주세요.");
            $("#eventType").focus();
            return false;
        }
        return true;
    }

    $(document).ready(init);
})();
```

### 4-3. ES6 class 패턴 (복잡한 상태 관리가 필요한 경우)

단순 페이지에서는 4-1 패턴을 사용한다. 복잡한 상태 관리·재사용 로직이 필요한 경우에만 class를 사용한다.

```javascript
(() => {
    "use strict";

    /**
     * 경조사 신청 페이지 컨트롤러.
     */
    class CeremonyApplyPage {

        constructor() {
            this.$form = $("#applyForm");
            this.isSubmitting = false;
        }

        /**
         * 초기화.
         */
        init() {
            this.bindEvents();
        }

        /**
         * 이벤트 바인딩.
         */
        bindEvents() {
            $("#btnSubmit").on("click", () => this.onClickSubmit());
        }

        /**
         * 제출 처리.
         */
        onClickSubmit() {
            if (this.isSubmitting) return;
            if (!this.validateForm()) return;

            this.isSubmitting = true;

            $.ajax({
                url: "/api/v1/ceremony/apply",
                type: "POST",
                contentType: "application/json",
                data: JSON.stringify(this.collectFormData()),
                success: (res) => this.handleResponse(res),
                error: () => alert("서버 오류가 발생했습니다."),
                complete: () => { this.isSubmitting = false; }
            });
        }

        /**
         * 응답 처리.
         *
         * @param {Object} res - ApiResponse
         */
        handleResponse(res) {
            if (res.code === "0000") {
                alert("신청이 완료되었습니다.");
                location.href = "/ceremony/list";
            } else {
                alert(res.message);
            }
        }

        /**
         * 폼 데이터 수집.
         *
         * @returns {Object} 수집된 폼 데이터
         */
        collectFormData() {
            return {
                eventType: $("#eventType").val(),
                eventDate: $("#eventDate").val(),
                applicantName: $("#applicantName").val()
            };
        }

        /**
         * 폼 유효성 검증.
         *
         * @returns {boolean} 유효 여부
         */
        validateForm() {
            const eventType = $("#eventType").val();
            if (!eventType) {
                alert("경조사 유형을 선택해주세요.");
                $("#eventType").focus();
                return false;
            }
            return true;
        }
    }

    $(document).ready(function() {
        new CeremonyApplyPage().init();
    });
})();
```

---

## 5. UI 모달 처리 (Bootstrap 5.x)

네이티브 `alert()` / `confirm()` 대신 **Bootstrap Modal / Toast**를 사용한다.
상세 사용법은 `common.md §9` 참조.

### 5-1. 확인 모달 패턴

```javascript
(() => {
    "use strict";

    let pendingAction = null;

    function init() {
        bindEvents();
    }

    function bindEvents() {
        // 삭제 버튼 클릭 → 확인 모달 오픈
        $("#ceremonyTable").on("click", ".btn-delete", function() {
            const id = $(this).data("id");
            openConfirmModal("삭제하시겠습니까?", () => deleteCeremony(id));
        });

        // 모달 확인 버튼
        document.getElementById("btnModalConfirm").addEventListener("click", function() {
            if (pendingAction) pendingAction();
            bootstrap.Modal.getInstance(document.getElementById("confirmModal")).hide();
        });
    }

    /**
     * 확인 모달 오픈.
     *
     * @param {string} message - 모달 본문 메시지
     * @param {Function} onConfirm - 확인 시 실행할 콜백
     */
    function openConfirmModal(message, onConfirm) {
        document.querySelector("#confirmModal .modal-body").textContent = message;
        pendingAction = onConfirm;
        new bootstrap.Modal(document.getElementById("confirmModal")).show();
    }

    /**
     * 경조사 삭제.
     *
     * @param {string} id - 경조사 ID
     */
    function deleteCeremony(id) {
        $.ajax({
            url: `/api/v1/ceremony/${id}`,
            type: "DELETE",
            success(res) {
                if (res.code === "0000") {
                    showToast("삭제되었습니다.");
                    loadList();
                } else {
                    showToast(res.message, "error");
                }
            },
            error() {
                showToast("서버 오류가 발생했습니다.", "error");
            }
        });
    }

    /**
     * Toast 알림 표시.
     *
     * @param {string} message - 표시할 메시지
     * @param {string} [type="success"] - 알림 유형 (success | error)
     */
    function showToast(message, type = "success") {
        const toastEl = document.getElementById("toastMsg");
        toastEl.querySelector(".toast-body").textContent = message;
        toastEl.className = `toast ${type === "error" ? "bg-danger text-white" : ""}`;
        new bootstrap.Toast(toastEl, { delay: 3000 }).show();
    }

    $(document).ready(init);
})();
```

### 5-2. 단순 알림 (Toast)

```javascript
function showToast(message, type = "success") {
    const toastEl = document.getElementById("toastMsg");
    toastEl.querySelector(".toast-body").textContent = message;
    new bootstrap.Toast(toastEl, { delay: 3000 }).show();
}
```

---

## 6. AJAX 패턴 상세

### 6-1. GET 조회

```javascript
$.ajax({
    url: "/api/v1/ceremony/" + id,
    type: "GET",
    success(res) {
        if (res.code === "0000") {
            fillForm(res.data);
        } else {
            alert(res.message);
        }
    },
    error() {
        alert("조회 중 오류가 발생했습니다.");
    }
});
```

### 6-2. JSON POST

```javascript
$.ajax({
    url: "/api/v1/ceremony/apply",
    type: "POST",
    contentType: "application/json",
    data: JSON.stringify(formData),
    success(res) {
        if (res.code === "0000") {
            // 성공
        } else {
            alert(res.message);
        }
    },
    error() {
        alert("서버 오류가 발생했습니다.");
    }
});
```

### 6-3. 폼 직렬화 POST

```javascript
$.ajax({
    url: "/api/v1/ceremony/search",
    type: "POST",
    data: $("#searchForm").serialize(),
    success(res) {
        if (res.code === "0000") {
            renderList(res.data);
        } else {
            alert(res.message);
        }
    },
    error() {
        alert("서버 오류가 발생했습니다.");
    }
});
```

---

## 7. 오류 처리

### 7-1. ApiResponse 코드 기반

백엔드 `ApiResponse<T>` 포맷: `{code: "0000", message: "성공", data: {...}}`

```javascript
success: function(res) {
    if (res.code === "0000") {
        // 성공 처리
    } else {
        // 비즈니스 오류 — res.message 표시
        alert(res.message);
    }
},
error: function(xhr) {
    // HTTP 오류 (4xx, 5xx)
    alert("서버 오류가 발생했습니다.");
}
```

### 7-2. async/await + try-catch (비동기 패턴 필요 시)

```javascript
async function loadCeremonyDetail(id) {
    try {
        const res = await $.ajax({
            url: `/api/v1/ceremony/${id}`,
            type: "GET"
        });
        if (res.code === "0000") {
            return res.data;
        }
        alert(res.message);
        return null;
    } catch (error) {
        alert("조회 중 오류가 발생했습니다.");
        return null;
    }
}
```
