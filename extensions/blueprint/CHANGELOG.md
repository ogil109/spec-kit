# Changelog

All notable changes to this extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### TODO before bundled merge

- Execution-verify the PowerShell oracle (`scripts/powershell/blueprint-state.ps1`)
  on a Windows/pwsh environment (the Bash oracle is tested; the port is written for parity).
- Optional: express the driver loop natively in the workflow engine (do-while over
  the oracle) in addition to the agent-driven `drive` command.
- Detect `implement`/`analyze` completion more richly than tasks-checkbox state.

## [1.0.0] - 2026-06-16

### Added

- **Deterministic state oracle** (`scripts/bash/blueprint-state.sh`) — computes the
  single next waterfall action from `specs/` (ground truth) + the blueprint. No LLM
  judgment in the reliable path. Unit + behavioral tests included.
- Command: `/speckit.blueprint.next` — print the next action (the oracle).
- Command: `/speckit.blueprint.status` — human worklist (in-flight, distill drift, next).
- Command: `/speckit.blueprint.drive` — autonomously drive the waterfall over the
  backlog, re-grounding on the oracle each step, with `max_steps`/`stop_before`/
  `slug`/`dry_run` controls and slice **parking**.
- Command: `/speckit.blueprint.distill` — collapse a finalized spec's section to an
  **at-a-glance digest** + pointer (digest altitude, prose-first, partial distillation).
- Command: `/speckit.blueprint.init` — scaffold the blueprint, optionally seeding
  from an existing master/overview doc; auto-distills sections already owned by specs.
- **`blueprint-waterfall` workflow** — `specify workflow run blueprint-waterfall`,
  the driver with persisted run-state + resumability.
- Prose-first blueprint document convention (annotated TOC + Detailed/Distilled
  banners); works on organically-grown overview docs, not just generated ones.
- Bundled registration: `extensions/catalog.json`, `workflows/catalog.json`, wheel packaging.

### Design notes

- Validated against a real, hand-written project overview that independently arrived
  at the same model and vocabulary (distilled / holding pen / owned by); the
  digest-altitude `distill` guidance is modeled on its actual distilled sections.

### Requirements

- Spec Kit: >=0.10.0

---

[Unreleased]: https://github.com/github/spec-kit/tree/main/extensions/blueprint
[1.0.0]: https://github.com/github/spec-kit/tree/main/extensions/blueprint
