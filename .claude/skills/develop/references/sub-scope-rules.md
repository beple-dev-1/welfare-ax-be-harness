# 하위 스코프 검증·탐색 규칙

> `/develop` 스킬의 1단계(인수 검증) 및 7단계(모듈 탐색 대상)에서 호출된다.
> 본 파일은 **조직 무관 generic 알고리즘** 만 보유한다. 특화 어휘·경로·파라미터명은 **`.claude/config/scope.yaml`** 의 `subScope` 정의가 단일 출처다.
>
> **변수**:
> - `{basePackagePath}` = `.claude/config/project.yaml` `basePackagePattern` 에서 `.{module}` 제거 + dot 을 slash 로 변환한 값.
>   예: `com.beplepay.weadk.welfare.{module}` → `com/beplepay/weadk/welfare`
> - `{projectRoot}` = `scope.yaml` 의 해당 entry `project` (= project.yaml `projects[].name`)
> - `{paramValue}` = 사용자가 `{스코프} {값}` 형태로 입력한 두 번째 인자

---

## 1. 인수 검증 (1단계에서 호출)

### 1-1. 일반 알고리즘

```
parseArguments(args):
  scopeId  = args[0]
  paramVal = args[1] or null

  entry = scope.yaml.groups.*.scopes[].find(id == scopeId)
  if entry is null:
    return error("스코프 미존재")

  if paramVal is null:
    return { mode: "fullScope", entry }

  if entry.subScope is null:
    return error("이 스코프는 하위 파라미터를 지원하지 않습니다")

  validatePath = resolveVars(entry.subScope.validatePath, paramValue=paramVal)
  if not exists({projectRoot}/{validatePath}):
    return error("유효하지 않은 {entry.subScope.paramName}: " + paramVal +
                 ". 유효 목록은 다음 디렉토리에서 확인: " + dirname(validatePath))

  return { mode: "subScope", entry, paramValue: paramVal }
```

### 1-2. 변수 치환 규칙

`subScope.validatePath` / `subScope.allowedPaths` / `subScope.scanPaths` / `subScope.cacheFileSuffix` 의 변수 토큰:

| 토큰 | 치환 값 |
|---|---|
| `{basePackagePath}` | project.yaml `basePackagePattern` 에서 `.{module}` 제거 + dot→slash |
| `{paramValue}` | 사용자 입력 두 번째 인자 |

치환은 `paramValue` 값이 결정된 직후 일괄 수행한다.

### 1-3. `--ref-read` 값 제약

- `--ref-read` 값은 최상위 스코프 식별자만 허용 (`scope.yaml` `groups.*.scopes[].id`).
- 하위 스코프 식별자는 받지 않는다. 상위 스코프로 지정.

---

## 2. 모듈 탐색 대상 (7단계에서 호출)

### 2-1. scanPaths 해석

`subScope.scanPaths` 값:

- 명시적 경로 리스트 → 각 항목 변수 치환 후 스캔 대상 추가
- `"@inherit-shared"` 토큰 → 해당 그룹의 `sharedCodeRange` 를 그대로 상속 (그룹별 공통 코드)
- 미지정 → `subScope.allowedPaths` 와 동일

### 2-2. 그룹 sharedCodeRange 상속

`scanPaths: "@inherit-shared"` 시 그룹 `sharedCodeRange` 의 각 경로를 다음 규칙으로 확장:

```
java[]            → {projectRoot}/src/main/java/{basePackagePath}/{scopeId}/{path}
javaRootFiles[]   → {projectRoot}/src/main/java/{basePackagePath}/{scopeId}/{file}
resources[]       → {projectRoot}/src/main/resources/{path}
```

> `{scopeId}` 가 패키지 디렉토리명과 다른 경우 그룹 `sharedCodeRange` 에 `packageDir` 키를 추가 (예외 케이스용).

### 2-3. 결과 합산

7단계 스캔 대상 = `subScope.allowedPaths` 치환 결과 ∪ `subScope.scanPaths` 해석 결과.

---

## 3. 캐시 식별자 (7단계 저장 경로)

`subScope.cacheFileSuffix` 값을 변수 치환 후 캐시 파일명에 결합:

```
cacheFileName = scopeId + resolveVars(subScope.cacheFileSuffix) + ".md"
```

미지정 시 `{scopeId}.md` (일반 스코프와 동일).

---

## 4. 그룹 sharedCodeRange 정의

`scope.yaml` `groups.{X}.sharedCodeRange` 필드:

```yaml
groups:
  {X}:
    sharedCodeRange:
      java: [common/, config/, ...]          # 패키지 하위 디렉토리
      javaRootFiles: [Application.java, ...] # 패키지 루트 직속 파일
      resources: [views/templates/, ...]     # 리소스 하위 경로
```

`subScope.scanPaths: "@inherit-shared"` 시 본 정의가 적용된다. 명시적 경로 리스트 사용 시 그룹 `sharedCodeRange` 는 무시.

---

## 5. 외부 조직 도입 가이드

신규 조직에서 하위 스코프 지원 시:

1. `scope.yaml` 의 해당 entry 에 `subScope` 블록 추가 (paramName/validatePath/allowedPaths/scanPaths/cacheFileSuffix).
2. 공통 코드 상속이 필요하면 그룹에 `sharedCodeRange` 정의 + `scanPaths: "@inherit-shared"` 지정.
3. 본 파일(`sub-scope-rules.md`) 수정 불필요 — generic 알고리즘이 자동 처리한다.
