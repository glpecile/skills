---
name: review-and-ship
description: Review, simplify, validate, and publish scoped code changes. Run the harness's built-in code review and a delegated read-only complexity review, fix findings, then commit and push. Create a PR if none exists, merge it, then return to main and pull. Use when the user says "review-and-ship", "/review-and-ship", "review and ship", or asks to review, simplify, and publish changes. Do not trigger for review-only requests or a push or merge request that does not ask for the review workflow.
disable-model-invocation: true
compatibility: Requires the ponytail-review skill, a subagent tool, git, and GitHub CLI gh for PR operations. Uses the harness's built-in review skill (code-review in Claude Code) when one exists.
---

# Review and ship

## Required dependency

The default complexity reviewer is `ponytail-review`, installed separately.
The workflow name does not depend on the reviewer. Before starting the workflow,
load that skill and confirm a subagent tool is available. If either prerequisite
is missing, stop and report it. Do not edit, commit, push, or merge anything,
and do not substitute an inline review.

The correctness reviewer is the harness's built-in review skill: `code-review`
in Claude Code. Check the available skills for it before starting. Without one,
step 2 delegates a correctness review subagent instead, and the final response
says which reviewer ran.

Own the review-to-ship workflow. Delegate the complexity review, apply the fixes
yourself, and verify before publishing. Invoking this skill authorizes scoped
commits, pushes, PR creation, PR comments, and merging. It does not authorize unrelated
changes or bypassing repository protections.

## 1. Establish the target

- Read repository instructions. Inspect the branch, status, staged and unstaged
  diffs, untracked files, upstream, and remotes before changing anything.
- Resolve an explicitly named PR first. Otherwise, look for an open PR whose
  head matches the current branch and repository. Record its number, head SHA,
  head repository, head branch, and base branch. Do not confuse forks or similarly
  named branches. If the checkout does not match the requested PR, switch only
  when local changes can be preserved safely; otherwise stop and report it.
- Define the shipping scope from the user's task and its changes. Include
  uncommitted work in that scope, not every dirty file. If ownership is unclear,
  ask which changes to include.
- Without a PR, resolve the intended base branch from the user's request or the
  repository's default branch. If on the default or a protected branch, create
  a feature branch before committing or pushing, preserving local work.
- For a PR, review the full branch diff against its base plus scoped local
  changes and untracked file contents. Without a PR, compare against the intended
  base to include unpublished commits as well as scoped local changes.
  Ask if there is no reliable comparison base. A clean working tree is not proof
  that there is nothing to review.
- If there is no change to review or publish and no open PR, report that and stop.

## 2. Run both reviews

Run the two reviews in parallel. They look for different things, so neither
one replaces the other.

**Correctness.** Invoke the harness's built-in review skill on the same target:
in Claude Code, `code-review` with the PR number, or with no argument for the
local diff. Never pass `--comment`, because it posts to the PR before you have
triaged the findings. Never pass `--fix`, because step 3 applies fixes after
triage. Without a built-in review skill, spawn a second read-only subagent with
the same scope and an instruction to review correctness and security only.

**Complexity.** Spawn a read-only review subagent with a self-contained prompt. Include:

- The repository path, repository instructions, comparison base, and exact
  scoped files or diff, including relevant untracked files.
- The actual loaded `ponytail-review` instructions, or an accessible path with
  an explicit instruction to read them. Naming the skill alone does not load it
  into a fresh subagent's context.
- An instruction to review over-engineering only and use that skill's finding
  format. The subagent must not edit, commit, push, merge, or spawn more agents.

Wait for both results before making edits. Neither review's approval replaces
tests or required reviews. Keep the repository's other review methods in place.
If the diff touches web or React Native UI files (components, styles,
templates) and `ui-review` is available, run it as an extra review. If it adds
or changes motion (transitions, keyframes, springs, animation libraries) and
`review-animations` is available, run that too. Skip both for game engines,
canvas or shader rendering, and other non-DOM UI, where their rules misfire.
Resolve blocking findings from every review before shipping. When the two
reviews conflict, such as a deletion that would remove a guard the correctness
review asked for, correctness wins.

## 3. Fix and verify

Apply each finding with the smallest behavior-preserving change. Inspect callers
and tests before removing code. If a finding would break a requirement, explain
why and give that evidence to the reviewer rather than following it blindly.

Then sweep the scoped diff for slop comments and delete them: comments that
restate the next line, narrate the change ("now uses X", "added for Y", "fixed
bug"), address the reviewer, or leave TODOs nobody owns. A comment stays if it
says why, warns about a non-obvious constraint, or matches the file's existing
comment style. Touch only comments the scoped diff added or changed; leave the
rest of the file to its owners. If `unslop` is available, apply its patterns to
the comments that stay and to the commit message and PR body in steps 4 and 5.

Run the repository's relevant tests, lint, and type checks, plus `git diff --check`.
Use at least one smoke test or runnable self-check when no test suite exists.
Do not delete tests to satisfy the complexity review. Report unavailable checks;
do not claim they passed. Stop shipping if validation fails or cannot establish
that the changes work.

After edits, rerun each review that had actionable findings on the updated full
scoped diff, and include the disposition of earlier findings. Allow at most three review rounds total.
Ship only when no actionable findings remain. If the reviewer keeps finding
issues or a disagreement remains unresolved, stop with the remaining findings.

## 4. Commit and push

- Inspect the final diff for accidental changes and secrets. Stage only the
  scoped files or hunks. Never use blanket staging when unrelated work exists.
  Ensure the commit excludes unrelated changes already in the index; if that
  cannot be done safely, stop and ask rather than altering the user's staging.
- Commit scoped uncommitted work and review fixes with a descriptive message.
  If there are no such changes, do not create an empty commit.
- Push unpublished scoped commits to the verified branch and remote, setting
  an upstream if needed. Confirm what commits will be published. Never force
  push or rewrite existing commits. A rejected push is a blocker, not permission
  to reset or rebase the user's work.
- Do not publish directly to the default or a protected branch unless the user
  explicitly requested that destination.

## 5. Create or reuse a PR, then merge

After pushing, look again for an open PR matching the verified head branch and
repository, so a PR opened during the review is reused rather than duplicated.
If none exists, create one with `gh pr create`, explicitly setting the base and
head. Use a descriptive title and summarize the scoped changes and validation
in the body. Record the new PR's number and URL. If creation fails, stop and
report the blocker; do not merge locally or fall back to a direct push.

Re-fetch PR metadata. Verify that its base matches the reviewed base and that the
remote head SHA equals the reviewed local HEAD. Wait for required checks on that SHA, and inspect mergeability,
draft status, and required approvals. Stop on failed checks, conflicts, missing
approvals, or a changed head. Never use an admin override or dismiss reviews.

Before merging, post a PR comment with `gh pr comment <number> --body-file <file>`
summarizing the final scoped changes, review fixes, validation results, and any
remaining limitations, so the PR records what is being shipped. Confirm the
comment was posted successfully; if posting fails, stop before merging and
report the blocker.

Squash and merge PRs by default. Use another merge method only when the user
explicitly requests it. If the repository does not allow squash merging, stop
and report the blocker rather than choosing another method. Merge the explicit
PR number with `gh pr merge <number> --squash --match-head-commit <reviewed-sha>`
so a concurrent push cannot silently change what gets merged. Replace `--squash`
only for an explicitly requested method. Respect merge queues. Auto-merge or queue entry
is pending, not a completed merge. Confirm the PR's actual merged state before
reporting success. Do not delete branches unless asked.

After the merge succeeds, return to `main` and run `git pull --ff-only`. If the
repository has no `main`, use its default branch. Preserve unrelated local work;
do not stash, reset, clean, discard changes, or remove worktrees to make the switch
or pull succeed. If switching or pulling is unsafe, report that the PR merged
but local cleanup is blocked.

## Final response

Report which reviewers ran, the fixes, validation results, commit and push status, and PR merge status
or blocker. Include the PR link when available and say whether the checkout is
back on updated `main`. Do not describe a queued merge as merged.
