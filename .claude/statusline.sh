#!/bin/bash
# Claude Code statusline — we-adk-welfare
# 표시: ctx % | 5h X% · 7d Y% | effort | [model] project @ branch ✱
# 입력: stdin JSON (context_window, rate_limits, effort, model, workspace 사용)
#
# 파싱은 python 으로 — sed 로 nested 객체에서 동일 키(`used_percentage`)를 정확히 잡기 어렵고
# 다른 hook 들이 이미 python 을 쓰고 있어 일관성 유지.

INPUT=$(cat)

# 워크스페이스 루트 폴백 (project_dir 누락 시): 스크립트 위치 기반
WS_FALLBACK="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -W 2>/dev/null)"
[ -z "$WS_FALLBACK" ] && WS_FALLBACK="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"

# Python 코드는 변수에 담아 -c 로 전달 (stdin 은 파이프로 JSON 전달 — heredoc 사용 불가)
PY_CODE=$(cat <<'PYEOF'
import json, sys, re, os, subprocess

ws_fallback = sys.argv[1] if len(sys.argv) > 1 else ""

try:
	d = json.loads(sys.stdin.read())
except Exception:
	sys.exit(0)

cw = d.get("context_window") or {}
rl = d.get("rate_limits") or {}
model = d.get("model") or {}
ws = d.get("workspace") or {}
eff = d.get("effort") or {}

ctx_pct = int(cw.get("used_percentage", 0) or 0)
ctx_size = int(cw.get("context_window_size", 0) or 0)
rl_5h = int((rl.get("five_hour") or {}).get("used_percentage", 0) or 0)
rl_7d = int((rl.get("seven_day") or {}).get("used_percentage", 0) or 0)
effort = (eff.get("level") or "").strip()

def fmt_size(n):
	if n >= 1_000_000:
		v = n / 1_000_000
		return f"{int(v)}M" if v == int(v) else f"{v:.1f}M"
	if n >= 1_000:
		v = n / 1_000
		return f"{int(v)}K" if v == int(v) else f"{v:.1f}K"
	return str(n) if n else ""

display_raw = model.get("display_name", "?") or "?"
display = re.sub(r"\s*\(.*\)$", "", display_raw).strip() or "?"

cwd = (ws.get("current_dir") or "").strip()
ws_root = (ws.get("project_dir") or "").strip() or ws_fallback or cwd

if not cwd or cwd == ws_root:
	project = "(workspace)"
else:
	project = os.path.basename(cwd.rstrip("/\\")) or "(workspace)"

branch = ""
dirty = ""
if cwd and os.path.isdir(os.path.join(cwd, ".git")):
	try:
		r = subprocess.run(["git", "-C", cwd, "branch", "--show-current"],
		                   capture_output=True, text=True, timeout=2)
		branch = r.stdout.strip()
	except Exception:
		pass
	try:
		r = subprocess.run(["git", "-C", cwd, "status", "--porcelain"],
		                   capture_output=True, text=True, timeout=2)
		if r.stdout.strip():
			dirty = "✱"
	except Exception:
		pass

def threshold_color(pct, txt):
	if pct >= 90:
		return f"\033[1;31m{txt}\033[0m"
	if pct >= 70:
		return f"\033[1;33m{txt}\033[0m"
	return txt

ctx_size_str = fmt_size(ctx_size)
ctx_label = f"{ctx_pct}% ctx ({ctx_size_str})" if ctx_size_str else f"{ctx_pct}% ctx"
ctx_str = threshold_color(ctx_pct, ctx_label)
rl_5h_str = threshold_color(rl_5h, f"5h {rl_5h}%")
rl_7d_str = threshold_color(rl_7d, f"7d {rl_7d}%")
rl_str = f"{rl_5h_str} · {rl_7d_str}"
effort_str = f"\033[2m{effort}\033[0m" if effort else ""

ws_part = f"[{display}] {project}"
if branch:
	ws_part += f" @ {branch}{dirty}"

segments = [ctx_str, rl_str]
if effort_str:
	segments.append(effort_str)
segments.append(ws_part)

print(" | ".join(segments))
PYEOF
)

# Windows 한국어 로케일 콘솔 인코딩(cp949) 이 ·, • 등을 못 매핑하므로 UTF-8 강제
export PYTHONIOENCODING=utf-8
printf '%s' "$INPUT" | python -c "$PY_CODE" "$WS_FALLBACK"
