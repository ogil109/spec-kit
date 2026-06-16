#!/usr/bin/env bash
# blueprint-state — the deterministic state oracle for the waterfall harness.
#
# Computes, purely from the filesystem (specs/ = ground truth, the blueprint doc
# = the index), the next actionable step in the waterfall. No LLM judgment in the
# parts that must be reliable across a long unattended run.
#
# Usage:
#   blueprint-state.sh status                 # human-readable worklist
#   blueprint-state.sh next [--json]          # the single next action (drives the loop)
#
# Env / args:
#   --root <dir>        repo root (default: search upward for .specify, else cwd)
#   --blueprint <path>  blueprint doc (default: from config, else docs/overview.md
#                       or docs/blueprint.md or .specify/memory/blueprint.md)
set -euo pipefail

ROOT=""
BLUEPRINT=""
CMD="${1:-status}"; shift || true
JSON=0
while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON=1 ;;
    --root) ROOT="$2"; shift ;;
    --blueprint) BLUEPRINT="$2"; shift ;;
  esac
  shift
done

# ── locate repo root ──────────────────────────────────────────────────────────
if [ -z "$ROOT" ]; then
  d="$(pwd)"
  while [ "$d" != "/" ]; do
    [ -d "$d/.specify" ] && ROOT="$d" && break
    d="$(dirname "$d")"
  done
  [ -z "$ROOT" ] && ROOT="$(pwd)"
fi

# ── locate the blueprint doc ──────────────────────────────────────────────────
if [ -z "$BLUEPRINT" ]; then
  cfg="$ROOT/.specify/extensions/blueprint/blueprint-config.yml"
  if [ -f "$cfg" ]; then
    p=$(grep -E '^\s*path:' "$cfg" | head -1 | sed -E 's/^\s*path:\s*"?([^"]*)"?\s*$/\1/')
    [ -n "$p" ] && BLUEPRINT="$ROOT/$p"
  fi
fi
if [ -z "$BLUEPRINT" ] || [ ! -f "$BLUEPRINT" ]; then
  for cand in docs/blueprint.md docs/overview.md .specify/memory/blueprint.md; do
    [ -f "$ROOT/$cand" ] && BLUEPRINT="$ROOT/$cand" && break
  done
fi

SPECS_DIR="$ROOT/specs"

# ── per-spec phase frontier (deterministic from artifacts) ────────────────────
# Build chain: specify → clarify → plan → tasks → implement → (analyze) → done
# Doc track (orthogonal): if a spec exists but the blueprint doesn't point to it
#                         yet, it has "distill drift".
spec_phase() {
  local dir="$1"
  [ -f "$dir/spec.md" ] || { echo "specify"; return; }
  if grep -q '\[NEEDS CLARIFICATION' "$dir/spec.md" 2>/dev/null; then echo "clarify"; return; fi
  [ -f "$dir/plan.md" ]  || { echo "plan";  return; }
  [ -f "$dir/tasks.md" ] || { echo "tasks"; return; }
  # implement: tasks.md exists but still has unchecked items → implementing
  if grep -qE '^\s*-\s*\[ \]' "$dir/tasks.md" 2>/dev/null; then echo "implement"; return; fi
  echo "built"
}

slug_of() { basename "$1"; }

is_distilled() {  # does the blueprint already point to this spec slug?
  local slug="$1"
  [ -f "$BLUEPRINT" ] || { echo 0; return; }
  if grep -q "specs/$slug" "$BLUEPRINT" 2>/dev/null; then echo 1; else echo 0; fi
}

# ── gather state ──────────────────────────────────────────────────────────────
INFLIGHT_SLUG=(); INFLIGHT_PHASE=()
DISTILL_DRIFT=()
BUILT_COUNT=0
if [ -d "$SPECS_DIR" ]; then
  for dir in "$SPECS_DIR"/*/; do
    [ -d "$dir" ] || continue
    slug="$(slug_of "${dir%/}")"
    phase="$(spec_phase "${dir%/}")"
    distilled="$(is_distilled "$slug")"
    if [ "$phase" != "built" ]; then
      INFLIGHT_SLUG+=("$slug"); INFLIGHT_PHASE+=("$phase")
    else
      BUILT_COUNT=$((BUILT_COUNT+1))
    fi
    [ "$distilled" = "0" ] && DISTILL_DRIFT+=("$slug")
  done
fi

# ── compute the single next action ────────────────────────────────────────────
# Priority (autonomous waterfall — keep the blueprint honest, finish started work
# before opening new work):
#   1. distill drift  (spec exists, blueprint hasn't collapsed its section)
#   2. advance the in-flight slice through its build chain (depth-first)
#   3. specify the next backlog subsystem (agent selects from the blueprint)
NEXT_PHASE="done"; NEXT_SLUG=""; NEXT_REASON="backlog empty — nothing in specs/, nothing in flight"
if [ "${#DISTILL_DRIFT[@]}" -gt 0 ]; then
  NEXT_PHASE="distill"; NEXT_SLUG="${DISTILL_DRIFT[0]}"
  NEXT_REASON="spec exists but blueprint still holds its detail"
elif [ "${#INFLIGHT_SLUG[@]}" -gt 0 ]; then
  NEXT_PHASE="${INFLIGHT_PHASE[0]}"; NEXT_SLUG="${INFLIGHT_SLUG[0]}"
  NEXT_REASON="in-flight slice; next build phase by artifact frontier"
elif [ -f "$BLUEPRINT" ]; then
  # spec backlog: any detailed (unspecced) subsystem? heuristic — section headings
  # not yet pointing at a spec. Selection of WHICH is the agent's judgment.
  NEXT_PHASE="specify"; NEXT_SLUG=""
  NEXT_REASON="no in-flight work; specify the next detailed subsystem from the blueprint"
fi
HAS_NEXT=true; [ "$NEXT_PHASE" = "done" ] && HAS_NEXT=false

# ── output ────────────────────────────────────────────────────────────────────
if [ "$CMD" = "next" ]; then
  if [ "$JSON" = "1" ]; then
    printf '{"has_next": %s, "phase": "%s", "slug": "%s", "reason": "%s", "blueprint": "%s"}\n' \
      "$HAS_NEXT" "$NEXT_PHASE" "$NEXT_SLUG" "$NEXT_REASON" "${BLUEPRINT#"$ROOT/"}"
  else
    echo "next: $NEXT_PHASE ${NEXT_SLUG:+($NEXT_SLUG)} — $NEXT_REASON"
  fi
  exit 0
fi

# status (human)
echo "Blueprint waterfall — state"
echo "  root:      $ROOT"
echo "  blueprint: ${BLUEPRINT:-<none — run blueprint.init>} ${BLUEPRINT:+(${BUILT_COUNT} built, $(( ${#INFLIGHT_SLUG[@]} )) in-flight)}"
echo
echo "In-flight (spec exists, build not complete):"
if [ "${#INFLIGHT_SLUG[@]}" -eq 0 ]; then echo "  (none)"; else
  for i in "${!INFLIGHT_SLUG[@]}"; do
    echo "  - ${INFLIGHT_SLUG[$i]}  → next: ${INFLIGHT_PHASE[$i]}"
  done
fi
echo
echo "Distill drift (spec exists, blueprint not yet collapsed):"
if [ "${#DISTILL_DRIFT[@]}" -eq 0 ]; then echo "  (none — blueprint in sync)"; else
  for s in "${DISTILL_DRIFT[@]}"; do echo "  - $s  → /speckit.blueprint.distill $s"; done
fi
echo
echo "Next action: $NEXT_PHASE ${NEXT_SLUG:+($NEXT_SLUG)}"
echo "  ($NEXT_REASON)"
