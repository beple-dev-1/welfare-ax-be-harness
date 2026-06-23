<#
.SYNOPSIS
  code-review STEP 1 severity 결정론 스캐너.

.DESCRIPTION
  references/severity-rules.md 의 keywords 컬럼을 파싱하여 diff 본문에
  대조하고 매칭 결과(ID·severity·파일·라인·키워드)를 JSON 으로 출력한다.

  AI 추론 대신 deterministic grep 으로 동일 입력 → 동일 출력 보장.
  STEP 0(incident-antipatterns IC/IW) 와 STEP 2(휴리스틱) 는 LLM 책임.
  본 script 는 STEP 1 pattern_table 매칭만 담당한다.

.PARAMETER DiffFile
  diff 본문 파일 경로 (`git diff --staged > diff.txt` 결과).

.PARAMETER RulesFile
  severity-rules.md 경로. 기본: $PSScriptRoot/../references/severity-rules.md

.PARAMETER OutFormat
  json | tsv (기본 json)

.EXAMPLE
  git diff --staged | Out-File -Encoding utf8 .tmp/diff.txt
  powershell .claude/skills/code-review/scripts/severity-scan.ps1 -DiffFile .tmp/diff.txt
#>

param(
  [Parameter(Mandatory=$true)][string]$DiffFile,
  [string]$RulesFile,
  [ValidateSet('json','tsv')][string]$OutFormat = 'json'
)

$ErrorActionPreference = 'Stop'

if (-not $RulesFile) {
  $RulesFile = Join-Path $PSScriptRoot '..\references\severity-rules.md'
}
if (-not (Test-Path $RulesFile)) {
  throw "severity-rules.md not found: $RulesFile"
}
if (-not (Test-Path $DiffFile)) {
  throw "diff file not found: $DiffFile"
}

# --- 1. severity-rules.md 표 파싱 ------------------------------------------
$rules = @()
$section = $null
foreach ($line in Get-Content $RulesFile) {
  if ($line -match '^##\s+(Critical|Warning|Suggestion)\s*$') {
    $section = $matches[1]
    continue
  }
  if (-not $section) { continue }
  if ($line -notmatch '^\|\s*[CWS]\d{2}') { continue }
  $cols = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
  if ($cols.Count -lt 4) { continue }
  $id        = $cols[0]
  $name      = $cols[1]
  $kwBlob    = $cols[2]
  $keywords  = $kwBlob -split ',' | ForEach-Object {
    ($_ -replace '`','').Trim()
  } | Where-Object { $_ -ne '' }
  $rules += [PSCustomObject]@{
    id       = $id
    severity = $section
    name     = $name
    keywords = $keywords
  }
}

# --- 2. diff 본문 → 변경 파일별 추가/수정 라인 추출 ------------------------
$diffLines = Get-Content $DiffFile
$currentFile = $null
$lineNo = 0
$entries = @()   # @{file, line, text}
foreach ($l in $diffLines) {
  if ($l -match '^\+\+\+ b/(.+)$') {
    $currentFile = $matches[1]
    $lineNo = 0
    continue
  }
  if ($l -match '^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@') {
    $lineNo = [int]$matches[1] - 1
    continue
  }
  if (-not $currentFile) { continue }
  if ($l.StartsWith('+') -and -not $l.StartsWith('+++')) {
    $lineNo++
    $entries += [PSCustomObject]@{
      file = $currentFile
      line = $lineNo
      text = $l.Substring(1)
    }
  } elseif (-not $l.StartsWith('-')) {
    $lineNo++
  }
}

# --- 3. 매칭 ---------------------------------------------------------------
$hits = @()
foreach ($e in $entries) {
  foreach ($r in $rules) {
    foreach ($kw in $r.keywords) {
      if ([string]::IsNullOrWhiteSpace($kw)) { continue }
      $escaped = [regex]::Escape($kw)
      if ($e.text -match $escaped) {
        $hits += [PSCustomObject]@{
          id        = $r.id
          severity  = $r.severity
          name      = $r.name
          file      = $e.file
          line      = $e.line
          keyword   = $kw
          snippet   = $e.text.Trim().Substring(0, [Math]::Min(120, $e.text.Trim().Length))
        }
        break
      }
    }
  }
}

# --- 4. 출력 ---------------------------------------------------------------
if ($OutFormat -eq 'tsv') {
  "id`tseverity`tname`tfile`tline`tkeyword`tsnippet"
  foreach ($m in $hits) {
    "$($m.id)`t$($m.severity)`t$($m.name)`t$($m.file)`t$($m.line)`t$($m.keyword)`t$($m.snippet)"
  }
} else {
  $hits | ConvertTo-Json -Depth 4 -Compress
}
