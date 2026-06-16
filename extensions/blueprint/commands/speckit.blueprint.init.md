---
description: "Scaffold the blueprint — the project's backlog + architecture map — optionally seeding from an existing master/overview design doc"
---

# Initialize Blueprint

Create the project **blueprint**: the authoritative, decreasing-detail document the
autonomous waterfall driver runs from. It is at once the backlog of unspecced
subsystems, the architecture map, and the index of feature specs.

## User Input

```text
$ARGUMENTS
```

Optional **seed source** — a path to an existing comprehensive design doc
(`docs/master-spec.md`, `docs/overview.md`) to import. If empty, scaffold an empty
blueprint from the template.

## Resolve

1. Repo root = nearest ancestor with `.specify/`.
2. Blueprint path: `blueprint-config.yml` → `blueprint.path` (default
   `.specify/memory/blueprint.md`; many teams prefer `docs/blueprint.md`). Call it
   `BLUEPRINT`.
3. Template: `.specify/extensions/blueprint/templates/blueprint-template.md`.

## Prerequisites

- If `BLUEPRINT` exists, **do not overwrite**. Report it and suggest
  `__SPECKIT_COMMAND_BLUEPRINT_STATUS__`, then stop.
- Create `BLUEPRINT`'s parent directory if needed.

## Execution

1. **Start from the template.** Fill `[PROJECT NAME]` and `[DATE]`. Keep the
   "how this works" header and the prose section convention (Detailed vs Distilled
   banners) — the commands and the oracle read prose, not tags.

2. **If a seed source was provided**, import it as the holding pen:
   - Split it into subsystem-sized sections; carry over the real design detail at
     design altitude (decisions, thresholds, entities, contracts, open questions).
     Do not invent content the seed lacks.
   - **Cross-check `specs/`.** For each subsystem, if a feature spec already owns it,
     scaffold that section already-**distilled** (digest + pointer) instead of
     copying detail. Where a spec owns only part, distill that part and keep the
     rest detailed (partial distillation). When ownership is ambiguous, leave it
     detailed and note `[NEEDS CLARIFICATION: owning spec?]`.

3. **If no seed**, leave the two example sections as a guide to replace.

4. **Build the Table of Contents** so every section has one entry with its status
   (`detailed` / `distilled → specs/<slug>`).

5. **Write** `BLUEPRINT`. Do not delete the seed source — recommend the author
   retire it once the blueprint is trusted, to keep a single source of truth.

## Report Back

- Path written; whether seeded and from where.
- TOC summary: N sections — X detailed / Y distilled.
- Next: design more detailed sections, or run
  `__SPECKIT_COMMAND_BLUEPRINT_DRIVE__` to start building autonomously, or
  `__SPECKIT_COMMAND_BLUEPRINT_STATUS__` to see the worklist.

## Guardrails

- Never overwrite an existing blueprint.
- Never fabricate design detail not in the seed or codebase.
- Keep the prose section convention and the header — downstream commands rely on it.
