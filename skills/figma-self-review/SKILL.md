---
name: figma-self-review
description: Self-review UI that was already built from a Figma frame. Render the frame through the Figma MCP, screenshot the build with agent-browser, pixel-diff the two, trace each hot region to an exact property mismatch, fix it, and repeat. Use when the user asks to compare a build with its design, check whether it matches Figma, or self-review against Figma, or after build-design or figma-design-to-code finish. Not for building from a design (build-design) or for adding screenshots to a PR (before-and-after).
compatibility: Requires the Figma MCP server, a running local build, and agent-browser 0.38+ (diff screenshot) or another headless browser with ImageMagick 7 for diffing.
---

# Figma self-review

This skill owns one loop: Figma render in, pixel diff out, fix, repeat. Reading the design and mapping it to tokens belong to `build-design` and `figma-design-to-code`. Browser sessions and capture belong to `agent-browser`. Before the first capture, run `agent-browser skills get core --full` and read its output.

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
6. Compare dimensions with `magick identify -format '%wx%h\n'` on both files (`sips -g pixelWidth -g pixelHeight` on macOS without ImageMagick).

```text
Same width and height?
├── Yes → step 3
└── No → the size is the first finding
    ├── Width off
    │   ├── Your code sets it (container width, padding, max-width) → Fix it, then capture again.
    │   └── A design-system layout sets it → Ask (step 5). Keep it, and diff the inner pieces
    │       separately (step 4, "One offset hides everything after it").
    └── Only height off → something inside is too tall or too short. Compare stacked children
        top to bottom (step 3) until you find the one that is off. Fix it, then capture again.
```

Keep both files under `captures/`, in paths with no spaces, so `before-and-after` can use them later.

If agent-browser cannot start, use any headless browser that can set an exact viewport and deviceScaleFactor, for example Playwright WebKit in the repo's own scratch harness. Set deviceScaleFactor to the export scale. Record which browser you used, because the report names it.

## 3. Compare structure before pixels

A pixel diff shows where the images differ. It never tells you that a column is missing. Check structure first, because a wrong harness or a wrong count turns every later finding into noise.

1. **Verify the harness.** Read the built text's computed `font-size` and `letter-spacing` with `getComputedStyle` and compare them with the design's text values. A harness that renders at 14px while the app renders at 16px produces findings the real screen does not have. Fix the harness before going on.
2. **Count.** From `get_metadata`, count the frame's table columns, cells, list items and slots, and compare each count with the built DOM. In a test run, Figma had 6 table columns and the build had 5, and the pixel diff never pointed at it. A count mismatch is a finding. Fix it before the first diff.
3. **Widths and offsets.** For each child of the root, compare its width and x from `get_metadata` with `getBoundingClientRect` on the built element, measured from the root's left edge. For tables and grids, read the header-cell widths from `get_metadata` and compare them with `getBoundingClientRect` on the built `th` elements.
4. **Truncation.** A cell whose text ends in an ellipsis has `scrollWidth` equal to `clientWidth`, so an overflow check on the cell misses it. For each text node in a fixed-width column, clone the leaf element, append the clone hidden and unconstrained (`position:absolute; visibility:hidden; width:auto; max-width:none; white-space:nowrap`), and read its width. Compare that natural width with the content width available in the cell, which is the cell width minus its horizontal padding. Do the same for pills and buttons that cannot wrap. A natural width larger than the available width is a truncation finding.

Write these findings in the same form as step 4: a property, a design value, and a built value.

## 4. Diff, then locate

```bash
agent-browser diff screenshot --baseline captures/figma/<frame>.png \
  -s '<selector>' -o captures/diff/<frame>.png -t 0.1
```

Keep the threshold at 0.1 or above. Figma and Chromium antialias text differently, so a threshold of 0 marks every glyph.

Without agent-browser, ImageMagick gives the same diff. `-fuzz 10%` is the equivalent of `-t 0.1`, and the command prints the number of differing pixels. Exit code 1 means the images differ, not that the command failed.

```bash
magick compare -metric AE -fuzz 10% captures/figma/<frame>.png captures/build/<frame>.png captures/diff/<frame>.png
magick captures/figma/<frame>.png captures/build/<frame>.png captures/diff/<frame>.png +append captures/diff/<frame>-triptych.png
```

Read the triptych instead of the three files one at a time, so the same region lines up across all three.

The diff is a locator, not a verdict. Never adjust a value to make the pixels go away. Each hot region becomes a finding through these steps:

1. Look at the three images together: Figma, build, and diff. Name the element under the region.
2. Find that layer's node id in `get_metadata`, then read its exact values with `get_design_context` on that node. For text, the response carries both the text style token (for example `Global-S`, letterSpacing 0.2px) and the layer's raw values (tracking 0.032px). Note both when they differ, because step 5 classifies the difference.
3. Read the built element's values with `agent-browser eval`. Use `getComputedStyle` for color, font, radius, and padding. Use `getBoundingClientRect` on neighbors for gaps and offsets.
4. Write the finding as a property, a design value, and a built value, such as "Card gap: design 16px, built 12px". A note like "the bottom looks off" is not a finding, so go back to step 2.

For icons, read the size from `get_design_context` on the icon or button node. To check it in pixels, crop both images to the same box around the icon with `magick <in>.png -crop WxH+X+Y +repage <crop>.png`. Then read the glyph's bounding box with `magick <crop>.png -threshold 60% -negate -trim info:-`. The `WxH` it prints is the glyph size at the capture scale, so divide it by the scale.

Walk the regions from largest to smallest. A wrong container width or gap moves everything after it, so fixing it often clears smaller regions downstream.

**One offset hides everything after it.** When the container is wider or narrower than the frame's slot, every pixel after it is hot. In a test run, a design-system layout gave 1040px where Figma had 918px. Classify that container finding first (step 5). Then diff the inner pieces separately: export each child node with `download_assets` on its own node id, screenshot the matching built element, and diff each pair. Never override a design-system width locally to make the whole frame line up. A design-system width that the design does not match is Ask.

## 5. Classify every finding

```text
Is the difference in your code?
├── Deviation on purpose: the PR body, ticket or user already accepted it, such as a disabled button
│   for a missing step or changed copy → Report as Deliberate. Never fix it.
├── No: dynamic data, user images, or live text the frame shows as a placeholder → Ignore. List under Content.
├── No: Figma and browser rendering only, such as text antialiasing, subpixel offsets of 1px or less,
│   or shadow rasterization when blur, offset, and color match → Ignore. List under Rendering.
└── Yes
    ├── The value maps to a token and you used a different token or a raw value → Fix
    ├── There is no exact token, and you used the nearest one within 2px or on the same color step → Report as Rounded
    ├── The text style token and the layer's raw values differ, and the build follows the token → Report as Rounded.
    │   Its text renders wider, so size columns from the built natural widths (step 3), not from Figma's.
    ├── The nearest token is more than 2px away or on a different color step → Ask. Do not add a token.
    ├── A design-system component or layout sets a value the design does not match → Ask. Never override it locally.
    ├── The design breaks an accessibility, contrast, or focus rule → Keep the design. Report as Conflict
    └── Anything else you built differently → Fix
```

Fix only the files that render this frame. A diff that reaches other screens is out of scope.

## 6. Loop with a bound

After the fixes, capture the build again and diff again. Do not capture Figma again unless the frame changed.

Stop when every remaining region is classified as Deliberate, Content, Rendering, Rounded, Ask, or Conflict, or after 3 rounds. Without the bound, the loop keeps chasing font rendering it can never remove. If round 3 still has fixable findings, report them as open. Do not start round 4.

## 7. Report

Use the same table as `build-design`:

| Element | Design | Built | Status |
| --- | --- | --- | --- |
| Card gap | 16px | `gap-4`, 16px | Fixed (was `gap-3`) |
| Title size | 15px | `text-sm`, 14px | Rounded to token |
| Avatar | Photo | User image | Content |

Then add one line per frame with the browser, the width, the scale, the number of rounds, and the path to the last diff image. The same line lists what is left in the diff and why, such as "header text antialiasing (Rendering), avatars (Content)". It also says whether the loop ended because nothing fixable was left or because it stopped at round 3, so a reader can tell the two apart. List any Ask or Conflict items as questions for the user, and list Deliberate items with who accepted them.

To put the comparison on the PR, pass the pair to `before-and-after`: `--before captures/figma/<frame>.png --after captures/build/<frame>.png --label "Figma vs build"`. Before is the design. Only do this when the user asks for it.

## Before you finish

| You notice | Fix |
| --- | --- |
| A diff run on images with different dimensions | Fix the size first (step 2) |
| A diff run before counting columns, cells and slots against `get_metadata` | Do step 3 first |
| A harness font size or letter-spacing that differs from the app | Fix the harness, then capture again |
| An overflow check on the cell as the only truncation check | Measure the natural width with a hidden clone (step 3) |
| A design-system width overridden locally to line up the frame | Revert it, mark it Ask, and diff the inner pieces separately |
| A Deliberate item changed to match the design | Revert it |
| An image resized or cropped to make dimensions match | Delete it and capture at the right viewport and scale |
| A finding with no design value from `get_design_context` | Read the node |
| A value changed because the diff went quiet, with no measured mismatch | Revert it |
| A raw value or a new token added to match a pixel | Use the nearest token and report it as Rounded, or ask |
| A 4th round started | Stop and report the open findings |
| A match reported without a build screenshot | Capture it, or say the frame was not compared |
