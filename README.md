# Skills

[![skills.sh](https://skills.sh/b/glpecile/skills)](https://skills.sh/glpecile/skills)

Agent skills that help you hand work to coding agents and check what comes back, from mapping a codebase to shipping the PR.

They come from my day-to-day work with Claude Code, Cursor, Codex and OpenCode. Each skill is a workflow I kept repeating by hand: it gives the agent a process to follow and the checks to run before it says it is done.

## Skills

- [**codebase-map**](./skills/codebase-map/SKILL.md): Creates an offline, interactive **architecture map** with **sequence diagrams**, **component-sharing** findings and copyable **task handoffs**, plus a Markdown report for agents. Source tracing can take several minutes.
- [**delegate**](./skills/delegate/SKILL.md): Plans at session level, hands implementation to **cheaper model subagents**, and verifies each task with a **runnable acceptance check** in a goal loop.
- [**figma-self-review**](./skills/figma-self-review/SKILL.md): Checks UI you already built against its **Figma frame**. It compares **structure**, **pixel-diffs** both renders, traces each difference to an **exact property**, fixes it, and repeats for up to 3 rounds. Needs the Figma MCP and agent-browser 0.38+, or another headless browser plus ImageMagick 7.
- [**review-and-ship**](./skills/review-and-ship/SKILL.md): Runs the harness's built-in **code review** for correctness and `ponytail-review` for **complexity**, fixes the findings, **validates**, then **commits, pushes** and **squash-merges** an existing PR. Needs `ponytail-review`, subagents, Git and `gh`. User-invoked.

## Install

```bash
npx skills add glpecile/skills
```

Or a single skill:

```bash
npx skills add glpecile/skills --skill figma-self-review
```

## My setup

This repo is also how I set up a new machine.

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

### Layout

- `skills/` — own skills only. Symlinked. Third-party skills with no installable upstream live in the private dotfiles repo under `skills/`, never here. `agents/openai.yaml` inside a skill is Codex display metadata.
- `manifest` — `owner/repo skill-name` per line for skills that live in a public repo. Installed as copies, updated with `bunx skills update -g`.

### Manifest

- [emilkowalski/skill](https://github.com/emilkowalski/skill) — animate, animation-performance, animation-vocabulary, apple-design, emil-design-eng, find-animation-opportunities, improve-animations, mobile-native, pick-ui-library, review-animations
- [cursor/plugins](https://github.com/cursor/plugins) — unslop
- [vojtaholik/good-css](https://github.com/vojtaholik/good-css) — good-css
- [jakubkrehel/skills](https://github.com/jakubkrehel/skills) — better-accessibility, better-colors, better-interface, better-layout, better-typography, better-ui, better-writing, break, build-design, explain-interface, interface-review, state-machine, variant

## License

[MIT](./LICENSE), covering the skills in `skills/`. Manifest entries keep their upstream licenses.
