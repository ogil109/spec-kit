---
description: "Autonomously drive the waterfall: loop over the blueprint backlog, taking each slice through specify→clarify→plan→tasks→implement and distilling as you go, re-grounding on the deterministic oracle every step"
---

# Blueprint Drive (autonomous waterfall)

Run the project's build as an unattended waterfall. Each iteration you ask the
**deterministic oracle** what to do next, do exactly that one step, then ask
again. The oracle reads `specs/` and the blueprint from disk every time, so you
**cannot drift**: your memory of progress is never the source of truth — the
filesystem is. This is what lets the loop run for hours without losing the plot.

## User Input

```text
$ARGUMENTS
```

Optional controls (parse from `$ARGUMENTS`, all have safe defaults):
- `max_steps=N` — stop after N phase-steps (default 25). A hard backstop.
- `stop_before=<phase>` — stop when the next action would be this phase
  (e.g. `stop_before=implement` to set everything up but not write code).
- `slug=<feature>` — only advance this one slice; ignore the rest of the backlog.
- `dry_run=true` — print the plan of next steps without executing any.

## The loop

Repeat until the oracle says `done`, you hit `max_steps`, or you hit a stop/parked
condition:

1. **Ask the oracle.** Run
   `.specify/extensions/blueprint/scripts/bash/blueprint-state.sh next --json`
   (PowerShell: `.../powershell/blueprint-state.ps1 next --json`). Parse
   `{has_next, phase, slug, reason}`.

2. **Check stop conditions.** If `has_next` is false → **stop, report success**.
   If `phase == stop_before`, or steps taken ≥ `max_steps` → **stop and report**
   where you are. If `dry_run`, print the action and **simulate** advancing (you
   cannot actually advance without running it, so for `dry_run` just print the
   single next action and stop).

3. **Run exactly one phase** by invoking the matching core command for `slug`:
   | phase | command |
   |---|---|
   | `specify` | `__SPECKIT_COMMAND_SPECIFY__` — select the next *detailed* (unspecced) subsystem from the blueprint and specify it. Pull the slice's design detail out of its blueprint section as the input. |
   | `clarify` | `__SPECKIT_COMMAND_CLARIFY__` for `slug` — resolve the `[NEEDS CLARIFICATION]` markers. |
   | `plan` | `__SPECKIT_COMMAND_PLAN__` for `slug`. |
   | `tasks` | `__SPECKIT_COMMAND_TASKS__` for `slug`. |
   | `implement` | `__SPECKIT_COMMAND_IMPLEMENT__` for `slug`. |
   | `distill` | `__SPECKIT_COMMAND_BLUEPRINT_DISTILL__` `slug` — collapse the slice's blueprint section to a digest + pointer. |

   Do the step properly and completely — this is real work, not a checkbox. The
   oracle only advances when the artifact for the current phase actually exists
   on disk, so a half-done phase will simply be re-selected next iteration.

4. **Re-ground and continue.** Go back to step 1. Do **not** assume what comes
   next — re-run the oracle. The set of remaining work changes as artifacts land.

## Parking (don't get stuck)

If a phase cannot be completed autonomously — a `clarify` whose answer needs a
human decision, an `implement` blocked on a missing dependency or a credential,
a genuinely ambiguous spec — **do not loop forever and do not guess on something
that needs a human.** Record the blocker (one line: slice, phase, what's needed),
**skip that slice** (continue with `slug` excluded), and surface all parked items
in the final report. A waterfall that parks one slice and keeps building the rest
is healthy; one that spins on a blocked slice is not.

## Final report

When the loop ends, report:
- Why it stopped: `done` / `max_steps` / `stop_before` / all-remaining-parked.
- What advanced this run, slice by slice (phase → phase).
- Parked slices and exactly what each needs from a human.
- The current `__SPECKIT_COMMAND_BLUEPRINT_STATUS__` snapshot and the suggested
  way to resume (`__SPECKIT_COMMAND_BLUEPRINT_DRIVE__` again, or address the
  parked items first).

## Guardrails

- The oracle is the source of truth for "what's next" — never substitute your own
  recollection. Re-run it every iteration.
- One phase per iteration. Never skip ahead (e.g. plan before a spec is clarified);
  the oracle enforces order, so just follow it.
- Never fabricate completion. If you didn't actually finish a phase, the artifact
  won't exist and that's correct — let the oracle re-select it.
- Respect `max_steps` and parking. Unattended ≠ unbounded.
