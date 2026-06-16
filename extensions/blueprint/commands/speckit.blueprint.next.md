---
description: "Print the single next waterfall action (deterministic), derived from specs/ and the blueprint — the oracle the autonomous driver loops on"
---

# Blueprint Next

Compute, **deterministically**, the single next action in the waterfall. This is the
oracle that keeps an autonomous run on track: it reads `specs/` (ground truth) and
the blueprint (the index), never guesses, and emits one next step.

## Execution

Run the state script and report its output verbatim:

- **Bash**: `.specify/extensions/blueprint/scripts/bash/blueprint-state.sh next --json`
- **PowerShell**: `.specify/extensions/blueprint/scripts/powershell/blueprint-state.ps1 next --json`

The JSON has the shape:

```json
{"has_next": true, "phase": "plan", "slug": "002-rate-limiting",
 "reason": "in-flight slice; next build phase by artifact frontier",
 "blueprint": "docs/overview.md"}
```

- `phase` ∈ `specify | clarify | plan | tasks | implement | distill | done`.
- `slug` is the feature directory under `specs/` the action applies to (empty when
  `phase` is `specify` — the agent selects which detailed subsystem to start, or
  `done`).
- `has_next: false` means the backlog is exhausted — nothing in `specs/` is
  unfinished and the blueprint is in sync.

## Notes

- This command does not change anything. It is the read side of the harness.
- The mapping from `phase` to the command to run:
  `specify → __SPECKIT_COMMAND_SPECIFY__`, `clarify → __SPECKIT_COMMAND_CLARIFY__`,
  `plan → __SPECKIT_COMMAND_PLAN__`, `tasks → __SPECKIT_COMMAND_TASKS__`,
  `implement → __SPECKIT_COMMAND_IMPLEMENT__`,
  `distill → __SPECKIT_COMMAND_BLUEPRINT_DISTILL__`.
