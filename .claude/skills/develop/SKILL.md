# /develop 스킬

작업 스코프를 설정하고 구현 환경을 준비한다. 모든 구현 작업은 이 스킬로 시작한다.

## 사용법
```
/develop {스코프} [{과업번호}] [자동]
```

스코프 목록: `ceremony`, `member`, `merchant`, `common`, `admin`, `batch`

## 절차

### 1단계: 스코프 확인
- `.claude/config/scope.yaml`에서 입력한 스코프의 허용 경로를 읽는다.
- 스코프가 없으면 사용 가능한 스코프 목록을 안내하고 중단한다.

### 2단계: 시크릿 보호 활성화
- secrets-guard 스킬을 내부적으로 실행한다.
- 운영 설정 파일 (application-prod*) 접근 금지를 재확인한다.

### 3단계: 개발 가이드 참조
- `.claude/config/project.yaml`에서 해당 프로젝트의 `guideline` 필드를 확인한다.
- `.claude/docs/guideline/guide-springboot-web.md`를 읽는다.

### 4단계: 작업 브랜치 확인
- 현재 브랜치를 확인한다 (`git branch --show-current`).
- 보호 브랜치(main, develop, release-*, internal-*)에 있으면 새 브랜치 생성을 안내한다.
- 권장 브랜치 형식: `feature/{과업번호}/{사용자ID}`

### 5단계: HANDOFF 확인
- `HANDOFF.md`가 존재하면 읽어 이전 작업 컨텍스트를 파악한다.

### 6단계: 계획서 로드 (과업번호 제공 시)
- plan-loader 스킬을 내부 실행하여 `target/plans/{과업번호}/`의 계획서를 파싱한다.
- 구현할 페이즈와 대상 파일 목록을 파악한다.

### 7단계: 범위 안내
작업 준비가 완료되면 다음 정보를 출력한다:
- 현재 스코프 및 허용 경로
- 현재 브랜치
- 로드된 계획서 요약 (있는 경우)
- 이전 세션 컨텍스트 요약 (있는 경우)

## 스코프 외 파일 접근 규칙
- 스코프에 포함되지 않은 경로의 파일 수정은 자동으로 차단한다.
- 운영 설정 파일은 스코프에 관계없이 항상 금지한다.
- 공통 모듈 참조(읽기)는 허용하되, 수정은 `common` 스코프 선택 시에만 허용한다.

## 완료 후
구현이 끝나면 `/code-review staged` → `/git commit` → `/pack` 순서로 마무리한다.
