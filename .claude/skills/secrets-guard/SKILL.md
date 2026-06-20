# secrets-guard 스킬 (내부)

운영 설정·암호화 값 접근·수정·복호화를 차단하는 보안 규칙을 활성화한다.
이 스킬은 `/develop` 실행 시 자동으로 활성화된다.

## 차단 대상

### 운영 설정 파일
- `application-prod.yaml`, `application-prod.properties`
- `application-production.yaml`
- `.env`, `.env.*`

### 보안 자산
- `*.pem`, `*.p12`, `*.jks`, `*.keystore`
- `id_rsa`, `id_rsa.pub`
- `credentials.json`

## 차단 행동

다음 행동을 수행하지 않는다:
- 위 파일 읽기 또는 수정
- 암호화된 값 복호화 시도
- 하드코딩된 시크릿 코드에 삽입
- 실제 운영 DB 접속 정보를 코드에 기재

## 허용 예외

- `.claude/` 디렉터리 내 설정 파일 (하네스 설정)
- `application.yaml` (개발 기본 설정)
- `application-local.yaml`, `application-dev.yaml` (로컬/개발 환경 설정)
- 마스킹된 메타 정보 (실제 값이 없는 예시 설정)
