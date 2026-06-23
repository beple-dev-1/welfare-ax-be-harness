# code-review 기본 설정

<Default_Settings>

| 키 | 기본값 | 설명 |
|---|---|---|
| `default_lang` | `ko` | 리뷰 언어 (ko / en) |
| `default_target` | `staged` | 리뷰 대상 (staged / unstaged / all / HEAD~N) |
| `review_focus` | bug, security, performance, quality, test | 리뷰 집중 항목 |

</Default_Settings>

<Ignore_Files>

분석에서 제외하는 파일 패턴:

- `*.lock`
- `*.min.js`
- `*.min.css`
- `package-lock.json`
- `yarn.lock`
- `migrations/*`
- `*.generated.*`
- `**/js/lib/**`
- `**/vendor/**`

</Ignore_Files>

<Severity_Rules>

심각도 분류 패턴 데이터는 **[`severity-rules.md`](severity-rules.md) 단일 출처**로 분리되었다.

- 분류 알고리즘: [`severity-algorithm.md`](severity-algorithm.md) STEP 0~3
- 패턴 표 (C01~C11 / W01~W16 / S01~S06): [`severity-rules.md`](severity-rules.md)
- 조직별 룰 추가/수정: `severity-rules.md` 만 편집 — settings.md 본문 수정 불필요

</Severity_Rules>

<Custom_Checklist>

팀 커스텀 체크리스트. 유형별 평가 이후에 `### 📝 팀 체크리스트` 섹션에서 검증한다.
diff에 해당 내용이 포함되지 않아 판단 불가한 항목은 출력하지 않는다.

1. `{{config.commonUtilsArtifact}}` 중복 구현 여부 확인
2. JPA Entity 클래스에 @Entity, @Table, @Id, @GeneratedValue 어노테이션이 올바르게 적용되었는지 확인
3. 외부 API 호출 시 timeout 설정 및 예외 처리 존재 여부
4. @Transactional 범위 적절성 (과도한 범위 또는 누락)
5. HikariCP 커넥션 반환 누락 (try-with-resources 미사용)
6. ResponseCode/ResponseTemplate이 올바른 모듈에 정의되었는지 확인
7. @Scheduled/@KafkaListener 메소드 try-catch 감싸기 (미처리 시 중단/무한루프)
8. Redis 저장 시 TTL 명시적 설정 여부 (미설정 시 메모리 누수)
9. 컬렉션 반복 중 원본 수정 금지 (ConcurrentModificationException 방지)
10. 신규/수정 기능에 대응하는 JUnit 테스트 클래스 존재 여부 확인

</Custom_Checklist>
