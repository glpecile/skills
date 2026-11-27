# Skills

Agent skills that help you hand work to coding agents and check what comes back, from mapping a codebase to shipping the PR.

They come from my day-to-day work with Claude Code, Cursor, Codex and OpenCode. Each skill is a workflow I kept repeating by hand: it gives the agent a process to follow and the checks to run before it says it is done.

## Skills

- [**codebase-map**](./skills/codebase-map/SKILL.md): Creates an offline, interactive **architecture map** with **sequence diagrams**, **component-sharing** findings and copyable **task handoffs**, plus a Markdown report for agents. Source tracing can take several minutes. Needs `jq` 1.6+, or falls back to filling the template by hand.
- [**delegate**](./skills/delegate/SKILL.md): Plans at session level, hands implementation to **cheaper model subagents**, and verifies each task with a **runnable acceptance check** in a goal loop.
- [**figma-self-review**](./skills/figma-self-review/SKILL.md): Checks UI you already built against its **Figma frame**. It compares **structure**, **pixel-diffs** both renders, traces each difference to an **exact property**, fixes it, and repeats for up to 3 rounds. Needs the Figma MCP and agent-browser 0.38+, or another headless browser plus ImageMagick 7.
- [**find-haptic-opportunities**](./skills/find-haptic-opportunities/SKILL.md): Audits a mobile app for **missing haptics**. It runs each candidate through **meaning, frequency, ownership, timing and comfort gates**, then proposes **exact recipes** that reuse the app's existing haptic vocabulary, with **rejected candidates** and a verification checklist. Read-only.
- [**ketchup**](./skills/ketchup/SKILL.md): Catches you up on an existing chat. It **checks the live state** of every PR, Jira ticket, Notion page and artifact the chat touched. It **fixes what broke** when the fix needs no human. Then it reports the **next action**, links, work done, **who is blocking** what, and the decisions that need you.
- [**react-taste**](./skills/react-taste/SKILL.md): My **DOs and DON'Ts** for React. Decision trees for **effects**, **where state lives**, **async state** with `useTransition`, **Suspense** loading states, component APIs, **destructive actions** behind a dialog and **memoization** under React Compiler.
- [**scrub**](./skills/scrub/SKILL.md): Steps through a **screen recording** frame by frame. It finds the moment with **scene-change times** and overview sheets, extracts **every real frame** of a variable-frame-rate recording, and reports each **jump, flash or overlap** with its time range. It never calls an odd frame "normal", and a fix counts only after a **new recording** of the same window is clean. Needs `ffmpeg`.
- [**shush**](./skills/shush/SKILL.md): Deletes code comments that **narrate** or **justify**. A **decision tree** keeps only license headers, tool directives, contracts, TODO ticket keys, labels for opaque values and settings headers. It edits comments only: each deleted reason that guarded code becomes a **RESHAPE** line for the commit message and the PR body, with the rename or test that would make the code say it. Rules adapted from Comment Sicko in [pstack](https://github.com/playcsgo/pstack_plugins).
- [**yeet**](./skills/yeet/SKILL.md): Runs the harness's built-in **code review** for correctness and `ponytail-review` for **complexity**, fixes the findings as a **hill climb** (one change, one measurement, keep or revert) against the open findings and failing checks, or against a metric you name ("yeet and score the bundle size"), **proves each change** with observed evidence, then **commits, pushes**, **creates a PR** if none exists and **squash-merges** it. Needs `ponytail-review`, subagents, Git and `gh`. On UI diffs it also runs Emil Kowalski's **motion chain** (`find-animation-opportunities` → `animate` → `review-animations`), which it then needs. On React diffs it also runs **`react-taste`**, and on UI diffs Emil's **`break-ui`** with worst-case data, when installed. On every diff it runs **`shush`** on comments before the reviews, when installed.

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
