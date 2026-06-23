# Input Format — code-review / code-reviewer 공통

> code-review skill 및 code-reviewer agent 의 `$ARGUMENTS` 파싱 규격 단일 출처. 본 references 는 SKILL.md `<Input_Format>` 과 agent prompt `<Input_Format>` 양쪽에서 참조한다.

## 파싱 토큰

| 값       | 설명                             | 기본값      |
| -------- | -------------------------------- | ----------- |
| `TARGET` | 리뷰 대상 범위                   | `staged`    |
| `LANG`   | 리뷰 언어 `ko` / `en`            | `ko`        |
| `PATH`   | 특정 파일/디렉토리 스코프 (선택, **복수 가능**) | 없음 (전체) |

## 호출 예시

```
(없음)                        # staged 변경사항 (git diff --staged)
unstaged                      # unstaged 변경사항 (git diff)
all                           # staged + unstaged 전체 (git diff HEAD)
HEAD~1                        # 마지막 커밋 (git diff HEAD~1 HEAD)
HEAD~3                        # 최근 3개 커밋
en                            # 언어 지정 (ko/en)
staged en                     # 조합 가능
path/to/File.java             # 특정 파일만 리뷰
we-adk-welfare-user/          # 특정 모듈만 리뷰
all en we-adk-welfare-user/   # 전체 조합 가능
we-adk-welfare-user/ we-adk-welfare-common/   # 복수 경로 — 둘 중 하나라도 매칭되면 리뷰 (스코프 자동 한정 시)
```

## 동작 규칙

- `PATH` 가 지정되면 diff 결과에서 해당 경로에 매칭되는 파일만 필터링하여 리뷰한다.
- **`PATH` 는 복수 지정 가능** — 여러 경로가 주어지면 diff 파일이 **어느 하나라도 매칭(OR)** 되면 리뷰 대상에 포함한다. (code-review 스킬의 스코프 자동 한정이 활성 스코프의 복수 allowedPaths 를 전달할 때 사용)
- `TARGET` 미지정 시 `staged` 사용. `LANG` 미지정 시 `system.yaml codeReview.defaultLang` 적용 (없으면 `ko`).
- 토큰 순서 무관 — 패턴으로 자동 분류 (`HEAD~N`/`staged`/`unstaged`/`all` → TARGET, `ko`/`en` → LANG, **그 외 토큰은 모두 PATH 목록에 수집**).
