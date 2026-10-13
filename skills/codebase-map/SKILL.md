---
name: codebase-map
description: Generate an evidence-backed interactive HTML architecture map and companion Markdown for understanding a codebase and delegating work. Use when the user wants the bigger picture, interactive UML-like diagrams, component sharing analysis, state/data flow, subsystem responsibilities, dependency injection or persistence maps, or architectural boundaries for scoped agent tasks. Not a symbol inventory, implementation task, or automatic refactoring tool.
---

# Codebase map

Map concepts, ownership and contracts before symbols. The purpose is to let a
human or another agent explain how the system works and scope a change without
rediscovering the entire repository. Keep source code unchanged.

## 1. Scope and snapshot

- Resolve the repository and read its AGENTS.md, stack manifest and architecture
  decisions. Ask only when the repository or requested focus cannot be resolved.
- Before tracing, tell the user that a useful map requires reading callers,
  state updates and tests, so the run can take several minutes. State the scope
  and send updates when a real finding changes it. Do not promise an unmeasured
  completion time or silently expand a focused run into a whole-repo audit.
- Record absolute repo path, HEAD, date and dirty status. A map is a snapshot,
  not a live guarantee. Read storage implementation code, never persisted tokens,
  secrets or environment values.
- Use the user's focus to select representative vertical slices. For a broad
  request, start with entry points, composition root, state and external I/O.
  Exclude generated code, dependencies and build output.
- Distinguish documented intent from observed implementation. If they disagree,
  show both with references; do not silently repeat the docs.

## 2. Trace ownership and flows

For each slice, follow the actual callers and callees end to end. Imports locate
relationships but do not prove runtime execution or causality.

- Frontend: identify composition, feature owners, shared primitives, state writers
  and readers, query/cache keys, derivation, subscriptions, URL state, persistence,
  loading/failure boundaries and platform differences.
- Backend: trace entry → orchestration → domain functions → external I/O;
  identify purposes, DI wiring/lifetimes, transaction boundaries and persistence
  ownership. Do not invent services or a database for a DB-less application.
- Full-stack: join UI/API/storage only where source proves the connection.
- Trace 2–4 useful journeys including a mutation and its aftermath. Explain
  success, partial failure, refresh/invalidation order and when UI actually
  changes. Separate proposed intent from authoritative state.
- Choose the diagram from the question: component/dependency graph for
  structure, sequence diagram for messages between participants over time,
  flowchart for decisions and branches. State flows default to sequence
  diagrams, not columns of numbered paragraphs. Keep 3–6 participants per
  sequence; label messages with short verbs, distinguish responses, and let
  selecting a message reveal the step, contract and source reference. Retain
  a selectable step-list alternative for narrow screens and assistive access.
- For each state object, identify owner, writers, readers, lifetime, persistence
  and recomputation signal. Separate remote truth, cached snapshots, derived
  values and transient interaction state.

## 3. Lift to patterns and boundaries

Group files into responsibility-based nodes with stable IDs, purpose, pattern,
contracts, state ownership and path:line evidence. Label edges precisely:
composes, reads, writes, injects, derives, invalidates, subscribes or persists.
Call something a pattern only after explaining the mechanism that supports it.

When investigating sharing:

1. Find existing reuse and actual consumers before recommending extraction.
2. Compare responsibilities and behavior, not just JSX shape or names.
3. Separate shared interaction/presentation from feature-specific policy.
4. Classify each observation as existing reuse, confirmed repeated mechanism,
   boundary mismatch, intentional difference or unverified hypothesis.
5. Give both extraction benefit and behavior that must remain separate. A
   hypothetical generic component is not a finding.

Do not treat cross-feature imports as bugs by themselves. Check whether the
owner name/location hides a genuinely shared responsibility. Never refactor
during a mapping request.

## 4. Produce two synchronized views

Write artifacts outside the target repo unless the user asks otherwise. Default
to a fresh directory beneath the harness-approved temp directory (otherwise the
OS temp directory). Tell the user the absolute paths.

Use a single JSON model and `scripts/render.py` to produce offline `index.html`
and `architecture.md`. The renderer needs Python 3; no CDN, server or build step.
The HTML includes selectable subsystem graphs, node details, labeled edges,
  search, flow steps, sharing findings and delegation boundaries. For dense maps,
  split views rather than squeezing the whole repository onto one canvas. Give
  each view 2–4 responsibility columns with 2–4 nodes each; columns set node
  positions, not causality. Edges describe the actual relationship. Keep edge
  labels in the inspector so they do not overlap the diagram.

### Presentation defaults

- Lead with the map, not an introductory essay. Use section navigation, a
  diagram workspace and one selected-component inspector.
- Use the bundled template. Apply Jakub's better-layout, better-typography and
  accessibility guidance plus Emil's interaction guidance when extending it.
  Load available skills; if unavailable, disclose that instead of claiming review.
- Show names and relationship structure on the diagram. Put purposes, state,
  contracts and source references in the inspector. Keep findings and source
  lists behind labeled disclosures so long text does not bury the map.
- Use neutral surfaces, one selection accent, a small type scale and consistent
  spacing. Keep body copy readable; do not squeeze complete descriptions into
  fixed-size nodes. Use no taglines, decorative gradients or entrance sequences.
- Keep frequent actions immediate. Use restrained press feedback, visible focus
  and reduced-motion support. Use native buttons and disclosures.
- Provide a list alternative on narrow screens and explicit fit/zoom controls
  for the two-dimensional diagram. Check 320px and desktop widths.
- Inspect a real browser screenshot before presenting the HTML when browser
  automation is available. DOM tests alone cannot approve diagram readability.

### Copyable handoffs

Include a copy action for the full report, each section, each component, each
flow, each finding and each proposed task. Generate handoffs from the same
model as the report so scope and claims cannot drift.

Each handoff names the repository and inspected commit, explains the selected
responsibility, lists evidence, states a proposed improvement scope, preserves
the relevant contracts and names existing checks. Include uncertainty and
coordination requirements. Tell the receiving agent to verify current source
before acting: a report may already be stale. Findings are suggestions, not
permission to edit unrelated files. Do not invent a task for existing reuse or
an intentional difference.

Confirm copy success. If the clipboard API is unavailable (including some
file:// contexts), show a labeled, selectable text field with the complete
handoff and explain how to copy it manually. Never claim success after a failed
clipboard write.

### Language

Use STE100 as the writing guide. Do not claim certified compliance without
checking the approved-word dictionary. Keep established technical names such as
QueryClient, provider, mutation and dependency injection; define unfamiliar
terms once. Use the same term for the same object everywhere.

- Write one fact or instruction per sentence. Aim for at most 20 words per
  sentence. Use a named subject and an active verb.
- Name the writer, reader and update signal. Write “The query stores provider
  data,” not “the read model owns truth” or “the cache mediates convergence.”
- State the observed mechanism before naming a pattern. Avoid metaphors,
  promotional copy, abstract noun chains and unexplained architectural labels.
- Keep node labels to 2–5 words. Give each purpose 1–2 short sentences. Move
  evidence and limits to disclosures instead of repeating them in every card.
- Use `stateFields` for a compact Owner / Writers / Readers / Lifetime / Update
  table. Retain `state` as a complete sentence summary in Markdown.

Model structure (all text is plain text, never HTML):

```json
{
  "title": "Project architecture",
  "snapshot": "Repo path · HEAD · date · dirty status",
  "scope": "Inspected slices and what was not covered",
  "summary": ["Architecture conclusions"],
  "checks": ["Existing repo validation command"],
  "nodes": [{"id":"cache", "label":"Query cache", "group":"State", "purpose":"...", "pattern":"...", "state":"Owner; writers; readers; lifetime; persistence; signal", "contracts":["..."], "sources":["src/cache.ts:12-40"]}],
  "views": [{"id":"overview", "label":"Overview", "nodes":["cache"], "columns":[{"label":"State", "nodes":["cache"]}], "edges":[{"from":"cache", "to":"cache", "label":"relationship", "evidence":"src/cache.ts:12"}]}],
  "flows": [{"title":"Log an item", "steps":[{"node":"cache", "text":"What happens and why", "evidence":"src/cache.ts:12"}], "failure":"Failure and recovery behavior"}],
  "findings": [{"title":"...", "classification":"Existing reuse / Repeated mechanism / Boundary mismatch / Intentional difference / Hypothesis", "detail":"Evidence and consequence", "preserve":"Behavior that must stay distinct", "sources":["src/cache.ts:12"]}],
  "delegation": [{"title":"Scoped task", "scope":"Allowed area", "contracts":"What must remain intact", "checks":["Existing test or runnable check"], "sources":["src/cache.ts:12"]}],
  "unknowns": ["Limitations and open questions"]
}
```

```sh
python3 <skill-dir>/scripts/render.py <map.json> <output-dir>
```

Optional sequence data on each flow:

```json
{"sequence":{"participants":[{"id":"ui","label":"Screen"},{"id":"cache","label":"Query cache"}],"messages":[{"from":"ui","to":"cache","label":"Read data","step":0},{"from":"cache","to":"ui","label":"Return data","step":0,"response":true}]}}
```

`step` indexes the flow's evidence-backed `steps`. Each message must represent
an inspected event. Do not invent responses to complete a diagram.

## 5. Verify and hand off

- Verify every cited path and line range exists and supports its claim. Mark
  runtime behavior inferred from static analysis as such.
- Ensure every edge endpoint and flow node resolves. Check the rendered HTML's
  selection, search, view switching and flow navigation with a browser when
  available; otherwise run DOM checks and disclose the lack of visual QA.
- Ensure the HTML works offline and includes a textual edge list; diagrams
  cannot be the only accessible explanation. Escape repository-derived text.
- Test full-report and section handoffs, copy feedback and manual-copy fallback.
- Delegate from responsibility boundaries: name allowed files, dependencies,
  invariants, existing checks and coordination points. Do not imply tasks that
  touch the same shared contract can be implemented independently.
- Summarize the biggest discoveries and link the artifacts. Say what was not
  inspected. A map is not proof that suspected duplication or a bug exists.
