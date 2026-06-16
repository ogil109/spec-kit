#!/usr/bin/env pwsh
# blueprint-state — deterministic state oracle for the waterfall harness (PowerShell port).
# Mirrors scripts/bash/blueprint-state.sh.
#
# Usage:
#   blueprint-state.ps1 status
#   blueprint-state.ps1 next [--json]
#   [--root <dir>] [--blueprint <path>]
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string]$Command = "status",
  [Parameter(ValueFromRemainingArguments = $true)] [string[]]$Rest
)
$ErrorActionPreference = "Stop"

$Json = $false; $Root = ""; $Blueprint = ""
for ($i = 0; $i -lt $Rest.Count; $i++) {
  switch ($Rest[$i]) {
    "--json"      { $Json = $true }
    "--root"      { $i++; $Root = $Rest[$i] }
    "--blueprint" { $i++; $Blueprint = $Rest[$i] }
  }
}

# locate repo root
if (-not $Root) {
  $d = (Get-Location).Path
  while ($d -and (Split-Path $d -Parent)) {
    if (Test-Path (Join-Path $d ".specify")) { $Root = $d; break }
    $d = Split-Path $d -Parent
  }
  if (-not $Root) { $Root = (Get-Location).Path }
}

# locate blueprint
if (-not $Blueprint) {
  $cfg = Join-Path $Root ".specify/extensions/blueprint/blueprint-config.yml"
  if (Test-Path $cfg) {
    $m = Select-String -Path $cfg -Pattern '^\s*path:\s*"?([^"]*)"?\s*$' | Select-Object -First 1
    if ($m) { $Blueprint = Join-Path $Root $m.Matches[0].Groups[1].Value }
  }
}
if (-not $Blueprint -or -not (Test-Path $Blueprint)) {
  foreach ($c in @("docs/blueprint.md", "docs/overview.md", ".specify/memory/blueprint.md")) {
    if (Test-Path (Join-Path $Root $c)) { $Blueprint = Join-Path $Root $c; break }
  }
}

$specsDir = Join-Path $Root "specs"

function Get-SpecPhase($dir) {
  if (-not (Test-Path (Join-Path $dir "spec.md"))) { return "specify" }
  if (Select-String -Path (Join-Path $dir "spec.md") -Pattern '\[NEEDS CLARIFICATION' -Quiet) { return "clarify" }
  if (-not (Test-Path (Join-Path $dir "plan.md")))  { return "plan" }
  if (-not (Test-Path (Join-Path $dir "tasks.md"))) { return "tasks" }
  if (Select-String -Path (Join-Path $dir "tasks.md") -Pattern '^\s*-\s*\[ \]' -Quiet) { return "implement" }
  return "built"
}
function Test-Distilled($slug) {
  if (-not ($Blueprint -and (Test-Path $Blueprint))) { return $false }
  return [bool](Select-String -Path $Blueprint -Pattern "specs/$slug" -Quiet)
}

$inflight = @(); $drift = @(); $builtCount = 0
if (Test-Path $specsDir) {
  foreach ($dir in (Get-ChildItem -Path $specsDir -Directory)) {
    $slug = $dir.Name
    $phase = Get-SpecPhase $dir.FullName
    if ($phase -ne "built") { $inflight += [pscustomobject]@{ slug = $slug; phase = $phase } }
    else { $builtCount++ }
    if (-not (Test-Distilled $slug)) { $drift += $slug }
  }
}

$nextPhase = "done"; $nextSlug = ""; $reason = "backlog empty — nothing in specs/, nothing in flight"
if ($drift.Count -gt 0) {
  $nextPhase = "distill"; $nextSlug = $drift[0]; $reason = "spec exists but blueprint still holds its detail"
} elseif ($inflight.Count -gt 0) {
  $nextPhase = $inflight[0].phase; $nextSlug = $inflight[0].slug; $reason = "in-flight slice; next build phase by artifact frontier"
} elseif ($Blueprint -and (Test-Path $Blueprint)) {
  $nextPhase = "specify"; $reason = "no in-flight work; specify the next detailed subsystem from the blueprint"
}
$hasNext = ($nextPhase -ne "done")

if ($Command -eq "next") {
  if ($Json) {
    $rel = if ($Blueprint) { $Blueprint.Replace("$Root/", "").Replace("$Root\", "") } else { "" }
    '{{"has_next": {0}, "phase": "{1}", "slug": "{2}", "reason": "{3}", "blueprint": "{4}"}}' -f `
      $hasNext.ToString().ToLower(), $nextPhase, $nextSlug, $reason, $rel
  } else {
    "next: $nextPhase $(if($nextSlug){"($nextSlug)"}) — $reason"
  }
  exit 0
}

Write-Output "Blueprint waterfall — state"
Write-Output "  root:      $Root"
Write-Output "  blueprint: $(if($Blueprint){$Blueprint}else{'<none — run blueprint.init>'}) ($builtCount built, $($inflight.Count) in-flight)"
Write-Output ""
Write-Output "In-flight (spec exists, build not complete):"
if ($inflight.Count -eq 0) { Write-Output "  (none)" } else { $inflight | ForEach-Object { Write-Output "  - $($_.slug)  → next: $($_.phase)" } }
Write-Output ""
Write-Output "Distill drift (spec exists, blueprint not yet collapsed):"
if ($drift.Count -eq 0) { Write-Output "  (none — blueprint in sync)" } else { $drift | ForEach-Object { Write-Output "  - $_  → /speckit.blueprint.distill $_" } }
Write-Output ""
Write-Output "Next action: $nextPhase $(if($nextSlug){"($nextSlug)"})"
Write-Output "  ($reason)"
