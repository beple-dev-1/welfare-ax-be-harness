# 코드 리뷰 심각도 규칙

## CRITICAL (즉시 수정)

### 비즈니스 로직
- 복지혜택 지급·취소 API의 중복 처리 방지 미적용
- 잔액/한도 동시성 처리 없이 SELECT→비교→UPDATE 패턴
- 배치 재실행 멱등성 미보장

### 보안
- PII(개인정보) 로그 노출 (`log.info("회원명: {}", member.getName())`)
- 코드·설정·Swagger 메타정보에 개인 이메일·연락처 하드코딩
- 인증 없이 접근 가능한 보호 API 엔드포인트
- 시크릿/비밀번호 하드코딩
- 운영 환경 Swagger UI 노출 (`springdoc.swagger-ui.enabled` 기본값 미설정)

### 아키텍처
- @Transactional 메서드 내 외부 REST API 호출
- Controller에서 비즈니스 로직 수행 (Service 미사용)
- 입력값 서버 검증 완전 누락

## WARNING (권고 수정)

### 성능
- 인덱스 미사용 LIKE '%{키워드}%' 쿼리
- N+1 문제 발생 가능한 연관 관계 조회
- 트랜잭션 범위가 과도하게 넓음

### 안정성
- 예외 처리 누락 (catch 없는 외부 호출)
- 배치 실패 시 알림 경로 미정의
- null 체크 없는 Optional.get() 사용

### 코드 품질
- @Transactional readOnly 미구분
- DTO와 Entity 직접 혼용

## INFO (참고)

### 컨벤션
- 네이밍 규칙 미준수
- 불필요한 주석 또는 영어 주석
- import 순서 불일치

### 테스트
- 경계값 테스트 미포함
- 예외 케이스 테스트 미포함
