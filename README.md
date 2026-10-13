# Skills

Personal collection of [agent skills](https://agentskills.io) for Claude Code, Cursor, Codex, and OpenCode, plus a one-shot setup for a new machine.

Install a single skill without cloning:

```bash
npx skills add glpecile/skills --skill figma-self-review
```

## Setup

```bash
git clone git@github.com:glpecile/skills.git ~/Developer/skills
~/Developer/skills/setup.sh
```

Agents installing this repo: run `./setup.sh` after cloning; cloning alone installs nothing. Rules for agents live in [AGENTS.md](./AGENTS.md).

`setup.sh` is idempotent:

1. Symlinks every `skills/*`, plus `~/dotfiles/skills/*` when that private repo is cloned, into `~/.agents/skills/`, `~/.claude/skills/`, and the skills dir of each installed agent (Cursor, Codex, OpenCode). Edits in this repo are live everywhere at once.
2. Prunes symlinks into this repo or `~/dotfiles` that no longer resolve.
3. Installs each line of `manifest` from its upstream repo via `bunx skills add` for Claude Code, Cursor, Codex, and OpenCode.

`bunx` (Bun) is needed for the manifest step only.

## Layout

- `skills/` — own skills only. Symlinked. Third-party skills with no installable upstream live in the private dotfiles repo under `skills/`, never here. `agents/openai.yaml` inside a skill is Codex display metadata.
- `manifest` — `owner/repo skill-name` per line for skills that live in a public repo. Installed as copies, updated with `bunx skills update -g`.

## Own

- **[codebase-map](./skills/codebase-map/SKILL.md)** — Create an offline architecture map with sequence diagrams, component-sharing findings, and copyable task handoffs. Includes a Markdown report for agents. Source tracing can take several minutes.
- **[delegate](./skills/delegate/SKILL.md)** — Plan at session level, delegate implementation to cheaper model subagents, verify each task with a runnable acceptance check.
- **[figma-self-review](./skills/figma-self-review/SKILL.md)** — Pixel-diff a built UI against its Figma frame, trace each difference to an exact property, fix it, and repeat for up to 3 rounds. Requires the Figma MCP and agent-browser 0.38+.
- **[review-and-ship](./skills/review-and-ship/SKILL.md)** — Review, simplify, validate, commit and push, and merge an existing PR. Uses `ponytail-review` for the complexity review. Requires that skill installed separately, subagents, Git, and `gh` for PR operations. Previously named `ponytail-merge`.

## Manifest

- [emilkowalski/skill](https://github.com/emilkowalski/skill) — animate, animation-performance, animation-vocabulary, apple-design, emil-design-eng, find-animation-opportunities, improve-animations, mobile-native, pick-ui-library, review-animations
- [cursor/plugins](https://github.com/cursor/plugins) — unslop
- [vojtaholik/good-css](https://github.com/vojtaholik/good-css) — good-css
- [jakubkrehel/skills](https://github.com/jakubkrehel/skills) — better-accessibility, better-colors, better-interface, better-layout, better-typography, better-ui, better-writing, break, build-design, explain-interface, interface-review, state-machine, variant

## License

[MIT](./LICENSE), covering the skills in `skills/`. Manifest entries keep their upstream licenses.
