# Personal setup

How these skills are installed on personal setups. Everyone else installs with `npx skills add glpecile/skills`.

Linking and installing live in the private [dotfiles](https://github.com/glpecile/dotfiles) repo, which also holds the third-party skills.

## Install

```bash
git clone git@github.com:glpecile/skills.git ~/Developer/skills
git clone git@github.com:glpecile/dotfiles.git ~/dotfiles
~/dotfiles/install.sh   # full machine setup; runs skills.sh at the end
~/dotfiles/skills.sh    # skills only
```

Keep both paths: `skills.sh` links from `~/Developer/skills` and `~/dotfiles`. Cloning alone links nothing, so the install is not done until `skills.sh` has run.

`skills.sh` is idempotent:

1. Symlinks `~/Developer/skills/skills/*` and `~/dotfiles/skills/*` into `~/.agents/skills/`, `~/.claude/skills/`, and the skills dir of each installed agent (Cursor, Codex, OpenCode). Edits in either repo are live everywhere at once.
2. Prunes symlinks into either repo that no longer resolve.
3. Installs each line of `~/dotfiles/skills.manifest` from its upstream repo via `bunx skills add`. Without `bunx` it skips this step and says so.

Run it again after adding, renaming, or removing a skill in either repo, or editing `skills.manifest`.

## Where a skill goes

- Written here → `skills/` in this repo. `agents/openai.yaml` inside a skill is Codex display metadata.
- Third-party with an installable upstream → a line in `~/dotfiles/skills.manifest`.
- Third-party without one → `~/dotfiles/skills/`. Never in this repo, which is public and MIT-licensed.
