---
name: ponytail-merge
description: Delegate ponytail-review to a read-only subagent, fix its findings, validate, then commit and push the scoped changes. Merge the current PR when one exists, then return to main and pull. Use when the user says "ponytail-merge", "/ponytail-merge", "ponytail merge", or asks to review, simplify, and ship changes with ponytail. Do not trigger for review-only requests or ordinary merge requests that do not ask for ponytail.
compatibility: Requires the ponytail-review skill, a subagent tool, git, and GitHub CLI gh for PR operations.
---

# Ponytail merge

## Required dependency

`ponytail-review` must be installed separately. Before starting the workflow,
load that skill and confirm a subagent tool is available. If either prerequisite
is missing, stop and report it. Do not edit, commit, push, or merge anything,
and do not substitute an inline review.

Own the review-to-ship workflow. Delegate the complexity review, apply the fixes
yourself, and verify before publishing. Invoking this skill authorizes scoped
commits, pushes, and merging an existing PR. It does not authorize unrelated
changes, creating a PR, or bypassing repository protections.

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
  ask which changes to include. Preserve unrelated staged changes too.
- For a PR, review the full branch diff against its base plus scoped local
  changes and untracked file contents. Without a PR, use the upstream or known
  branch point to include unpublished commits as well as scoped local changes.
  Ask if there is no reliable comparison base. A clean working tree is not proof
  that there is nothing to review.
- If there is no change to review or publish and no open PR, report that and stop.

## 2. Delegate the review

Spawn a read-only review subagent with a self-contained prompt. Include:

- The repository path, repository instructions, comparison base, and exact
  scoped files or diff, including relevant untracked files.
- The actual loaded `ponytail-review` instructions, or an accessible path with
  an explicit instruction to read them. Naming the skill alone does not load it
  into a fresh subagent's context.
- An instruction to review over-engineering only and use that skill's finding
  format. The subagent must not edit, commit, push, merge, or spawn more agents.

Wait for the result before making edits. `ponytail-review` is not a correctness
or security review, and its approval does not replace tests or required reviews.
Keep the repository's default review methods in place: perform the normal
correctness and security review, and use applicable specialist reviews such as
`ui-review` for interface changes. Ponytail adds a complexity review; it does
not replace those reviews. Resolve their blocking findings before shipping.

## 3. Fix and verify

Apply each finding with the smallest behavior-preserving change. Inspect callers
and tests before removing code. If a finding would break a requirement, explain
why and give that evidence to the reviewer rather than following it blindly.

Run the repository's relevant tests, lint, and type checks, plus `git diff --check`.
Use at least one smoke test or runnable self-check when no test suite exists.
Do not delete tests to satisfy the complexity review. Report unavailable checks;
do not claim they passed. Stop shipping if validation fails or cannot establish
that the changes work.

After edits, rerun the review subagent on the updated full scoped diff and include
the disposition of earlier findings. Allow at most three review rounds total.
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
- Without a PR, stop after the push. Do not create a PR or merge locally. Ask
  before publishing directly to the default or a protected branch unless the
  user explicitly requested that destination.

## 5. Merge an existing PR

Re-fetch PR metadata after pushing. Verify that the remote head SHA equals the
reviewed local HEAD. Wait for required checks on that SHA, and inspect mergeability,
draft status, and required approvals. Stop on failed checks, conflicts, missing
approvals, or a changed head. Never use an admin override or dismiss reviews.

Use the repository's configured merge method. If none is specified and multiple
methods are allowed, ask rather than guessing. Merge the explicit PR number with
`gh pr merge` and `--match-head-commit <reviewed-sha>` so a concurrent push cannot
silently change what gets merged. Respect merge queues. Auto-merge or queue entry
is pending, not a completed merge. Confirm the PR's actual merged state before
reporting success. Do not delete branches unless asked.

After the merge succeeds, return to `main` and run `git pull --ff-only`. If the
repository has no `main`, use its default branch. Preserve unrelated local work;
do not stash, reset, clean, discard changes, or remove worktrees to make the switch
or pull succeed. If switching or pulling is unsafe, report that the PR merged
but local cleanup is blocked.

## Final response

Report the fixes, validation results, commit and push status, and PR merge status
or blocker. Include the PR link when available and say whether the checkout is
back on updated `main`. Do not describe a queued merge as merged.
