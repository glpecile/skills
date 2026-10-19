# Skills

Agent skills that help you hand work to coding agents and check what comes back, from mapping a codebase to shipping the PR.

They come from my day-to-day work with Claude Code, Cursor, Codex and OpenCode. Each skill is a workflow I kept repeating by hand: it gives the agent a process to follow and the checks to run before it says it is done.

## Skills

- [**codebase-map**](./skills/codebase-map/SKILL.md): Creates an offline, interactive **architecture map** with **sequence diagrams**, **component-sharing** findings and copyable **task handoffs**, plus a Markdown report for agents. Source tracing can take several minutes. Needs `jq` 1.6+, or falls back to filling the template by hand.
- [**delegate**](./skills/delegate/SKILL.md): Plans at session level, hands implementation to **cheaper model subagents**, and verifies each task with a **runnable acceptance check** in a goal loop.
- [**figma-self-review**](./skills/figma-self-review/SKILL.md): Checks UI you already built against its **Figma frame**. It compares **structure**, **pixel-diffs** both renders, traces each difference to an **exact property**, fixes it, and repeats for up to 3 rounds. Needs the Figma MCP and agent-browser 0.38+, or another headless browser plus ImageMagick 7.
- [**find-haptic-opportunities**](./skills/find-haptic-opportunities/SKILL.md): Audits a mobile app for **missing haptics**. It runs each candidate through **meaning, frequency, ownership, timing and comfort gates**, then proposes **exact recipes** that reuse the app's existing haptic vocabulary, with **rejected candidates** and a verification checklist. Read-only.
- [**review-and-ship**](./skills/review-and-ship/SKILL.md): Runs the harness's built-in **code review** for correctness and `ponytail-review` for **complexity**, fixes the findings, **validates**, then **commits, pushes**, **creates a PR** if none exists and **squash-merges** it. Needs `ponytail-review`, subagents, Git and `gh`. User-invoked.

## Install

```bash
npx skills add glpecile/skills
```

Or a single skill:

```bash
npx skills add glpecile/skills --skill figma-self-review
```

## Personal setup

How I install these on my own machines, alongside third-party skills: [PERSONAL_SETUP.md](./PERSONAL_SETUP.md).

## License

[MIT](./LICENSE)
