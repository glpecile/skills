---
name: figma-self-review
description: Self-review UI that was already built from a Figma frame. Render the frame through the Figma MCP, screenshot the build with agent-browser, pixel-diff the two, trace each hot region to an exact property mismatch, fix it, and repeat. Use when the user asks to compare a build with its design, check whether it matches Figma, or self-review against Figma, or after build-design or figma-design-to-code finish. Not for building from a design (build-design) or for adding screenshots to a PR (before-and-after).
compatibility: Requires the Figma MCP server, agent-browser 0.38+ (diff screenshot), and a running local build.
---

# Figma self-review

This skill owns one loop: Figma render in, pixel diff out, fix, repeat. Reading the design and mapping it to tokens belong to `build-design` and `figma-design-to-code`. Browser sessions and capture belong to `agent-browser`. Load `agent-browser skills get core --full` before the first capture.

The design decides. A difference is either something you fix or something you report. You never resolve one by changing the design's intent.

## 1. Pin the targets

For each frame in scope, record:

- **Figma.** The file key and node from the URL. Write `1-2` in the URL as `1:2`, and on a branch URL pass the branch key as the file key. A URL with no `node-id` has no target, so list frames with `get_metadata` and ask which ones ship. Call `create_session` before any other file tool.
- **Frame size.** Width and height from `get_metadata`, in Figma units.
- **Build.** The local URL, the route state that shows this frame, and a CSS selector for the component root, which is the element that corresponds to the frame.

Frames of one piece at different widths are breakpoints, so pin each width separately.

## 2. Capture both at the same scale

Pixel diffs only work on images that have the same dimensions and the same scale. Resampling either image to force a match creates diff pixels the build did not cause, so never resize.

1. Set the viewport width to the frame width with `agent-browser set viewport <w> <h>`. Use the frame height, or the current height when the frame is a component and not a full screen.
2. Read the scale with `agent-browser eval 'devicePixelRatio'`.
3. Export the frame with `download_assets`, setting `defaultFormat: "png"` and `defaultScale` to that ratio. Download the `export` URL right away, because it expires: `curl -sL "<url>" -o captures/figma/<frame>.png`. Use `get_screenshot` with `maxDimension` set to the longer frame edge times the ratio only when `download_assets` fails.
4. Bring the build into the state the frame shows, including scroll position, open menus, and hover. Use the same copy and images when the frame draws specific ones and the app allows it.
5. Screenshot the root only: `agent-browser screenshot '<selector>' captures/build/<frame>.png`. A whole-page screenshot compares page chrome the frame does not contain.
6. Compare dimensions with `sips -g pixelWidth -g pixelHeight` on both files.

```text
Same width and height?
├── Yes → step 3
└── No → the size is the first finding
    ├── Width off → the container width, padding, or max-width is wrong. Fix it, then capture again.
    └── Only height off → something inside is too tall or too short. Compare stacked children
        top to bottom (step 3, values only) until you find the one that is off. Fix it, then capture again.
```

Keep both files under `captures/`, in paths with no spaces, so `before-and-after` can use them later.

## 3. Diff, then locate

```bash
agent-browser diff screenshot --baseline captures/figma/<frame>.png \
  -s '<selector>' -o captures/diff/<frame>.png -t 0.1
```

Keep the threshold at 0.1 or above. Figma and Chromium antialias text differently, so a threshold of 0 marks every glyph.

The diff is a locator, not a verdict. Never adjust a value to make the pixels go away. Each hot region becomes a finding through these steps:

1. Look at the three images together: Figma, build, and diff. Name the element under the region.
2. Find that layer's node id in `get_metadata`, then read its exact values with `get_design_context` on that node.
3. Read the built element's values with `agent-browser eval`. Use `getComputedStyle` for color, font, radius, and padding. Use `getBoundingClientRect` on neighbors for gaps and offsets.
4. Write the finding as a property, a design value, and a built value, such as "Card gap: design 16px, built 12px". A note like "the bottom looks off" is not a finding, so go back to step 2.

Walk the regions from largest to smallest. A wrong container width or gap moves everything after it, so fixing it often clears smaller regions downstream.

## 4. Classify every finding

```text
Is the difference in your code?
├── No: dynamic data, user images, or live text the frame shows as a placeholder → Ignore. List under Content.
├── No: Figma and browser rendering only, such as text antialiasing, subpixel offsets of 1px or less,
│   or shadow rasterization when blur, offset, and color match → Ignore. List under Rendering.
└── Yes
    ├── The value maps to a token and you used a different token or a raw value → Fix
    ├── There is no exact token, and you used the nearest one within 2px or on the same color step → Report as Rounded
    ├── The nearest token is more than 2px away or on a different color step → Ask. Do not add a token.
    ├── The design breaks an accessibility, contrast, or focus rule → Keep the design and report the conflict
    └── Anything else you built differently → Fix
```

Fix only the files that render this frame. A diff that reaches other screens is out of scope.

## 5. Loop with a bound

After the fixes, capture the build again and diff again. Do not capture Figma again unless the frame changed.

Stop when every remaining region is classified as Content, Rendering, Rounded, Ask, or Conflict, or after 3 rounds. Without the bound, the loop keeps chasing font rendering it can never remove. If round 3 still has fixable findings, report them as open. Do not start round 4.

## 6. Report

Use the same table as `build-design`:

| Element | Design | Built | Status |
| --- | --- | --- | --- |
| Card gap | 16px | `gap-4`, 16px | Fixed (was `gap-3`) |
| Title size | 15px | `text-sm`, 14px | Rounded to token |
| Avatar | Photo | User image | Content |

Then add one line per frame with the width, the scale, the number of rounds, and the path to the last diff image. List any Ask or Conflict items as questions for the user.

To put the comparison on the PR, pass the pair to `before-and-after`: `--before captures/figma/<frame>.png --after captures/build/<frame>.png --label "Figma vs build"`. Before is the design. Only do this when the user asks for it.

## Before you finish

| You notice | Fix |
| --- | --- |
| A diff run on images with different dimensions | Fix the size first (step 2) |
| An image resized or cropped to make dimensions match | Delete it and capture at the right viewport and scale |
| A finding with no design value from `get_design_context` | Read the node |
| A value changed because the diff went quiet, with no measured mismatch | Revert it |
| A raw value or a new token added to match a pixel | Use the nearest token and report it as Rounded, or ask |
| A 4th round started | Stop and report the open findings |
| A match reported without a build screenshot | Capture it, or say the frame was not compared |
