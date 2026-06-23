<#
.SYNOPSIS
  pack 0단계(P2) — stale 프로젝트 섹션 자동 보존 결정론 처리기.

.DESCRIPTION
  워크스페이스 루트 HANDOFF.md 의 frontmatter projects: 표를 파싱하고
  각 프로젝트의 현재 git 브랜치와 비교하여 stale 섹션을 추출한다.
  추출된 진행중 컨텍스트는 HANDOFF_HISTORY.md 에 prepend 되고
  HANDOFF.md 의 해당 섹션은 제거된다.

  AI 추론 대신 deterministic parsing 으로 동일 입력 → 동일 출력 보장.

  처리 흐름:
    1) HANDOFF.md frontmatter 의 projects: 표 파싱
    2) 각 프로젝트 git branch --show-current 비교
    3) 불일치(stale) 프로젝트별로:
       - HANDOFF.md 의 `## {project} @ \`{branch}\`` 섹션 추출
       - `### Plan` / `### Next` / `### Caution` 만 보존하여 HISTORY entry 작성
       - HANDOFF.md 에서 해당 섹션 제거
    4) HISTORY `## ` 헤더 수 카운트 → 100 초과 시 안내 플래그

.PARAMETER WorkspaceRoot
  워크스페이스 루트 (기본: pwd).

.PARAMETER DryRun
  파일 수정 없이 처리 계획만 JSON 출력.

.OUTPUTS
  JSON: { stale: [...], preserved: n, historyTotal: n, overflow: bool, dryRun: bool }

.EXAMPLE
  powershell .claude/skills/pack/scripts/pack-stale.ps1
  powershell .claude/skills/pack/scripts/pack-stale.ps1 -DryRun
#>

param(
  [string]$WorkspaceRoot = (Get-Location).Path,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$handoffFile = Join-Path $WorkspaceRoot 'HANDOFF.md'
$historyFile = Join-Path $WorkspaceRoot 'HANDOFF_HISTORY.md'

$result = [ordered]@{
  stale         = @()
  preserved     = 0
  historyTotal  = 0
  overflow      = $false
  dryRun        = [bool]$DryRun
}

if (-not (Test-Path $handoffFile)) {
  $result | ConvertTo-Json -Depth 5 -Compress
  return
}

# -Encoding utf8 강제: BOM 없는 UTF-8 파일을 PS 5.1 이 ANSI(CP949)로 오독해 mojibake 되는 것을 방지.
$content = Get-Content $handoffFile -Raw -Encoding utf8
$lines   = $content -split "`r?`n"

# --- 1. frontmatter projects: 표 파싱 ---------------------------------------
$fmStart = -1; $fmEnd = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -eq '---') {
    if ($fmStart -lt 0) { $fmStart = $i; continue }
    $fmEnd = $i; break
  }
}
if ($fmStart -lt 0 -or $fmEnd -lt 0) {
  $result | ConvertTo-Json -Depth 5 -Compress
  return
}

$projects = @{}
$inProjects = $false
for ($i = $fmStart + 1; $i -lt $fmEnd; $i++) {
  $l = $lines[$i]
  if ($l -match '^projects:\s*$') { $inProjects = $true; continue }
  if ($l -match '^\S' -and $inProjects) { $inProjects = $false }
  if (-not $inProjects) { continue }
  if ($l -match '^\s*-\s+([^:]+):\s*(.+?)\s*$') {
    $projects[$matches[1].Trim()] = $matches[2].Trim()
  }
}

if ($projects.Count -eq 0) {
  $result | ConvertTo-Json -Depth 5 -Compress
  return
}

# --- 2. 현재 git 브랜치 비교 ------------------------------------------------
$staleList = @()
foreach ($p in $projects.Keys) {
  $recordedBranch = $projects[$p]
  $projectPath = Join-Path $WorkspaceRoot $p
  if (-not (Test-Path (Join-Path $projectPath '.git'))) { continue }
  Push-Location $projectPath
  try {
    $curBranch = "$(git branch --show-current 2>$null)".Trim()
    if (-not $curBranch) {
      $sha = "$(git rev-parse --short HEAD 2>$null)".Trim()
      if ($sha) { $curBranch = "_detached_$sha" } else { $curBranch = '_unknown' }
    }
  } finally { Pop-Location }
  if ($curBranch -ne $recordedBranch) {
    $staleList += [PSCustomObject]@{
      project        = $p
      recordedBranch = $recordedBranch
      currentBranch  = $curBranch
    }
  }
}

if ($staleList.Count -eq 0) {
  # HISTORY 헤더 카운트만 수행
  if (Test-Path $historyFile) {
    $headers = (Select-String -Path $historyFile -Pattern '^## ' -CaseSensitive).Count
    $result.historyTotal = $headers
    $result.overflow = ($headers -gt 100)
  }
  $result | ConvertTo-Json -Depth 5 -Compress
  return
}

# --- 3. stale 섹션 추출 -----------------------------------------------------
function Extract-Section {
  param([string[]]$AllLines, [string]$Project, [string]$Branch)
  $headerRegex = "^##\s+$([regex]::Escape($Project))\s+@\s+``$([regex]::Escape($Branch))``\s*$"
  $startIdx = -1; $endIdx = $AllLines.Count
  for ($i = 0; $i -lt $AllLines.Count; $i++) {
    if ($AllLines[$i] -match $headerRegex) { $startIdx = $i; break }
  }
  if ($startIdx -lt 0) { return $null }
  for ($i = $startIdx + 1; $i -lt $AllLines.Count; $i++) {
    if ($AllLines[$i] -match '^##\s+\S') { $endIdx = $i; break }
  }
  return @{ start = $startIdx; end = $endIdx; lines = $AllLines[$startIdx..($endIdx - 1)] }
}

function Get-SubSection {
  param([string[]]$SectionLines, [string]$SubHeader)
  $startIdx = -1; $endIdx = $SectionLines.Count
  for ($i = 0; $i -lt $SectionLines.Count; $i++) {
    if ($SectionLines[$i] -match "^###\s+$([regex]::Escape($SubHeader))\s*$") { $startIdx = $i + 1; break }
  }
  if ($startIdx -lt 0) { return @() }
  for ($i = $startIdx; $i -lt $SectionLines.Count; $i++) {
    if ($SectionLines[$i] -match '^(##|###)\s+\S') { $endIdx = $i; break }
  }
  return $SectionLines[$startIdx..($endIdx - 1)] |
    Where-Object { $_ -notmatch '^\s*$' -or $true } # 빈줄 보존
}

$historyEntries = @()
$removeRanges   = @()
# KST 고정 (UTC+9, DST 없음). 로컬 머신 TZ 비의존 — external-ready.
$now = (Get-Date).ToUniversalTime().AddHours(9).ToString("yyyy-MM-ddTHH:mm") + "+09:00"

foreach ($s in $staleList) {
  $sec = Extract-Section -AllLines $lines -Project $s.project -Branch $s.recordedBranch
  if (-not $sec) { continue }

  $planLines    = Get-SubSection -SectionLines $sec.lines -SubHeader 'Plan'
  $nextLines    = Get-SubSection -SectionLines $sec.lines -SubHeader 'Next'
  $cautionLines = Get-SubSection -SectionLines $sec.lines -SubHeader 'Caution'

  $entry = New-Object System.Text.StringBuilder
  [void]$entry.AppendLine("## $now — $($s.project) @ $($s.recordedBranch)")
  [void]$entry.AppendLine("")
  [void]$entry.AppendLine("### In-progress (snapshot)")
  if ($planLines.Count -gt 0) {
    [void]$entry.AppendLine("**Plan**:")
    foreach ($pl in $planLines) { [void]$entry.AppendLine($pl) }
  }
  if ($nextLines.Count -gt 0) {
    [void]$entry.AppendLine("**Next**:")
    foreach ($nl in $nextLines) { [void]$entry.AppendLine($nl) }
  }
  if ($cautionLines.Count -gt 0) {
    [void]$entry.AppendLine("**Caution**:")
    foreach ($cl in $cautionLines) { [void]$entry.AppendLine($cl) }
  }
  [void]$entry.AppendLine("")
  [void]$entry.AppendLine("---")
  [void]$entry.AppendLine("")

  $historyEntries += $entry.ToString()
  $removeRanges   += @{ start = $sec.start; end = $sec.end; project = $s.project }
  $result.stale   += [PSCustomObject]@{
    project        = $s.project
    recordedBranch = $s.recordedBranch
    currentBranch  = $s.currentBranch
  }
}

# --- 4. HANDOFF.md 에서 stale 섹션 제거 + HISTORY prepend -------------------
if (-not $DryRun -and $removeRanges.Count -gt 0) {
  $keep = New-Object System.Collections.Generic.List[string]
  $removeSet = @{}
  foreach ($r in $removeRanges) {
    for ($k = $r.start; $k -lt $r.end; $k++) { $removeSet[$k] = $true }
  }
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if (-not $removeSet.ContainsKey($i)) { $keep.Add($lines[$i]) }
  }
  # frontmatter projects: 표에서 stale 프로젝트 제거
  $cleanedLines = New-Object System.Collections.Generic.List[string]
  $skipStale = $false
  foreach ($line in $keep) {
    $skipLine = $false
    foreach ($s in $staleList) {
      if ($line -match "^\s*-\s+$([regex]::Escape($s.project)):\s+") { $skipLine = $true; break }
    }
    if (-not $skipLine) { $cleanedLines.Add($line) }
  }
  $newContent = [string]::Join("`r`n", $cleanedLines)
  Set-Content -Path $handoffFile -Value $newContent -Encoding utf8 -NoNewline

  $existingHistory = if (Test-Path $historyFile) { Get-Content $historyFile -Raw -Encoding utf8 } else { '' }
  $prepend = ($historyEntries -join '')
  Set-Content -Path $historyFile -Value ($prepend + $existingHistory) -Encoding utf8 -NoNewline
}

$result.preserved = $historyEntries.Count

# --- 5. HISTORY 헤더 카운트 ------------------------------------------------
if (Test-Path $historyFile) {
  $headers = (Select-String -Path $historyFile -Pattern '^## ' -CaseSensitive).Count
  $result.historyTotal = $headers
  $result.overflow = ($headers -gt 100)
}

$result | ConvertTo-Json -Depth 5 -Compress
