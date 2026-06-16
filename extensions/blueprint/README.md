# Blueprint Waterfall Harness Extension

A harness for **waterfall, fully agent-driven app development**. One authoritative,
*collapsing* blueprint is the project's state; a **deterministic oracle** computes
what to build next; an **autonomous driver** loops the backlog through the spec-kit
waterfall — specify → clarify → plan → tasks → implement — distilling each slice as
it goes, re-grounding on the oracle every step so it can run for hours without
drifting.

## The idea

Start from a comprehensive design and slice it into specs, and you get two sources
of truth — the master doc and the specs both hold the detail, and every spec edit
drags a cumbersome back-sync behind it. The blueprint fixes that by being a
*decreasing-detail* artifact:

- **Detailed (unspecced)** sections hold full design — the holding pen / backlog.
- Once a feature spec owns a slice, its section **distills** to an at-a-glance
  digest + a pointer. Detail flows out into specs, once, forward — never back.

As slices get specced and built, the blueprint asymptotes to a pure architecture
map + index. That map is exactly the substrate an agent needs to drive an
unattended build: *what to build next*, *how it fits*, *where the truth lives*.

## Why it stays on the rails (the deterministic spine)

The hard part of unattended autonomy is not drifting over a long run. The harness
never trusts the agent's memory of progress — **the filesystem is the source of
truth**:

- `specs/<NNN-slug>/` (and the artifacts inside: `spec.md`, `plan.md`, `tasks.md`)
  are ground truth for what's specced/built.
- The oracle script `scripts/bash/blueprint-state.sh` reads `specs/` + the blueprint
  and computes the single next action — deterministically, no LLM judgment in the
  part that must be reliable. The driver re-runs it every iteration.

```
$ blueprint-state.sh next --json
{"has_next": true, "phase": "plan", "slug": "002-rate-limiting", ...}
```

## Commands

| Command | What it does |
|---------|--------------|
| `speckit.blueprint.init` | Scaffold the blueprint, optionally seeding from an existing master/overview doc. |
| `speckit.blueprint.next` | Print the single next action (deterministic). The oracle the driver loops on. |
| `speckit.blueprint.status` | Human worklist: in-flight slices + next phase, distill drift, next action. |
| `speckit.blueprint.distill` | Collapse a finalized spec's section to an at-a-glance digest + pointer. |
| `speckit.blueprint.drive` | **Autonomously drive the waterfall** over the whole backlog. |

Plus the **`blueprint-waterfall` workflow** (`specify workflow run blueprint-waterfall`)
— the same driver with persisted run-state and resumability.

## Typical flow

```bash
specify extension add blueprint

/speckit.blueprint.init docs/master-spec.md      # seed the blueprint from a master doc
/speckit.blueprint.status                        # see the backlog + next action

# build the whole project autonomously:
/speckit.blueprint.drive max_steps=25
#   loops: next → plan 001 → tasks 001 → implement 001 → distill 001 → specify 002 → …

# or via the workflow (persisted run-state, resumable):
specify workflow run blueprint-waterfall -i max_steps=25 -i stop_before=implement
```

## The blueprint document

Prose-first — no rigid tags required. An annotated table of contents is the index +
architecture map; each section opens with a `> **Detailed (unspecced)**` or
`> **Distilled — owned by` `specs/<slug>`**` banner. Partial distillation is normal
(distill the specced sub-part; keep the rest as holding pen). The oracle reads this
prose and the filesystem; it works on organically-grown overview docs, not just ones
this extension created.

## Configuration

`.specify/extensions/blueprint/blueprint-config.yml`:

```yaml
blueprint:
  path: ".specify/memory/blueprint.md"   # or docs/blueprint.md / docs/overview.md
distill:
  require_confirmation: true             # lossy → confirm before overwriting
```

## Autonomy & safety

- The driver takes `max_steps` (hard cap), `stop_before=<phase>`, `slug=<one slice>`,
  and `dry_run=true`. Unattended ≠ unbounded.
- It **parks** any slice it can't finish autonomously (needs a human decision, a
  missing credential, a genuinely ambiguous spec), skips it, keeps building the
  rest, and reports parked items at the end.
- `distill` is lossy and confirms by default.
- The oracle and `status` are read-only.

## Authority model

Feature spec = source of truth for its slice. Blueprint = map + holding pen that
defers to specs. Constitution = principles. Consider a "Spec Authority" principle in
your constitution to encode it.

## Status of this extension

- Bash oracle: tested (unit + behavioral tests in `tests/extensions/blueprint/`).
- PowerShell oracle (`scripts/powershell/blueprint-state.ps1`): written for parity;
  **needs execution-verification on a Windows/pwsh environment before merge**.
- The `drive` command is a semantic loop executed by the agent; the deterministic
  oracle keeps it grounded each iteration.
