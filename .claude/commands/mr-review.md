# /mr-review 커맨드

GitLab MR diff를 리뷰하고 결과를 MR 댓글로 등록한다.

## 사용법
```
/mr-review {프로젝트명+MR번호 | MR URL} [en]
```
예시: `/mr-review ax 42`, `/mr-review https://gitlab.com/.../merge_requests/42`

## 절차

### 1. 입력 파싱
- `.claude/config/system.yaml`의 `gitlab` 설정에서 base URL과 project_id 매핑을 읽는다.
- MR 번호 또는 URL에서 project_id와 MR IID를 파싱한다.
- `en` 옵션이 있으면 리뷰 출력 언어를 영어로 설정한다.
- `system.yaml`의 `gitlab.baseUrl`이 비어 있으면:
  "GitLab 연동이 설정되지 않았습니다. `system.yaml`의 `gitlab` 섹션을 설정해주세요." 안내 후 중단한다.

### 2. GitLab MR diff 수집

**GitLab MCP 사용 (우선):**
GitLab MCP(`mcp__gitlab__*`) 도구가 활성화된 경우 MCP 도구로 MR 정보와 diff를 조회한다.
- MR 상세 조회: `mcp__gitlab__get_merge_request`
- diff 조회: `mcp__gitlab__list_merge_request_diffs` 또는 `mcp__gitlab__get_merge_request_diffs`
- MCP 도구명은 설치된 서버 버전에 따라 다를 수 있으므로, 사용 가능한 mcp__gitlab__* 도구 목록을 먼저 확인한다.

**GitLab MCP 미활성화 시 (curl 폴백):**
```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "{gitlab.baseUrl}/api/v4/projects/{project_id}/merge_requests/{mr_iid}/changes"
```
- `GITLAB_TOKEN` 환경변수가 설정되지 않은 경우 오류를 안내하고 중단한다.

### 3. mr-reviewer 에이전트 실행
- diff를 mr-reviewer 에이전트에 전달한다.
- `.claude/docs/anti-patterns/incident-antipatterns.md` 기준 적용

### 4. 댓글 등록 및 알림

**GitLab MCP 사용 (우선):**
MCP 도구로 MR 댓글을 등록한다: `mcp__gitlab__create_merge_request_note` 또는 동등한 도구.

**GitLab MCP 미활성화 시 (curl 폴백):**
```bash
curl -s -X POST \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"${REVIEW_BODY}\"}" \
  "{gitlab.baseUrl}/api/v4/projects/{project_id}/merge_requests/{mr_iid}/notes"
```

`system.yaml`의 `notification.enabled`가 true이면 알림도 전송한다.

## GitLab MCP 활성화 방법

GitLab 전환 시 `.mcp.json`의 gitlab 항목에 값을 설정한다:

```json
"gitlab": {
  "env": {
    "GITLAB_PERSONAL_ACCESS_TOKEN": "{실제_토큰값}",
    "GITLAB_API_URL": "{gitlab.baseUrl}/api/v4"
  }
}
```

併せて `system.yaml`의 `gitlab.baseUrl`과 `projectMappings`도 설정한다.
