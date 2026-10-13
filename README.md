# Skills

Personal collection of [agent skills](https://agentskills.io) for Claude Code, Cursor, Codex, and OpenCode, plus a one-shot setup for a new machine.

## Setup

```bash
git clone git@github.com:glpecile/skills.git ~/Developer/skills
~/Developer/skills/setup.sh
```

`setup.sh` is idempotent:

1. Symlinks every `skills/*` into `~/.agents/skills/`, `~/.claude/skills/`, and the skills dir of each installed agent (Cursor, Codex, OpenCode). Edits in this repo are live everywhere at once.
2. Prunes symlinks into this repo that no longer resolve.
3. Installs each line of `manifest` from its upstream repo via `bunx skills add` for Claude Code, Cursor, Codex, and OpenCode.

`bunx` (Bun) is needed for the manifest step only. Cloning a private repository requires authorized GitHub access.

## Layout

- `skills/` — own skills and vendored third-party skills that have no installable upstream. Symlinked. `agents/openai.yaml` inside a skill is Codex display metadata.
- `manifest` — `owner/repo skill-name` per line for skills that live in a public repo. Installed as copies, updated with `bunx skills update -g`.

## Own

- **[codebase-map](./skills/codebase-map/SKILL.md)** — Create an offline architecture map with sequence diagrams, component-sharing findings, and copyable task handoffs. Includes a Markdown report for agents. Source tracing can take several minutes.
- **[delegate](./skills/delegate/SKILL.md)** — Plan at session level, delegate implementation to cheaper model subagents, verify each task with a runnable acceptance check.
- **[review-and-ship](./skills/review-and-ship/SKILL.md)** — Review, simplify, validate, commit and push, and merge an existing PR. Uses `ponytail-review` for the complexity review. Requires that skill installed separately, subagents, Git, and `gh` for PR operations. Previously named `ponytail-merge`.

## Vendored

- **before-and-after** — from [vercel-labs/before-and-after](https://github.com/vercel-labs/before-and-after). Vendored because the upstream calls its script by a repo-relative path; here it points at `~/.claude/skills/before-and-after/scripts/format.mjs`. Needs `agent-browser` and `gh` 2.99+.
- **animations, color, component-design, design-foundations, design-vocabulary, engineering-vocabulary, forms-and-inputs, marketing-pages, performance, surfaces, touch-and-accessibility, typography, ui-polish, ui-review, writing-skills** — the index.how design bundle. No git upstream found; kept as copies.

## Manifest

- [emilkowalski/skill](https://github.com/emilkowalski/skill) — animate, animation-performance, animation-vocabulary, apple-design, emil-design-eng, find-animation-opportunities, improve-animations, mobile-native, pick-ui-library, review-animations
- [cursor/plugins](https://github.com/cursor/plugins) — unslop
- [vojtaholik/good-css](https://github.com/vojtaholik/good-css) — good-css
- [jakubkrehel/skills](https://github.com/jakubkrehel/skills) — better-accessibility, better-colors, better-interface, better-layout, better-typography, better-ui, better-writing, break, build-design, explain-interface, interface-review, state-machine, variant
