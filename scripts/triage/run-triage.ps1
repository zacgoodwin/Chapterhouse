# Task Scheduler entry for the issue-triage workflow (workflows/issue-triage.md).
# Runs the latent triage session headless, then writes the single authoritative
# run-log heartbeat line (the prompt is forbidden from writing it).
# Register: see scripts/triage/README note or workflows/issue-triage.md.
$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..\..')

$claude = "$env:USERPROFILE\.local\bin\claude.exe"
$prompt = Get-Content -Raw (Join-Path $PSScriptRoot 'prompt.md')
$log = 'workflows\briefs\triage-session.log'
New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null

"=== run $(Get-Date -Format o) ===" | Out-File -Append $log
# Only the four triage entry points — exact commands, not a directory prefix
# ('node scripts/' would also admit scripts/ship/deploy.mjs), and NO raw gh:
# even read-only 'gh issue view' accepts -R <any-repo> and would let a
# prompt-injected public issue read private repos with this host's
# credentials. context.mjs is the repo-pinned read surface.
$start = Get-Date
# Deterministic pre-count: a nonempty queue with no fresh brief afterwards is
# a FAILED run (silent stop/refusal), never 'queue-empty'. A queue-command or
# parse failure is itself a failed run — it must never masquerade as empty.
$queueCount = 0
try {
  $queueJson = node scripts/triage/queue.mjs
  if ($LASTEXITCODE -ne 0) { throw "queue.mjs exit=$LASTEXITCODE" }
  $queueCount = ($queueJson | ConvertFrom-Json).Count
} catch {
  node scripts/lib/runlog.mjs triage "FAILED queue snapshot: $_"
  node scripts/lib/notify.mjs 'Triage run FAILED' 'queue snapshot failed - see run-log'
  exit 1
}
& $claude -p $prompt --model claude-opus-5 `
  --allowedTools 'Bash(node scripts/triage/queue.mjs)' `
  'Bash(node scripts/triage/context.mjs:*)' `
  'Bash(node scripts/triage/apply.mjs:*)' `
  'Bash(node scripts/triage/write-brief.mjs:*)' `
  2>&1 | Out-File -Append $log
$exit = $LASTEXITCODE

# Brief counts only if THIS run wrote it — a same-day brief from an earlier
# run must not let a failed/empty later run report success. Same-date reruns
# get a -N suffix (write-brief uniquePath), so match the whole family.
$today = Get-Date -Format yyyy-MM-dd
$fresh = Get-ChildItem "workflows\briefs" -Filter "triage-$today*.md" -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -ge $start } | Select-Object -First 1
# Post-count: issues still in the queue after the run are either wontfix
# proposals (correct — they stay until approved) or missed work; surface the
# before/after so the heartbeat can't claim more than the session did.
$postCount = $queueCount
try { $postCount = ((node scripts/triage/queue.mjs) | ConvertFrom-Json).Count } catch {}
# Exact accounting: every issue from the pre-run snapshot must appear in the
# fresh brief AS A TICKET HEADING (triaged or wontfix-proposed), i.e. a line
# anchored '- **#N**'. A bare '#N' anywhere (e.g. 'blocked by #N' on another
# ticket's line) is NOT accounting — that spelling let a dropped issue pass.
$missing = @()
if ($fresh -and $queueCount -gt 0) {
  $briefNums = (Select-String -Path $fresh.FullName -Pattern '^\s*- \*\*#(\d+)\*\*' -AllMatches).Matches |
    ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object -Unique
  $missing = @(($queueJson | ConvertFrom-Json).number | Where-Object { $briefNums -notcontains $_ })
}
$outcome = if ($exit -ne 0) { "FAILED exit=$exit (see triage-session.log)" }
elseif ($fresh -and $missing.Count -gt 0) { "FAILED brief omits issues: $($missing -join ', ')"; $exit = 1 }
elseif ($fresh) { "ok brief=$($fresh.Name) queue $queueCount->$postCount" }
elseif ($queueCount -gt 0) { "FAILED queue=$queueCount but no brief written (see triage-session.log)"; $exit = 1 }
else { 'ok queue-empty' }
node scripts/lib/runlog.mjs triage $outcome
if ($exit -ne 0) { node scripts/lib/notify.mjs 'Triage run FAILED' "$outcome" }
# Task Scheduler must record the session's real result, not the notify's.
exit $exit
