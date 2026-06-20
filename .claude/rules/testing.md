# 테스트 기준

## 테스트 작성 원칙

- 모든 Service 레이어 비즈니스 로직은 단위 테스트 작성
- 외부 의존성(DB, 외부 API)은 Mock 처리하여 단위 테스트 속도 유지
- 통합 테스트는 `@SpringBootTest`로 작성하되 꼭 필요한 경우에만
- 테스트 클래스명: `{ClassName}Test`, 메서드명: `{행위}_{상황}_{기대결과}` 형식

## 테스트 슬라이스

- Controller 테스트: `@WebMvcTest` + MockMvc 사용
- Repository 테스트: `@DataJpaTest` + H2 또는 Testcontainers
- Service 단위 테스트: JUnit5 + Mockito (`@ExtendWith(MockitoExtension.class)`)

## 복지 도메인 필수 검증 항목

- 혜택 지급: 잔액 부족, 한도 초과, 중복 지급 경계값 테스트
- 가맹점 처리: 미등록 가맹점, 정지 가맹점 처리 케이스
- 보안: 권한 없는 접근, 만료된 토큰 처리

## 완료 기준 (DoD)

구현 완료라고 판단하기 전에 아래 항목을 확인한다:

- [ ] 핵심 비즈니스 로직 단위 테스트 작성 및 통과
- [ ] 경계값 및 실패 케이스 테스트 포함
- [ ] `/code-review` 실행 후 CRITICAL 0건
- [ ] 컨벤션 준수 확인 (네이밍, import 순서, 주석)
- [ ] 트랜잭션 경계 및 중복 처리 방지 로직 확인
- [ ] 입력값 서버 검증 확인
