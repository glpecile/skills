---
name: delegate
description: Plan at session level, delegate implementation to cheaper model subagents, verify in a goal loop. Use when the user asks to delegate work, split plan/implementation across models, or run a goal loop with subagents.
---

# Delegate

The session model plans, reviews, and verifies. It never writes implementation
code inline — cheap models type, expensive models judge. Inline implementation
wastes the planner's context and costs more per token for work sonnet does fine.

## Loop

1. Write the plan as numbered tasks. Each task gets an acceptance check —
   a command that exits 0 (test, typecheck, grep). A task without a runnable
   check cannot be delegated; split or rewrite it until it has one.
2. For each task, spawn `Agent` with `model: "sonnet"`. The prompt must be
   self-contained: files to touch, the change, the check command. The subagent
   has none of your context — anything not in the prompt does not exist.
3. Run the acceptance check yourself. Never trust the subagent's claim that
   it passed — subagents report success optimistically.
4. Check fails → re-delegate once with the failure output appended.
   Fails again → do that task inline yourself. Never a third delegation:
   two failures means the task needs judgment, not retries.
5. All checks pass → one final review of the whole diff at session level.

Independent tasks go out in one message so they run in parallel. Tasks that
touch the same files run sequentially — parallel edits to one file conflict.

## Model choice per task

Mechanical (rename, apply pattern, boilerplate, port) → haiku
Normal implementation against a clear spec → sonnet
Design decisions, ambiguous requirements, debugging → don't delegate; do inline
