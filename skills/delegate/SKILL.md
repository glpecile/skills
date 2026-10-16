---
name: delegate
description: Plan at session level, delegate implementation to cheaper model subagents, verify in a goal loop. Use when the user asks to delegate work, split plan/implementation across models, or run a goal loop with subagents.
---

# Delegate

The session model plans, reviews, and verifies. It never writes implementation
code inline — cheap models type, expensive models judge. Inline implementation
wastes the planner's context and costs more per token for work sonnet does fine.

## Loop

1. Write the plan as numbered tasks. Each task gets:
   - **Files**: every path it may create, edit, or delete.
   - **Blocked by**: the tasks it needs output from, plus any earlier task
     that lists one of the same files. Two tasks in flight never share a file,
     so every changed path maps to exactly one task.
   - **Check**: a command that exits 0 (test, typecheck, grep). A task without
     a runnable check cannot be delegated; split or rewrite it until it has one.
2. Snapshot the working tree, untracked files included, without touching the
   real index:
   `GIT_INDEX_FILE="$(git rev-parse --git-dir)/delegate.idx" sh -c 'git add -A && git write-tree'`
   Save the printed tree hash.
3. Dispatch the frontier: every task whose blockers have all passed, in one
   message so they run in parallel. Spawn each on a cheaper model (Claude Code:
   `Agent` with `model: "sonnet"`; elsewhere, the harness's subagent tool and
   its mid-tier model). The prompt must be self-contained: files, the change,
   the check command. The subagent has none of your context — anything not in
   the prompt does not exist.
4. When the batch returns, snapshot again and run
   `git diff --name-only <before> <after>`. Every path must belong to one
   task's Files. Revert any other path and treat its owner's task as failed —
   a passing check does not show the subagent stayed in scope.
5. Run each task's check yourself. Never trust the subagent's claim that it
   passed — subagents report success optimistically.
6. Check fails → re-delegate once with the failure output appended.
   Fails again → do that task inline yourself. Never a third delegation:
   two failures means the task needs judgment, not retries.
7. Back to step 2 with the new frontier until no tasks remain.
8. All checks pass → one final review of the whole diff at session level.

## Model choice per task

Mechanical (rename, apply pattern, boilerplate, port) → cheapest tier (haiku)
Normal implementation against a clear spec → mid tier (sonnet)
Design decisions, ambiguous requirements, debugging → don't delegate; do inline
