<#
.SYNOPSIS
  develop 7단계 모듈 캐시 스캐너 — 결정론적 출력.

.DESCRIPTION
  scope.yaml 의 스코프 entry 를 찾아 Java 소스를 스캔하고
  메모리 캐시(scopes/{scope}.md)를 생성/갱신한다.

  AI 추론 대신 deterministic file enumeration 으로 동일 입력 → 동일 출력 보장.

.PARAMETER Scope
  스코프 식별자 (scope.yaml 의 groups.*.scopes[].id).

.PARAMETER Mode
  init      — 캐시 미존재 시 최초 전체 스캔
  full      — 전체 재스캔, 기존 캐시 덮어쓰기
  incremental — git diff 변경 파일만 부분 업데이트

.PARAMETER SubScopeParam
  하위 스코프 파라미터. 미지정 시 메인 스코프 전체.

.PARAMETER WorkspaceRoot
  워크스페이스 루트 (기본: pwd).

.PARAMETER MemoryRoot
  scopes/ 캐시 디렉토리 (기본: $HOME/.claude/projects/{workspace-slug}/memory).

.EXAMPLE
  powershell scan-module.ps1 -Scope ceremony -Mode init
  powershell scan-module.ps1 -Scope batch -Mode incremental
#>

param(
  [Parameter(Mandatory=$true)][string]$Scope,
  [ValidateSet('init','full','incremental')][string]$Mode = 'init',
  [string]$SubScopeParam,
  [string]$WorkspaceRoot = (Get-Location).Path,
  [string]$MemoryRoot
)

$ErrorActionPreference = 'Stop'

# --- 1. scope.yaml 파싱 (entry 추출) ---------------------------------------
$scopesFile = Join-Path $WorkspaceRoot '.claude/config/scope.yaml'
if (-not (Test-Path $scopesFile)) {
  throw "scope.yaml not found: $scopesFile"
}

$lines = Get-Content $scopesFile
$entry = @{
  id = $null; project = $null; sharedModule = $null; allowedPaths = @();
  groupKey = $null;
  subScope = $null  # @{ paramName, validatePath, allowedPaths[], scanPaths(@inherit-shared | @()), cacheFileSuffix }
}
$groupShared = @{}  # groupKey → @{ java=@(); javaRootFiles=@(); resources=@() }

$inEntry      = $false
$currentId    = $null
$currentGroup = $null
$inSubScope   = $false
$subAllowedCollecting = $false
$subScanCollecting    = $false
$inGroupShared        = $false
$groupSharedSection   = $null  # java | javaRootFiles | resources

foreach ($line in $lines) {
  # 그룹 헤더 (`  A:` 형태, 들여쓰기 2)
  if ($line -match '^\s{2}([A-Z]):\s*$') {
    $currentGroup = $matches[1]
    if (-not $groupShared.ContainsKey($currentGroup)) {
      $groupShared[$currentGroup] = @{ java = @(); javaRootFiles = @(); resources = @() }
    }
    $inEntry = $false
    $inSubScope = $false
    $inGroupShared = $false
    continue
  }
  # 그룹 단위 sharedCodeRange:
  if ($line -match '^\s{4}sharedCodeRange:\s*$') {
    $inGroupShared = $true; $groupSharedSection = $null; $inEntry = $false; $inSubScope = $false
    continue
  }
  if ($inGroupShared) {
    if ($line -match '^\s{6}(java|javaRootFiles|resources):\s*$') {
      $groupSharedSection = $matches[1]; continue
    }
    if ($line -match '^\s{8}-\s+(.+?)\s*$' -and $groupSharedSection -and $currentGroup) {
      $val = $matches[1].Trim().Trim('"').Trim("'")
      $groupShared[$currentGroup][$groupSharedSection] += $val
      continue
    }
    if ($line -match '^\s{0,4}\S' -and $line -notmatch '^\s*#') {
      $inGroupShared = $false; $groupSharedSection = $null
    }
  }

  if ($line -match '^\s*-\s+id:\s*(.+?)\s*$') {
    $currentId = $matches[1].Trim()
    $inEntry = ($currentId -eq $Scope)
    $inSubScope = $false
    $subAllowedCollecting = $false
    $subScanCollecting = $false
    if ($inEntry) {
      $entry.id = $currentId
      $entry.groupKey = $currentGroup
    }
    continue
  }

  if (-not $inEntry) { continue }

  # subScope 블록 진입
  if ($line -match '^\s{8}subScope:\s*$') {
    $inSubScope = $true
    $entry.subScope = @{ paramName = $null; validatePath = $null; allowedPaths = @(); scanPaths = $null; cacheFileSuffix = $null }
    continue
  }

  if ($inSubScope) {
    if ($line -match '^\s{10}paramName:\s*(.+?)\s*$') {
      $entry.subScope.paramName = $matches[1].Trim()
      continue
    }
    if ($line -match '^\s{10}validatePath:\s*"?(.+?)"?\s*$') {
      $entry.subScope.validatePath = $matches[1].Trim().Trim('"').Trim("'")
      continue
    }
    if ($line -match '^\s{10}allowedPaths:\s*$') {
      $subAllowedCollecting = $true; $subScanCollecting = $false; continue
    }
    if ($line -match '^\s{10}scanPaths:\s*"?@inherit-shared"?\s*$') {
      $entry.subScope.scanPaths = '@inherit-shared'
      $subAllowedCollecting = $false; $subScanCollecting = $false; continue
    }
    if ($line -match '^\s{10}scanPaths:\s*$') {
      $entry.subScope.scanPaths = @()
      $subScanCollecting = $true; $subAllowedCollecting = $false; continue
    }
    if ($line -match '^\s{10}cacheFileSuffix:\s*"?(.+?)"?\s*$') {
      $entry.subScope.cacheFileSuffix = $matches[1].Trim().Trim('"').Trim("'")
      continue
    }
    if ($subAllowedCollecting -and $line -match '^\s{12}-\s+(.+?)\s*$') {
      $entry.subScope.allowedPaths += $matches[1].Trim().Trim('"').Trim("'")
      continue
    }
    if ($subScanCollecting -and $line -match '^\s{12}-\s+(.+?)\s*$') {
      $entry.subScope.scanPaths += $matches[1].Trim().Trim('"').Trim("'")
      continue
    }
    # subScope 블록 종료 (들여쓰기 8 미만)
    if ($line -match '^\s{0,7}\S' -and $line -notmatch '^\s*#') {
      $inSubScope = $false; $subAllowedCollecting = $false; $subScanCollecting = $false
    }
  }

  if ($line -match '^\s{6,8}project:\s*(.+?)\s*$') {
    $entry.project = $matches[1].Trim()
  } elseif ($line -match '^\s{6,8}sharedModule:\s*(.+?)\s*$') {
    $val = $matches[1].Trim()
    if ($val -ne 'null') { $entry.sharedModule = $val }
  } elseif ($line -match '^\s{6,8}allowedPaths:\s*\[(.+?)\]\s*$') {
    $entry.allowedPaths = $matches[1] -split ',' | ForEach-Object { $_.Trim() -replace '"','' }
  } elseif ($line -match '^\s{0,4}\S' -and $line -notmatch '^\s*#' -and -not $inSubScope) {
    # 다음 entry 또는 그룹 시작 — 종료
    break
  }
}

if (-not $entry.project) {
  throw "Scope '$Scope' not found in scope.yaml"
}

if ($SubScopeParam -and -not $entry.subScope) {
  throw "Scope '$Scope' does not support subScope param (scope.yaml subScope 미정의)"
}

# --- 2. basePackagePath 추출 (project.yaml) ------------------------------
$wsFile = Join-Path $WorkspaceRoot '.claude/config/project.yaml'
$basePackagePath = 'com/beplepay/weadk/welfare'
if (Test-Path $wsFile) {
  $pattern = (Get-Content $wsFile) | Where-Object { $_ -match '^basePackagePattern:\s*(.+)$' } | Select-Object -First 1
  if ($pattern -match 'basePackagePattern:\s*(.+?)(\.\{module\})?\s*$') {
    $basePackagePath = $matches[1].Trim() -replace '\.', '/'
  }
}

# --- 3. 캐시 경로 결정 -----------------------------------------------------
if (-not $MemoryRoot) {
  # Claude Code 프로젝트 slug 계산: 워크스페이스 루트의 부모 경로를 슬래시→대시, 콜론→대시 변환
  $claudeProjectRoot = Split-Path $WorkspaceRoot -Parent
  $wsSlug = ($claudeProjectRoot -replace '\\', '-' -replace ':', '-')
  $MemoryRoot = Join-Path $HOME ".claude/projects/$wsSlug/memory"
}
$scopesCacheDir = Join-Path $MemoryRoot 'scopes'
if (-not (Test-Path $scopesCacheDir)) {
  New-Item -ItemType Directory -Path $scopesCacheDir -Force | Out-Null
}

$cacheFileName = if ($SubScopeParam) {
  if ($entry.subScope -and $entry.subScope.cacheFileSuffix) {
    $suffix = $entry.subScope.cacheFileSuffix -replace '\{paramValue\}', $SubScopeParam
    "$Scope$suffix.md"
  } else {
    "$Scope--$SubScopeParam.md"
  }
} else {
  "$Scope.md"
}
$cacheFile = Join-Path $scopesCacheDir $cacheFileName

# --- 4. 현재 브랜치 확인 ---------------------------------------------------
$projectPath = Join-Path $WorkspaceRoot $entry.project
$branch = '_unknown'
if (Test-Path (Join-Path $projectPath '.git')) {
  Push-Location $projectPath
  try {
    $branch = git branch --show-current 2>$null
    if ($branch) { $branch = $branch.Trim() }
    if (-not $branch) {
      $sha = git rev-parse --short HEAD 2>$null
      if ($sha) { $branch = "_detached_$($sha.Trim())" }
    }
  } finally { Pop-Location }
}

# --- 5. 스캔 대상 디렉토리 결정 --------------------------------------------
$scanDirs = @()
$srcMain = Join-Path $projectPath 'src/main/java'
$srcTest = Join-Path $projectPath 'src/test/java'
$srcResources = Join-Path $projectPath 'src/main/resources'

function Resolve-Vars {
  param([string]$Path, [string]$ParamValue, [string]$BasePackagePath)
  $r = $Path -replace '\{basePackagePath\}', $BasePackagePath
  if ($ParamValue) { $r = $r -replace '\{paramValue\}', $ParamValue }
  return $r
}

if ($SubScopeParam -and $entry.subScope) {
  # 하위 스코프 — subScope.allowedPaths + scanPaths 만 스캔
  foreach ($p in $entry.subScope.allowedPaths) {
    $resolved = Resolve-Vars -Path $p -ParamValue $SubScopeParam -BasePackagePath $basePackagePath
    $full = Join-Path $projectPath $resolved
    if (Test-Path $full) { $scanDirs += $full }
  }
  if ($entry.subScope.scanPaths -eq '@inherit-shared') {
    $gkey = $entry.groupKey
    if ($gkey -and $groupShared.ContainsKey($gkey)) {
      foreach ($jp in $groupShared[$gkey].java) {
        $full = Join-Path $projectPath "src/main/java/$basePackagePath/$($entry.id)/$jp"
        if (Test-Path $full) { $scanDirs += $full }
      }
      foreach ($jf in $groupShared[$gkey].javaRootFiles) {
        $full = Join-Path $projectPath "src/main/java/$basePackagePath/$($entry.id)/$jf"
        if (Test-Path $full) { $scanDirs += $full }
      }
      foreach ($rp in $groupShared[$gkey].resources) {
        $full = Join-Path $projectPath "src/main/resources/$rp"
        if (Test-Path $full) { $scanDirs += $full }
      }
    }
  } elseif ($entry.subScope.scanPaths -is [array]) {
    foreach ($p in $entry.subScope.scanPaths) {
      $resolved = Resolve-Vars -Path $p -ParamValue $SubScopeParam -BasePackagePath $basePackagePath
      $full = Join-Path $projectPath $resolved
      if (Test-Path $full) { $scanDirs += $full }
    }
  }
  $scanDirs = $scanDirs | Select-Object -Unique
} else {
  # 전체 스코프 — 기존 로직
  foreach ($p in $entry.allowedPaths) {
    if ($p -eq '**') {
      if (Test-Path $srcMain) { $scanDirs += $srcMain }
      if (Test-Path $srcTest) { $scanDirs += $srcTest }
    } else {
      $sub = Join-Path $projectPath $p
      $subSrc = Join-Path $sub 'src/main/java'
      if (Test-Path $subSrc) { $scanDirs += $subSrc }
      elseif (Test-Path $sub) { $scanDirs += $sub }
    }
  }
  if ($entry.sharedModule) {
    $sharedSrc = Join-Path $projectPath "$($entry.sharedModule)/src/main/java"
    if (Test-Path $sharedSrc) { $scanDirs += $sharedSrc }
  }
}

# --- 6. 스캔 실행 ---------------------------------------------------------
$javaFiles = @()
$mapperXmls = @()

if ($Mode -eq 'incremental') {
  Push-Location $projectPath
  try {
    $changed = git diff --name-only HEAD 2>$null
    foreach ($f in $changed) {
      $abs = Join-Path $projectPath $f
      if ($abs -match '\.java$' -and (Test-Path $abs)) { $javaFiles += $abs }
      if ($abs -match 'Mapper\.xml$' -and (Test-Path $abs)) { $mapperXmls += $abs }
    }
  } finally { Pop-Location }
} else {
  foreach ($d in $scanDirs) {
    $javaFiles += Get-ChildItem -Path $d -Recurse -Filter '*.java' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  }
  if (Test-Path $srcResources) {
    $mapperXmls += Get-ChildItem -Path $srcResources -Recurse -Filter '*Mapper.xml' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  }
}

# --- 7. 분류 카운트 -------------------------------------------------------
$counts = @{
  controller = 0; service = 0; serviceImpl = 0; mapper = 0;
  model = 0; config = 0; util = 0; other = 0
}
foreach ($f in $javaFiles) {
  $name = [IO.Path]::GetFileNameWithoutExtension($f)
  switch -Regex ($f) {
    '/controller/'                { $counts.controller++; break }
    '/service/impl/'              { $counts.serviceImpl++; break }
    '/service/'                   { $counts.service++; break }
    '/mapper/'                    { $counts.mapper++; break }
    '/(model|dto|vo|domain)/'     { $counts.model++; break }
    '/config/'                    { $counts.config++; break }
    '/util/'                      { $counts.util++; break }
    default                       { $counts.other++ }
  }
}

# --- 8. 캐시 파일 작성 ----------------------------------------------------
$now = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
$scopeId = if ($SubScopeParam) { "$Scope $SubScopeParam" } else { $Scope }

$content = @"
---
scope: $scopeId
scanned_at: $now
project_root: $($entry.project)
branch: $branch
mode: $Mode
---

## 스캔 결과 요약

- Java 파일: $($javaFiles.Count)개
- Mapper XML: $($mapperXmls.Count)개

## 패키지 분류

| 분류 | 카운트 |
|-----|-------|
| controller | $($counts.controller) |
| service (interface) | $($counts.service) |
| service (impl) | $($counts.serviceImpl) |
| mapper | $($counts.mapper) |
| model/dto/vo | $($counts.model) |
| config | $($counts.config) |
| util | $($counts.util) |
| other | $($counts.other) |

## 스캔 대상 경로

$($scanDirs | ForEach-Object { "- $($_.Replace($WorkspaceRoot + [IO.Path]::DirectorySeparatorChar, ''))" } | Out-String)

## 참고

- 상세 클래스 목록은 본 캐시에 저장하지 않는다 (토큰 절약).
- 필요 시 Grep/Glob 로 직접 조회 (예: ``Grep "class.*Controller" {projectRoot}/src/main/java/{basePackagePath}/{module}/controller``).
- 캐시 부분 업데이트는 ``-Mode incremental`` 사용.
"@

Set-Content -Path $cacheFile -Value $content -Encoding UTF8

Write-Output "📦 cache saved: $cacheFile"
Write-Output "   branch: $branch | java: $($javaFiles.Count) | mapper: $($mapperXmls.Count)"
