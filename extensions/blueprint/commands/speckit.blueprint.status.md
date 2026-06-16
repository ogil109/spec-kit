---
description: "Show the blueprint waterfall worklist: in-flight slices and their next phase, distill drift, and the next action (deterministic)"
---

# Blueprint Status

Human-readable dashboard of the waterfall state — what's in flight, what phase each
slice is at, what's drifted, and what the driver would do next. Read-only.

## Execution

Run the state script and present its output:

- **Bash**: `.specify/extensions/blueprint/scripts/bash/blueprint-state.sh status`
- **PowerShell**: `.specify/extensions/blueprint/scripts/powershell/blueprint-state.ps1 status`

Then, if the user asked for it or it adds value, add a one-line recommendation
that maps the reported "Next action" phase to its command (e.g. `plan
(002-rate-limiting)` → run `__SPECKIT_COMMAND_PLAN__`), and mention
`__SPECKIT_COMMAND_BLUEPRINT_DRIVE__` to run the whole waterfall autonomously.

## Guardrails

- Read-only: never edit specs, the blueprint, or any state. Only report what the
  script computes.
