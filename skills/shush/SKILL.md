---
name: shush
description: Delete code comments that narrate or justify, and keep only the few that must stay. Use when the user asks to remove or clean up comments, or says "shush" or "/shush".
---

# Shush

A comment that argues for a choice is an opinion stored in the code. The next agent reads it as fact, repeats it, and defends code that may no longer need defending. Code says what it does. Reasons go in the commit message, the PR body or the chat, where they carry a date and an author.

## Scope

Use the files or diff the user names. Otherwise use the diff against the PR's base branch, or the repo's default branch when there is no PR, working tree included. In a diff, only comments on added or changed lines are in scope. A comment on an unchanged line stays, even in a changed file. Skip generated and vendored files.

Edit comments only. Never change code. A change the code needs goes in the report as a RESHAPE line.

## Decide each comment

Walk this tree for each comment in scope, top to bottom. The first match wins.

```
Is it a shebang, an encoding line, or a legal or license header?
└── Yes → keep
Does a tool read it (directive, pragma, magic comment, JSDoc type, generated-file marker)?
├── It suppresses a rule that catches bugs (types, unused results, unsafe calls) → keep, delete any reason text after it, flag RESHAPE: the fix that removes it
└── Any other → keep, delete any reason text after it
Is it a contract: a doc comment on an exported API, a usage line for a function or script, or a file header of 1 or 2 lines that says what the file does or what a caller can rely on (idempotent, safe to re-run)?
└── Yes → keep; cut each sentence that argues for the design and run it through "Reason comments"
Is it commented-out code?
└── Yes → delete
Is it a TODO or FIXME?
├── It names a ticket → keep only the marker and the ticket: TODO(HU-123)
└── No ticket → delete, list it in the report
Does it say what an opaque value means (a magic number, a flag, a settings key)?
└── Yes → keep only the meaning, 8 words or fewer, each number counts as a word; run any reason in it through "Reason comments"
Does it say why the code is this way: a cause, a constraint, a risk, an option not taken, or a link that explains one?
└── Yes → delete, then "Reason comments"
Is it a header in a config file or a shell setup file (.zshrc, .bashrc, a defaults write script) that groups 3 or more lines?
└── Yes → keep
Default → delete (narration, restated names, headers that group only 1 or 2 lines, banners, changelogs, author notes)
```

When unsure whether a keep branch applies, delete. A missing comment costs one `git blame`. A wrong one misleads each reader after you.

## Reason comments

```
Without the comment, would a reader remove or "simplify" the code and break something?
├── No → done
└── Yes → flag RESHAPE: the symbol, the deleted claim marked unverified, and the change that makes the code say it (a rename, an extracted function, a test, an assertion)
```

A deleted reason ends in one place: a RESHAPE line in the report. The caller puts RESHAPE lines in the commit message and the PR body.

## Example

Before:

```ts
// Map, not an object, because keys can be numbers
const seen = new Map<number, User>();
// TODO(HU-123): remove once the flag ships
const RETRY_MS = 1500; // backoff ms, don't lower, API rate limit
```

After:

```ts
const seen = new Map<number, User>();
// TODO(HU-123)
const RETRY_MS = 1500; // backoff ms
```

Report: `RESHAPE RETRY_MS: "don't lower, API rate limit" (unverified). Rename to RATE_LIMIT_BACKOFF_MS.` The Map line needs no RESHAPE: no reader would swap a typed Map for an object.

## Report

- Files touched and the number of comments deleted.
- Comments kept, each with its branch (license, tool, contract, ticket, label, settings header).
- RESHAPE lines: the symbol, and the deleted claim or the directive kept, and the change.
- TODOs deleted without a ticket.
