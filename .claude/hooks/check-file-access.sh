#!/bin/bash
# 운영 설정 파일 접근 차단 훅
# PreToolUse: Read, Edit, Write 도구 실행 전 실행됨

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
FILE_PATH="${CLAUDE_TOOL_INPUT:-}"

# .claude/ 내부 설정 파일은 예외 허용
if [[ "$FILE_PATH" == *"/.claude/"* ]]; then
  exit 0
fi

# 차단 대상 패턴 목록
BLOCKED_PATTERNS=(
  "application-prod"
  "application-production"
  ".env"
  "credentials.json"
  ".pem"
  ".p12"
  ".jks"
  ".keystore"
  "id_rsa"
)

for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$PATTERN"* ]]; then
    echo "⛔ [check-file-access] 차단: 운영/보안 파일에 접근할 수 없습니다."
    echo "   대상 파일: $FILE_PATH"
    echo "   사유: 운영 설정·보안 자산 보호 정책"
    exit 1
  fi
done

exit 0
