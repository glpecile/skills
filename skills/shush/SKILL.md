---
name: shush
description: Delete code comments that narrate or justify, and keep only the few that must stay. Use when the user asks to remove or clean up comments, or says "shush" or "/shush".
---

# Shush

A comment that argues for a choice is an opinion frozen in the file. The next agent reads it as fact, repeats it, and defends code that may no longer need defending. Code says what it does. Reasons go in the commit message or the chat, where they carry a date and an author.

## Scope

Use the files or diff the user names. Otherwise use the current diff against the base branch (default `main`), working tree included. Never touch comments outside the scope.

## Decide each comment

Walk this tree for every comment in scope, top to bottom. The first match wins.

```
Is it a shebang, an encoding line, or a legal or license header?
└── Yes → keep
Is it a tool directive (shellcheck, eslint-disable, @ts-expect-error, @ts-ignore, noqa, prettier-ignore, type: ignore)?
├── The rule is style-only or formatting → keep
└── The rule catches bugs (types, unused results, unsafe calls) → delete it and fix the code it hides; if the fix is out of scope, flag the symbol RESHAPE
Is it a contract: a doc comment on an exported API, a usage line for a function or script, or a one-line file header that says what the file does?
└── Yes → keep, but cut any sentence that argues for the design
Is it commented-out code?
└── Yes → delete (git has it)
Does it explain why the code is this way: a cause, a constraint, a risk, or an option not taken?
└── Yes → delete, then go to "Reason comments" below
Is it a TODO or FIXME?
├── It links a ticket → keep the link, drop the prose
└── No link → delete and list it in the report
Does it say what an opaque value means (a magic number, a flag, a defaults key)?
└── Yes → keep, as a label of 8 words or fewer, numbers included
Is it a header in a config file or a settings script that groups 3 or more lines?
└── Yes → keep
Default → delete (narration, restated names, headers over 1 or 2 lines, banners in code, changelogs, author notes)
```

Reason words are a hint, not the test: "because", "since", "so that", "to avoid", "instead of", "IMPORTANT", "do not remove", "workaround", "hack", "for now". A comment with none of them can still be a reason ("X has no config file; settings travel as an export"). A label that says what a value does is not a reason, even with "don't" in it ("don't rearrange Spaces by recent use").

When unsure whether a keep branch applies, delete. A missing comment costs one `git blame`. A wrong one misleads every reader after you.

## Reason comments

After you delete a reason, look at the code it guarded. Ask: would a reader without the comment remove or "simplify" this code and break something?

```
Would the code look removable without the comment?
├── No → done
└── Yes
    ├── A name can carry it (rename the variable, extract a function named for what it prevents) → do that
    ├── A check can carry it (test, assertion, CI lint) and it fits in scope → offer it to the user, add it only on approval
    └── Neither → list the symbol and the reason in the report as RESHAPE, so the user can put it in the commit message
```

Never rewrite a reason into a shorter reason. Never move it to another comment, a README or a docstring. The reason leaves the code entirely.

## Edits

- A trailing comment: delete the comment and its leading spaces, keep the code.
- A deletion that leaves 2 or more blank lines in a row: collapse them to 1.
- Change no code, except the renames and extractions the tree above calls for.
- Do not invent reasons. A RESHAPE line repeats what the deleted comment claimed and says the claim is unverified.

## Report

- Files touched and the number of comments deleted.
- Comments kept, each with its branch from the tree (license, directive, contract, ticket link, label, config header).
- RESHAPE flags: one line each, symbol and the deleted claim.
- TODOs deleted without a ticket.
