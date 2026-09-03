# Skills

Personal collection of [Claude Code skills](https://code.claude.com/docs/en/skills), plus a one-shot setup for a new machine.

## Setup

```bash
git clone git@github.com:glpecile/skills.git ~/Developer/skills
~/Developer/skills/setup.sh
```

`setup.sh` is idempotent:

1. Symlinks every `skills/*` into `~/.claude/skills/` (edits in this repo are live immediately).
2. Prunes symlinks into this repo that no longer resolve.
3. Installs each line of `manifest` from its upstream repo via `bunx skills add`.

Private repo — requires git access (SSH) to clone. `bunx` (Bun) is needed for the manifest step only.

## Layout

- `skills/` — own skills and vendored third-party skills that have no installable upstream. Symlinked.
- `manifest` — `owner/repo skill-name` per line for skills that live in a public repo. Installed as copies, updated with `bunx skills update -g`.

## Own

- **[delegate](./skills/delegate/SKILL.md)** — Plan at session level, delegate implementation to cheaper model subagents, verify each task with a runnable acceptance check.

## Vendored

- **before-and-after** — from [vercel-labs/before-and-after](https://github.com/vercel-labs/before-and-after). Vendored because the upstream calls its script by a repo-relative path; here it points at `~/.claude/skills/before-and-after/scripts/format.mjs`. Needs `agent-browser` and `gh` 2.99+.
- **animations, color, component-design, design-foundations, design-vocabulary, engineering-vocabulary, forms-and-inputs, marketing-pages, performance, surfaces, touch-and-accessibility, typography, ui-polish, ui-review, writing-skills** — the index.how design bundle. No git upstream found; kept as copies.

## Manifest

- [emilkowalski/skill](https://github.com/emilkowalski/skill) — animation-vocabulary, apple-design, emil-design-eng, find-animation-opportunities, improve-animations, review-animations
- [cursor/plugins](https://github.com/cursor/plugins) — unslop
