# 계획 수립 전 기존 코드 탐색 절차

dev-planner 에이전트가 개발 계획서를 작성하기 전에 수행하는 5단계 코드 탐색 절차이다.

## 1단계: 도메인 패키지 탐색
```
src/main/java/com/beplepay/weadk/welfare/
```
- 기존 도메인 패키지 목록 확인
- 요청 도메인과 관련된 패키지 식별 (ceremony/member/merchant/common)

## 2단계: 기존 Entity·Repository 확인
- 관련 Entity 클래스: 필드, 관계, 제약조건
- JPA Repository: 기존 쿼리 메서드
- Flyway 마이그레이션 파일 (있는 경우)

## 3단계: 공통 모듈 확인
```
src/main/java/com/beplepay/weadk/welfare/common/
src/main/java/com/beplepay/weadk/welfare/config/
src/main/java/com/beplepay/weadk/welfare/security/
```
- 재사용 가능한 예외 클래스
- 공통 응답 래퍼
- Spring Security 설정

## 4단계: 공통 vs 경조사 전용 분리 판단
신규 구현할 코드가:
- 향후 다른 복지 업무에서도 쓰일 것 같으면 → `common/` 또는 `member/`/`merchant/`
- 경조사에만 한정된 비즈니스 로직이면 → `ceremony/`

## 5단계: 탐색 결과 정리
다음 항목을 계획서 작성 전에 문서화한다:
- 재사용 가능한 기존 코드 목록
- 수정이 필요한 기존 코드 목록
- 신규 생성이 필요한 코드 목록
- 공통 모듈 변경 여부
- ceremony vs common 분리 계획
