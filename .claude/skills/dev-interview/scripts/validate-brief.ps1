<#
.SYNOPSIS
  dev-interview Stage 1 형식 게이트 결정론 검증기.

.DESCRIPTION
  11섹션 개발 브리프(`target/works/{과업번호}_dev_brief.md`) 의 출력 계약을
  references/brief-schema.md 의 self-check 항목에 따라 결정론 검증한다.

  AI 추론에 맡기던 self-check 를 regex/grep 기반 검증으로 전환하여
  동일 입력 → 동일 PASS/FAIL 결과 보장.

  검증 항목:
    1) §1 ~ §11 헤더 모두 존재 + 순서
    2) §1 문서 메타 표 7행 (기획서 파일·버전·품질등급·인터뷰일자·과업번호·작업 브랜치·제안 개발 기간)
    3) §2 시스템 결정 6행 (개발 유형·프로젝트 유형·프로젝트명·베이스 패키지·배포 포맷·빌드)
    4) §3 하위 절 (3-1, 3-2, 3-3, 3-4)
    5) §9 미결사항 비어있지 않음
    6) §11 Phase ≥ 3 (또는 단계 ≥ 3)
    7) "TBD" / "추후 결정" 표현 없음 (§1 작업 브랜치 "미정" 제외)
    8) 메타 footer (선탐색 시간·인터뷰 라운드·Codex 검토 등급)

.PARAMETER BriefFile
  검증 대상 브리프 마크다운 경로.

.OUTPUTS
  JSON: { pass: bool, checks: [...], failed: n }

.EXAMPLE
  powershell .claude/skills/dev-interview/scripts/validate-brief.ps1 -BriefFile target/works/057_dev_brief.md
#>

param(
  [Parameter(Mandatory=$true)][string]$BriefFile
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $BriefFile)) {
  throw "Brief file not found: $BriefFile"
}

$content = Get-Content $BriefFile -Raw
$lines   = $content -split "`r?`n"

$checks = @()
$failed = 0

function Add-Check {
  param([string]$Id, [string]$Name, [bool]$Pass, [string]$Detail = '')
  $script:checks += [PSCustomObject]@{
    id     = $Id
    name   = $Name
    pass   = $Pass
    detail = $Detail
  }
  if (-not $Pass) { $script:failed++ }
}

# --- 1. §1 ~ §11 헤더 순서 ---------------------------------------------------
$sectionHeaders = @()
foreach ($l in $lines) {
  if ($l -match '^## (\d+)\.\s') {
    $sectionHeaders += [int]$matches[1]
  }
}
$expected = 1..11
$missing  = @($expected | Where-Object { $sectionHeaders -notcontains $_ })
$ordered  = ($sectionHeaders -join ',') -eq ($expected -join ',').Substring(0, ($sectionHeaders -join ',').Length)
Add-Check 'SEC_HEADERS' '§1 ~ §11 헤더 존재 + 순서' (($missing.Count -eq 0) -and $ordered) `
  ("missing=$($missing -join ',') headers=$($sectionHeaders -join ',')")

# --- 2. §1 문서 메타 7항목 ---------------------------------------------------
$metaKeys = @('기획서 파일','기획서 버전','기획서 품질 등급','인터뷰 일자','과업번호','작업 브랜치','제안 개발 기간')
$missingMeta = @()
foreach ($k in $metaKeys) {
  if (-not (Select-String -InputObject $content -Pattern ([regex]::Escape("| $k |")) -Quiet) -and
      -not (Select-String -InputObject $content -Pattern ([regex]::Escape("| $k ")) -Quiet)) {
    $missingMeta += $k
  }
}
Add-Check 'META_TABLE' '§1 문서 메타 7항목' ($missingMeta.Count -eq 0) ("missing=$($missingMeta -join ',')")

# --- 3. §2 시스템 결정 6항목 -------------------------------------------------
$sysKeys = @('개발 유형','프로젝트 유형','프로젝트명','베이스 패키지','배포 포맷','빌드')
$missingSys = @()
foreach ($k in $sysKeys) {
  if (-not (Select-String -InputObject $content -Pattern ([regex]::Escape("| $k ")) -Quiet)) {
    $missingSys += $k
  }
}
Add-Check 'SYSTEM_TABLE' '§2 시스템 결정 6항목' ($missingSys.Count -eq 0) ("missing=$($missingSys -join ',')")

# --- 4. §3 하위 절 4개 -------------------------------------------------------
$subSections = @('3-1','3-2','3-3','3-4')
$missingSub = @()
foreach ($s in $subSections) {
  if (-not (Select-String -InputObject $content -Pattern "^### $s\." -Quiet)) {
    $missingSub += $s
  }
}
Add-Check 'SCOPE_SUBSECTIONS' '§3 Primary/Related/패턴/영향 하위 절' ($missingSub.Count -eq 0) ("missing=$($missingSub -join ',')")

# --- 5. §9 미결사항 비어있지 않음 -------------------------------------------
$sec9Idx = -1; $sec10Idx = $lines.Count
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^## 9\.\s') { $sec9Idx = $i }
  elseif ($lines[$i] -match '^## 10\.\s' -and $sec9Idx -ge 0) { $sec10Idx = $i; break }
}
$sec9HasContent = $false
if ($sec9Idx -ge 0) {
  for ($i = $sec9Idx + 1; $i -lt $sec10Idx; $i++) {
    if ($lines[$i].Trim() -ne '' -and $lines[$i] -notmatch '^##') {
      $sec9HasContent = $true; break
    }
  }
}
Add-Check 'OPEN_QUESTIONS' '§9 미결사항 비어있지 않음' $sec9HasContent ''

# --- 6. §11 Phase ≥ 3 단계 --------------------------------------------------
$sec11Idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^## 11\.\s') { $sec11Idx = $i; break }
}
$phaseCount = 0
if ($sec11Idx -ge 0) {
  for ($i = $sec11Idx + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## ') { break }
    if ($lines[$i] -match '^\s*\d+\.\s' -or $lines[$i] -match '(?i)Phase\s*\d+' -or $lines[$i] -match '^\s*-\s+\d+단계') {
      $phaseCount++
    }
  }
}
Add-Check 'IMPL_PHASES' '§11 Phase/단계 ≥ 3' ($phaseCount -ge 3) "count=$phaseCount"

# --- 7. TBD / 추후 결정 금지 -------------------------------------------------
$forbidden = @()
$tbdMatches = [regex]::Matches($content, '(?i)\bTBD\b|추후\s*결정')
foreach ($m in $tbdMatches) {
  $idx = $m.Index
  $lineNum = ($content.Substring(0, $idx) -split "`n").Count
  $lineContent = $lines[$lineNum - 1]
  # §1 작업 브랜치 "미정" 은 OK 이지만 TBD/추후 결정은 모두 위반
  $forbidden += "line $lineNum"
}
Add-Check 'NO_TBD' '"TBD" / "추후 결정" 표현 없음' ($forbidden.Count -eq 0) ("hits=$($forbidden -join '; ')")

# --- 8. 메타 footer ----------------------------------------------------------
$hasExploreTime = (Select-String -InputObject $content -Pattern '선탐색 시간' -Quiet)
$hasRounds      = (Select-String -InputObject $content -Pattern '인터뷰 라운드' -Quiet)
$hasReview      = (Select-String -InputObject $content -Pattern '검토 등급' -Quiet)
Add-Check 'META_FOOTER' '메타 footer (선탐색·라운드·검토 등급)' ($hasExploreTime -and $hasRounds -and $hasReview) `
  ("explore=$hasExploreTime rounds=$hasRounds review=$hasReview")

# --- 9. 부록 Q&A 로그 --------------------------------------------------------
$hasAppendix = (Select-String -InputObject $content -Pattern '^## 인터뷰 Q&A 로그' -Quiet) -or
               (Select-String -InputObject $content -Pattern '^## .*Q&A.*부록' -Quiet)
Add-Check 'QNA_APPENDIX' 'Q&A 로그 부록 첨부' $hasAppendix ''

# --- 출력 -------------------------------------------------------------------
$result = [ordered]@{
  pass     = ($failed -eq 0)
  checks   = $checks
  failed   = $failed
  file     = (Resolve-Path $BriefFile).Path
}
$result | ConvertTo-Json -Depth 5 -Compress
