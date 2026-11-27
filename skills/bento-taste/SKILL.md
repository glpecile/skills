---
name: bento-taste
description: My aesthetic for web interfaces, with soft color bento tiles, no decorative lines and small playful motion. Use when building, restyling or reviewing a web page or component that has no design of its own, or when the user asks for the bento look. Not for matching a Figma frame (build-design).
---

# Bento taste

The look: a compact page of soft, rounded tiles on warm white, each tile its own quiet color, black pill buttons, tight system type, and small motion that answers every touch. References are Apple, Linear and Benji Taylor's work. Emphasis comes from fill, color and motion, never from a line drawn around a thing.

If the project already has a design system or a design file, follow it. Use this skill only to fill the gaps it leaves.

## 1. Start with concepts, not a build

For a new page or a redesign, show 2 or 3 small concepts in this look and let the user pick one before you build the rest. A whole page in the wrong direction costs a full rebuild. Skip this step when the user already picked a direction.

These directions were rejected. Do not offer them:

- A poster look: one saturated brand color and condensed black type.
- A quiet minimal single column.
- Dark neon arcade.
- Serif editorial.
- Monospace terminal.

## 2. Layout: the bento grid

Put the content in a grid of tiles before you reach for sections or columns. Keep pages compact: a screen should show several tiles, not one hero.

```
A tile in a row is shorter or taller than the tile beside it. What do you do?
├── Desktop
│   ├── The content is short → stretch the tile to its peers' height. Never `align-self: start`.
│   ├── The content is long → cap it ("+3 more", a scroll area, `contain: size`) so it takes its peers' height.
│   ├── The tile is empty → the empty state fills the whole tile. Never a small box inside it.
│   └── A tile spans 2 rows → its edges end on the same lines as the tiles beside it.
└── Mobile (one tile per row)
    └── The tile has no peer. Drop fixed heights and let it take its content's height.
```

Why: a tile with empty space below its content reads as broken on desktop. On mobile the same rule wastes the screen.

## 3. Color

Put every color in CSS variables, one block per theme. Rules use only `var(--…)`. Never write a raw `oklch()`, hex or `rgb()` value in a component rule.

```css
:root {
  --page: oklch(98.5% 0.006 85);
  --ink: oklch(20% 0.01 85);
  --ink-muted: oklch(48% 0.01 85);
  --tile-peach: oklch(93% 0.04 55);
  --tile-sky: oklch(93% 0.035 235);
  --tile-sage: oklch(93% 0.035 150);
  --pill: oklch(18% 0 0);
  --pill-ink: oklch(98% 0 0);
}
.dark {
  --page: oklch(17% 0.005 85);
  --ink: oklch(95% 0.005 85);
  /* every variable again */
}
.tile { background: var(--tile-sky); color: var(--ink); }
```

Why: a theme or a whole palette can then change in one place, and two palettes can be compared side by side.

Ship light and dark from the first commit. Follow `prefers-color-scheme`. Add a theme toggle only when the user asks for one. Each tile gets its own soft color. Keep saturation low and let one pill or one icon carry the strong color.

## 4. No decorative lines

Never add:

- A colored top or left accent line on a dialog, a card or a selected item.
- An outline around a badge, a key hint or a secondary button.
- A divider line between items or sections.
- A border on a tile.
- Gridlines or axis lines on a chart. Label the values instead.

```
How do you show that this thing is different?
├── Selected or active → a background tint or a filled pill
├── Grouped → put the items in the same tile, or add space between groups
├── Secondary button → a tinted fill, or text only
├── A control with no border (checkbox, input) → a fill with 3:1 contrast against the tile
└── Keyboard focus → `:focus-visible` outline, only when nothing else shows focus
```

Each focusable element must show focus. Never set `outline: 0` without a fill or a ring to replace it.

Why: lines add noise and make a soft layout look like a form. Fill and space do the same job quietly.

## 5. Type and icons

- System font or an Inter-like sans. Tight tracking on headings, normal tracking on body text.
- Use more icons than a plain layout would: next to labels, in empty states, on pills. They carry the playful tone.
- Full-screen text cards are text only. No icon on them.

## 6. Motion

Every interactive element gets a small playful response. The tap does something useful, and it adds a little life:

- An empty state that focuses the input when tapped, and its art moves (dots that "type").
- An icon that turns or tilts slightly on hover.
- A new item that settles into place with a short blur and fade.
- A check that shows after a save, then fades out.
- Lists and tiles enter with a short stagger.

Rules for each one:

- Animate `opacity`, `color`, `filter: blur()` and `transform`: a small `rotate` or `scale` on icons, `scaleY` from the base for chart bars. Never animate `height` or `width`. Use 150–300 ms and ease-out.
- Stagger items by 40–60 ms, and keep the whole entry under 500 ms.
- Gate hover motion with `@media (hover: hover)`. Gate all motion with `prefers-reduced-motion`.
- Keep the motion on the element the user touched.
- Press feedback is a small scale-down of the pressed control. Never move a button sideways or up.

Never add:

- Zoom on whole surfaces, Ken Burns on images, shake, or a 3D tilt.
- Camera-like movement on full-screen visuals. Show energy there with hard cuts, color and timing.

Why: small motion on the touched element feels alive. Large motion on a surface confuses and adds nothing.

Text that changes in place (a clock, a count, a label that swaps) morphs with torph's `TextMorph`: `torph/react`, `torph/vue` or `torph/svelte`, or the `TextMorph` class from `torph` on a page with no framework. Never use keyed spans with `@starting-style` for this. `TextMorph` keeps a copy for screen readers and respects reduced motion.

## Review checklist

When you review a page in this look, check each item. A no is a finding.

- [ ] Tiles in a row have the same height on desktop. No tile has empty space below its content.
- [ ] No border, divider, outline, accent line or chart gridline except a `:focus-visible` ring.
- [ ] Each focusable element shows focus. Each control with no border has a fill with 3:1 contrast.
- [ ] Each color in a rule is a `var(--…)`. Light and dark both work.
- [ ] Each interactive element has a small response, gated by `(hover: hover)` and `prefers-reduced-motion`.
- [ ] No zoom, shake or tilt. Press feedback does not move the control.
- [ ] Text that changes in place uses `TextMorph`.
