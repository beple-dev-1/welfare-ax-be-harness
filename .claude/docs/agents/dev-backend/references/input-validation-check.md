---
name: input-validation-check
description: dev-backend 4-2단계 — 입력값 검증 자체 점검 (4-2-1 Controller @Valid / 4-2-2 DTO Bean Validation 표 / 4-2-3 한국 도메인 정규식 표 / 4-2-4 점검 항목). Controller·Service 외부 입력 경로 생성/수정 직후 Read.
---

# 4-2단계 — 입력값 검증 자체 점검

Controller·Service에 **외부 입력**(HTTP Request 파라미터·외부 API 응답·Batch Job 입력 등)을 받는 경로가 있으면 **즉시 아래 절차로 입력값 검증을 자체 점검**한다.

> **운영 사례**: 프론트엔드에서 핸드폰번호 검증을 누락한 사례 발생. 백엔드 Bean Validation은 *프론트 우회 공격 방어*의 마지막 보루이므로 프론트와 동일한 검증을 백엔드에서 다시 수행해야 한다.

---

## 4-2-1. Controller `@Valid` 적용

모든 `@RequestBody` / `@ModelAttribute` DTO에 `@Valid` 어노테이션 적용 의무. 검증 실패는 `BindingResult`로 받아 표준 응답 반환:

```java
@PostMapping("/api/ceremony/apply")
public ResponseTemplate apply(@Valid @RequestBody CeremonyApplyRequest req, BindingResult result) {
    if (result.hasErrors()) {
        return ResponseTemplate.fail(ResponseCode.INVALID_PARAM, result);
    }
    // ...
}
```

---

## 4-2-2. DTO Bean Validation 어노테이션

| 어노테이션                    | 용도                        | 예시                                                              |
| ----------------------------- | --------------------------- | ----------------------------------------------------------------- |
| `@NotNull`                    | null 차단                   | `@NotNull private String userId;`                                 |
| `@NotBlank`                   | null/empty/공백 문자열 차단 | `@NotBlank private String name;`                                  |
| `@NotEmpty`                   | null/empty 컬렉션 차단      | `@NotEmpty private List<String> items;`                           |
| `@Size(min, max)`             | 문자열·컬렉션 길이          | `@Size(max = 100) private String email;`                          |
| `@Pattern(regexp)`            | 정규식 매칭                 | `@Pattern(regexp = "^01[016789]\\d{7,8}$") private String phone;` |
| `@Email`                      | 이메일 형식                 | `@Email private String email;`                                    |
| `@Min(N)` `@Max(N)`           | 숫자 범위                   | `@Min(0) @Max(999) private Integer age;`                          |
| `@Positive` `@PositiveOrZero` | 양수/0 이상                 | `@Positive private Long amount;`                                  |

---

## 4-2-3. 한국 도메인 필드 정규식 (dev-frontend 4-1-1 정합)

| 필드       | `@Pattern` 정규식                  |
| ---------- | ---------------------------------- |
| 핸드폰번호 | `^01[016789]-?\\d{3,4}-?\\d{4}$`   |
| 사업자번호 | `^\\d{3}-?\\d{2}-?\\d{5}$`         |
| 법인번호   | `^\\d{6}-?\\d{7}$`                 |
| 우편번호   | `^\\d{5}$`                         |
| 카드번호   | `^\\d{4}-?\\d{4}-?\\d{4}-?\\d{4}$` |

---

## 4-2-4. 점검 항목

| 점검 항목               | 체크 내용                                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------------------ |
| Controller `@Valid`     | 외부 입력 받는 모든 메서드에 `@Valid` 적용했는가                                                 |
| DTO 어노테이션          | 필수·길이·형식 제약을 모두 어노테이션으로 명시했는가                                             |
| 한국 도메인 필드 정규식 | 핸드폰·사업자번호 등 형식 필드에 `@Pattern` 적용했는가 (dev-frontend 4-1-1과 정합 — 동일 정규식) |
| BindingResult 처리      | 검증 실패 시 표준 ResponseTemplate으로 응답하는가 (예: `INVALID_PARAM`)                          |
| 프론트 우회 방어        | 프론트 검증을 신뢰하지 않고 백엔드에서 동일 검증을 다시 수행하는가 (다중 방어)                   |

검증 누락이 발견되면 **수정 전/후를 5단계 보고에 포함**한다.

> **외부 가이드 참조**: `guide-api.md`에 _입력값 검증 (Bean Validation)_ 섹션은 현재 부재. 다른 팀원이 가이드 보강 진행 중이며, 보강 완료 후 본 4-2단계는 가이드 참조 의무화로 전환 예정.
