---
name: scrub
description: Step through a screen recording frame by frame to find what looks wrong in it. Use when the user shares a screen recording or frames taken from one, or says "scrub" or "/scrub".
compatibility: Requires ffmpeg and ffprobe. Does not use the drawtext filter, so a build without freetype works.
---

# Scrub

A user records the screen because the bug lasts less than a glance: a flash, a jump, a layout that is wrong for 50 ms. A model that looks at three frames and a description will explain the bug away as normal. Look at every real frame around the moment. Each thing in those frames that looks wrong is a bug until the frames prove it is not.

## 1. Find the file

Use the path the user gives. Pasted macOS paths often carry `\ ` escapes, or a narrow no-break space before AM or PM. If the path does not open, list `~/Desktop/Screen Recording*` and pick the file whose date matches.

If the user sent images instead of a video, skip to step 4. Put the images in the order the user gave, and ask for the video if the moment between two images is the question.

Work in a new scratch directory. Never write frames next to the recording.

## 2. Probe

```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,avg_frame_rate,r_frame_rate:format=duration \
  -of default=nw=1 "$f"
```

macOS screen recordings have a variable frame rate. The recorder writes a frame only when the screen changes, up to 60 per second. Two results follow:

- Measure time with frame timestamps, never with frame counts.
- Never use the `fps` filter on the window you study. It invents duplicate frames and moves real ones. Use `-fps_mode passthrough`.

## 3. Find the moment

If the user names a time or a step ("when I go back"), go to step 4 with a window of 1 s on each side.

Otherwise, list the times where the picture changes:

```bash
ffmpeg -v info -i "$f" -vf "select='gt(scene,0.01)',showinfo" -an -f null - 2>&1 \
  | grep -o 'pts_time:[0-9.]*'
```

Then make overview sheets, 2 frames per second, 24 tiles per sheet:

```bash
ffmpeg -v error -i "$f" -vf "fps=2,scale=480:-2,tile=6x4" overview-%02d.png
```

Tile `i` (from 0, row by row) on sheet `k` (from 1) is at `((k-1)*24 + i) / 2` seconds. Black tiles after the last frame are filler.

The overview only locates a window. It skips anything shorter than 0.5 s, so a flash shows only in the change list. Read the sheets, then match what the user describes with a change time from the list. Run step 4 on a window of 0.5 s on each side of each change time in the part the user names.

The list misses slow, continuous motion. If it has fewer than 3 times in that part, run it again at `0.003`. If it has more than 50, use `0.03`.

## 4. Extract every real frame in the window

```bash
mkdir -p win && ffmpeg -v info -ss "$start" -to "$end" -copyts -i "$f" \
  -fps_mode passthrough -vf "showinfo,scale=480:-2" win/%04d.png 2>&1 \
  | sed -nE 's/.*n: *([0-9]+) .*pts_time:([0-9.]+).*/\1 \2/p' \
  | awk '{printf "%04d.png %s\n", $1+1, $2}' > win/times.txt
ffmpeg -v error -i win/%04d.png -vf tile=4x3 win/sheet-%02d.png
```

Each line of `win/times.txt` gives a frame file and its time in seconds. On each sheet the tiles go row by row, 12 per sheet: tile `i` (from 0) on sheet `k` (from 1) is frame `(k-1)*12 + i + 1`. For a small detail, crop the full-size frame instead of scaling it:

```bash
ffmpeg -v error -ss "$t" -copyts -i "$f" -frames:v 1 -vf "crop=$w:$h:$x:$y" detail.png
```

## 5. Read the frames

Read every sheet in the window, not a sample. First find the start state, before the action, and the end state, after the motion stops. Then check each frame between them:

- Does an element jump, snap or change size to reach its end state?
- Does an element draw over chrome that it ends up under (a sticky header, a tab bar, a sheet)?
- Is there a frame that is blank, unstyled, the wrong theme, or a skeleton that flashes back?
- Do items overlap, crowd together or lose their spacing for a few frames?
- Does text change, wrap or flicker when its value does not change?
- Does the motion go one way and then the other?

Each yes is a finding. An element that changes color or brightness for only a few frames is a finding even when its shape is right. Do not call one "the normal path" or "expected" because the code does it on purpose. If the user asked about one thing and you see another, report both.

Measure each finding with `times.txt`: the first and the last frame where it shows, and the time between them.

## 6. Report

For each finding, give:

- The time range and the frame files, for example `1.733–1.782 s (0014–0016)`.
- The element, and what it does in those frames compared with the end state.
- The likely cause, marked as a guess until you read the code.

Show the user the sheet or the crop that proves the worst finding.

Say which seconds you read frame by frame and which you saw only in the overview. Never say the rest of the recording is clean if you did not read its frames.

## 7. Check a fix

A fix is proven only by a new recording of the same flow, scrubbed over the same window, with clean frames. Record with the project's tools (`xcrun simctl io booted recordVideo`, Playwright `recordVideo`, an emulator screen record). If you cannot record, say that the fix is not checked on frames. Do not say it is fixed.
