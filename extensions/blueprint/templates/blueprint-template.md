# [PROJECT NAME] Blueprint

**Status**: Living document — the authoritative backlog + architecture map for this project.

**Created**: [DATE]

<!--
  HOW THIS DOCUMENT WORKS
  =======================
  The blueprint is a *decreasing-detail* artifact and the state the autonomous
  waterfall driver runs from. It plays two roles and sheds the costly one:

    - HOLDING PEN (high value): a subsystem with NO feature spec yet keeps its
      full design detail here. This is the backlog the driver pulls from when it
      runs /speckit.specify on that slice.

    - INDEX (low cost): once a subsystem HAS a feature spec, its section distills
      to an at-a-glance digest + a pointer. The spec is the source of truth; this
      section just indexes it.

  Detail flows ONE WAY — out of here into specs, once, when a slice is specced.
  Never back. There is nothing to back-sync.

  GROUND TRUTH is the filesystem: `specs/<NNN-slug>/` is authoritative for what's
  been specced/built; this document references those specs by path. The driver's
  oracle (/speckit.blueprint.next) reads both and never guesses.

  SECTION CONVENTION (prose, not tags):
    - A DETAILED section opens with:   > **Detailed (unspecced)** — holding pen.
    - A DISTILLED section opens with:  > **Distilled — owned by `specs/<slug>`.**
      followed by a short role sentence, a bulleted at-a-glance digest of the
      load-bearing mechanics, and a "see the spec, don't restate" closer.
    Partial distillation is fine: distill the specced sub-part, keep the rest
    detailed with a note naming the future spec it's earmarked for.

  AUTHORITY: feature spec = source of truth for its slice; blueprint = map +
  holding pen that defers to specs; constitution = principles.
-->

## Table of Contents

The index *and* the architecture map. Each entry notes its status so the map and
the sections agree. Keep it current (the /speckit.blueprint.* commands do this).

- §1 [Subsystem A] — [one line]; **detailed** (no spec yet)
- §2 [Subsystem B] — [one line]; **distilled** → `specs/00X-slug`
- … add one entry per section …

---

## 1. [Subsystem A]

> **Detailed (unspecced)** — holding pen. Full design lives here until a feature
> spec takes it over. This is the backlog the driver specs next.

**Purpose**: [what this subsystem is responsible for].

**Key decisions**: [the real design — entities, contracts, thresholds, gate
mechanics, the things a future spec will formalize].

**Boundaries**: [what it exposes to / expects from neighbors].

**Open questions**: [NEEDS CLARIFICATION: …]

---

## 2. [Subsystem B]

> **Distilled — owned by `specs/00X-slug` ([spec](../../specs/00X-slug/spec.md)).**
> The full detail lives in that spec, which is the source of truth. This is a
> summary + index.

[One or two sentences: the slice's role and how it connects to neighbors.] At a glance:

- **[Facet]** — [the load-bearing decision / constant].
- **[Facet]** — [key mechanic].

For every requirement, threshold, and entity shape, see `specs/00X-slug/spec.md`.
Do not restate those details here — this section indexes the spec.
