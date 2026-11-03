---
name: react-taste
description: Opinionated DOs and DON'Ts for React code, gated by the installed React version, covering effects, state placement, hidden UI with Activity, async state with useTransition, Suspense loading states, component APIs, and memoization under React Compiler. Use when writing, editing, or reviewing React or React Native components and hooks, and whenever a change adds useEffect, useState, useMemo, useCallback, setTimeout, or an isLoading branch.
---

# React taste

Most React bugs come from a value with two owners: state that copies a prop,
a query result copied into a form, a flag set around an `await`. Each copy
must be kept in sync by hand, and an effect is usually the hand. Before you
write a hook, find the one owner of the value. Walk the trees below for every
`useEffect`, `useState`, `setTimeout`, and loading flag you add or touch.

## 0. Check the React version

Read the installed version first: `node_modules/react/package.json` or the
lockfile, not the range in `package.json`. A rule marked with a version below
applies only at that version or later. Below it, use the fallback. An API
from a newer React fails at runtime or silently does something else: in React
18, `isPending` from an async transition ends at the first `await`.

| API | Needs | Below that version |
|---|---|---|
| `use()` | 19 | The query library's Suspense hook (`useSuspenseQuery`). |
| Async function in `startTransition`, `useActionState`, `useOptimistic` | 19 | `useMutation`: its `isPending`, `error`, and `onMutate` for optimistic updates. With no mutation hook, a pending flag set in `try`/`finally` is the one allowed exception. Name the version in a comment. |
| `<Activity>` | 19.2 | Lift the state that must survive to the parent (section 2). |
| `useEffectEvent` | 19.2 | Keep the value in the effect's dependencies and accept the restart. Never silence the exhaustive-deps lint rule instead. |
| `useSyncExternalStore`, `useTransition` | 18 | Below 18, tell the user that most of this skill does not apply, and follow the project's patterns. |

## 1. Effects and timers

Read https://react.dev/learn/you-might-not-need-an-effect before you write or
review an effect. `useEffect` subscribes to a system outside React and cleans
up. `setTimeout` waits for wall-clock time. Neither one derives state,
sequences UI, or waits for an animation.

```
Why do you want this effect?
├── To compute a value from props or state
│   └── Compute it during render. Delete the state variable that held it.
├── To react to a user action (press, submit, change)
│   └── Do the work in that event handler.
├── To reset state when a prop changes
│   └── Render the component with key={thatProp}.
├── To fetch data
│   └── Use the project's query library (TanStack Query, SWR, a router
│       loader) or `use()` with Suspense (19+). Never fetch into useState.
├── To keep a form field in sync with another field
│   └── react-hook-form: `rules.deps`, or `getFieldState` inside `validate`.
│       Never call `trigger` from an effect.
├── To read an external store (browser API, third-party store)
│   └── useSyncExternalStore.
├── To wait for an animation or a layout step
│   └── Use the animation library's completion callback or a CSS/Reanimated
│       transition. Never a timeout that guesses the duration.
└── To subscribe to an external system and clean up (socket, listener, SDK)
    └── An effect is correct. Tell the user why before you add it.
        Does it read a value that must not restart the subscription (a muted
        flag, a theme)? 19.2+: read it inside a useEffectEvent. Below 19.2:
        keep it in the dependencies. Never use useEffectEvent to drop a real
        dependency, because the effect then runs with stale input.
```

### A timeout is not a fix

`setTimeout(fn, 0)`, a small delay, `requestAnimationFrame`, or
`queueMicrotask` that makes the code "work" is an escape hatch, not a fix. It
hides an order problem: two owners of one value, work in the wrong place, or a
read before React commits. The bug comes back on a slower device or under
load. When you reach for one, stop and redesign:

```
What does the delay wait for?
├── State to update before you read it
│   └── Use the value you just computed in the handler, not the state.
├── A DOM node to exist (focus, measure, scroll)
│   └── A ref callback on that node.
├── The DOM to update inside the same handler before you scroll or focus
│   └── flushSync around the state update. This is rare; name the reason.
├── Another component to render or to set its state first
│   └── Two owners. Lift the state to one owner, or move the work to the
│       handler that starts both.
└── Real wall-clock time (debounce, a toast that closes, a retry backoff)
    └── A timeout is correct. Use the project's debounce or timer helper,
        and clear it on unmount.
```

Never add a timeout to make a test or a flaky render pass. If no branch above
fits, tell the user what order problem you see, and do not ship the delay.

When you edit code that already has an effect, walk the tree for it too. If it
lands on any branch except the last, propose its removal in your summary. An
effect copied forward is a sync bug kept alive.

If the project has `eslint-plugin-react-you-might-not-need-an-effect` (ESLint
or an oxlint JS plugin), keep it on. If it does not, suggest it once.

## 2. Where state lives

```
Does something already own this value?
├── It comes from the server
│   └── It stays in its query. Hold the id in state and resolve the item from
│       query data. Never copy the item into state, context, or a form.
├── It can be computed from props, other state, or query data
│   └── Compute it during render. It is not state.
├── It lives in the URL (tab, filter, page)
│   └── Read it from the router. Do not mirror it in state.
└── Nothing owns it (a draft, a selection, an open sheet)
    └── useState, in the lowest component that needs it.
```

A form holds only the user's edits over the fetched values. Pass the fetched
values as `defaultValues` or `values`, and do not write them into the form
from an effect.

### UI that hides and shows again

Read https://react.dev/reference/react/Activity before you hide a tab, a
sidebar, a sheet, or a step.

```
Must the UI keep its state (scroll, draft, open section) while hidden, or
load before the user opens it?
├── No, it starts fresh each time
│   └── {open && <Panel />}
└── Yes
    ├── 19.2+ → <Activity mode={open ? 'visible' : 'hidden'}><Panel /></Activity>
    └── Below 19.2 → Lift the state that must survive to the parent. Hide the
        panel with CSS only when its effects can keep running while hidden.
```

- Treat a hidden Activity as unmounted. React keeps its state and DOM but
  runs its effect cleanups. An effect that does work on mount and has no
  cleanup is a bug that Activity shows. Keep `<StrictMode>` on, because it
  unmounts and mounts Activity children in development and shows the missing
  cleanup.
- Hidden DOM keeps playing. Pause `<video>`, `<audio>`, and `<iframe>` in a
  `useLayoutEffect` cleanup.
- A hidden Activity pre-renders only data read through Suspense (`use()`, a
  Suspense query). Data fetched in an effect does not load until the panel is
  visible.

## 3. Async state

The pending flag, the result, and the error of a promise come from a hook that
owns the promise. Never from `setState` around `await`, `.then()`, or
`finally`. A hand-made `isLoading` drifts when the component unmounts, the
call throws, or two calls overlap.

```
What starts the promise?
├── A read of server data
│   └── useQuery / useSuspenseQuery (or the project's equivalent).
├── A write to the server
│   └── useMutation. Show progress on the trigger, not in a new
│       "Saving…" row.
├── A user action that does async work or a slow state update, and the
│   project has no mutation hook for it
│   └── useTransition (async function: 19+):
│         const [isPending, startTransition] = useTransition()
│         startTransition(async () => { await save(draft) })
│       A throw inside the transition goes to the nearest error boundary.
│       If the error must show inline next to the form, use useActionState
│       (19+).
└── The UI must show the result before the server confirms
    └── useOptimistic (19+), inside the same transition or action.
```

## 4. Loading and error states

Screens use Suspense and error boundaries, not `if (isLoading)` branches. A
branch per screen repeats the same three states and hides the failure of one
section behind the whole screen.

- Wrap each independently fetched section in its own Suspense and error
  boundary, so one failed source hides one section, not the screen.
- A skeleton keeps the frame of the resolved layout, so text and controls do
  not move when the data lands.
- Content stays mounted through a refetch, a pull-to-refresh, or a failed
  refresh. Show the refresh error next to the content.
- An empty list is a success with its own empty state. A disabled query is not
  loading. Never test for loading to show "no results".
- Aggregate status across several sources, and mutation progress, can still
  branch on state.

## 5. Component APIs

- Do not add a mode prop that picks a different tree or workflow
  (`isEpisode`, `kind: 'show' | 'season'`). Export two components or two hooks.
  A mode prop grows one branch per mode in every place the component renders.
  Props that describe state (`disabled`, `selected`) are fine.
- Extract an inline sub-layout only when a second screen needs it. One caller
  does not justify a component.
- With Tailwind, compose every `className` with the project's `cn()` helper
  (`clsx` + `tailwind-merge`), never a template literal, so a caller's class
  replaces the default instead of competing with it.

### Compound components

```
Does the caller arrange or change the parts of the component?
├── No, the layout is fixed
│   └── Plain props.
└── Yes
    ├── The parts share state (selection, open, index, active step)
    │   └── Compound component. The root holds the state in a context.
    │       Each part reads it through a hook. Attach the parts to the root
    │       as properties: Tabs.List, Tabs.Trigger, Tabs.Panel.
    └── The parts share no state
        └── children or named slot props. No context.
```

Signs that a component needs this split: one prop for each part
(`headerTitle`, `headerIcon`, `footerAction`), a `renderX` prop, a boolean
that hides a part (`showFooter`), or a config array (`items={[{ label, icon,
onPress }]}`) where callers need to change one item. Each new need adds
another prop, and the component grows a branch for each one.

- Never pass the index or the selected id to each part by hand. The context
  gives it to them.
- Never use `React.Children.map`, `cloneElement`, or a check on a child's
  type to give state to the parts. These break when a caller wraps a part in
  a fragment or in its own component.
- The hook in each part throws a clear error when the part renders outside
  its root (`Tabs.Trigger must be inside Tabs`). A missing context that
  returns `undefined` renders the wrong UI with no error.

## 6. Memoization

```
Is React Compiler on? (babel-plugin-react-compiler, or React 19 framework config)
├── Yes
│   └── Never write useMemo, useCallback, or React.memo. The compiler does it.
│       To opt out a component, add 'use no memo' and give the reason in the PR.
│       A component the compiler cannot compile ships unmemoized with no
│       warning, so run its lint or healthcheck on files you change.
└── No
    └── Add useMemo or useCallback only for a measured slow render, or for a
        value that a memoized child or a subscription needs stable. Name the
        reason in a comment.
```

## 7. Before you say done

- A console warning that your change causes (key, act, hydration, Reanimated)
  is a bug. Fix it before you ship.
- A rule here that a lint rule can enforce should be one. Name the rule in
  your summary when the project lacks it.
