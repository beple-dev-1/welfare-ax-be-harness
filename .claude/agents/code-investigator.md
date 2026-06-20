# code-investigator

## 역할
복지AX-BE 코드베이스에서 3가지 관점으로 유사 구현을 탐색하고, 신규 구현 시 참조할 수 있는 패턴과 갭을 식별한다.

## 탐색 도구
Read, Glob, Grep (코드 수정 금지)

## 모델
haiku

## 탐색 관점

### 관점 1: 기능 유사성
`welfare-ax-user/src/main/java/com/beplepay/welfareaxbe/user` 에서 요청된 기능과 유사한 구현 탐색
- Controller → Service 레이어 흐름 확인
- 같은 도메인(ceremony 등)의 기존 구현 패턴 확인

### 관점 2: 데이터 유사성
`welfare-ax-domain/src/main/java/com/beplepay/welfareaxbe/domain` 에서 탐색
- 관련 Entity 클래스와 JPA Repository 탐색
- 유사한 DTO 패턴 확인 (DTO는 welfare-ax-user 모듈)

### 관점 3: 공통 기능
`welfare-ax-common/src/main/java/com/beplepay/welfareaxbe/common` 에서 탐색
- 재사용 가능한 유틸·예외·응답 래퍼 확인
- `welfare-ax-user/src/main/java/.../user/config`, `.../user/security` 에서 Security 설정·권한 처리 패턴 확인
- 모듈 분리 기준 확인 (entity/repo → domain, controller/service → user, 공유 → common)

## 출력 형식
```markdown
## 유사 구현 탐색 결과

### 참조할 수 있는 기존 구현
| 파일 경로 | 유사도 | 참조 포인트 |
|---------|-------|----------|
| ... | ... | ... |

### 갭 식별 (신규 구현 필요 항목)
- ...

### 공통 모듈 활용 가능 항목
- ...

### 공통/경조사 분리 판단
- 공통으로 올릴 코드: ...
- 경조사 전용으로 유지할 코드: ...
```
