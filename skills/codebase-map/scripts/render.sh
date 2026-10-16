#!/bin/sh
# Render one source-backed model as an offline HTML map and Markdown report.
# Usage: render.sh <map.json> <output-dir>. Needs jq 1.6+.
set -eu
# Feature probe instead of a version parse: --rawfile and IN() both arrived in jq 1.6.
if ! jq -n --rawfile t /dev/null 'IN(1; 1)' >/dev/null 2>&1; then
  echo 'render.sh: jq 1.6+ is required. Install it: brew install jq | sudo apt-get install jq | winget install jqlang.jq' >&2
  exit 127
fi
model=$1 out=$2
template="$(dirname "$0")/../assets/explorer.html"

errors=$(jq -r '
  [.nodes[].id] as $ids
  | (if ($ids | length) != ($ids | unique | length) then "Duplicate component IDs" else empty end),
    (if (.views | length) == 0 then "At least one map view is required" else empty end),
    (.views[] as $v
      | (if ($v.nodes | length) == 0 or ($v.nodes - $ids | length) > 0 then "Unknown view component in \($v.id)" else empty end),
        (if $v.columns then [$v.columns[].nodes[]] as $p
          | if ($p | length) != ($p | unique | length) or ($p | unique) != ($v.nodes | unique)
            then "Invalid view columns in \($v.id)" else empty end
         else empty end),
        ($v.edges[]
          | (if ([.from, .to] - $v.nodes | length) > 0 then "Unknown connection endpoint \(.from) -> \(.to)" else empty end),
            (if (.evidence // "") == "" then "Connection needs evidence: \(.from) -> \(.to)" else empty end))),
    (.flows[] as $f
      | (if ($f.steps | length) == 0 then "Flow needs a step: \($f.title)" else empty end),
        ($f.steps[] | if (.node | IN($ids[]) | not) or (.evidence // "") == "" then "Unknown node or missing evidence in flow: \($f.title)" else empty end),
        (if $f.sequence then [$f.sequence.participants[].id] as $a
          | (if ($a | length) < 2 or ($a | length) != ($a | unique | length) then "Invalid sequence participants in \($f.title)" else empty end),
            ($f.sequence.messages[]
              | (if ([.from, .to] - $a | length) > 0 then "Unknown sequence participant in \($f.title)" else empty end),
                (if .step < 0 or .step >= ($f.steps | length) then "Unknown sequence step in \($f.title)" else empty end))
         else empty end))
' "$model")
if [ -n "$errors" ]; then printf '%s\n' "$errors" >&2; exit 1; fi

mkdir -p "$out"

# Data first: the title placeholder sits above it, so a title or model that contains a placeholder cannot move the other.
jq -j --rawfile tpl "$template" '
  (tojson | gsub("<"; "\\u003c") | gsub(">"; "\\u003e") | gsub("&"; "\\u0026")) as $data
  | (.title | @html) as $title
  | $tpl | sub("__DATA__"; $data) | sub("__TITLE__"; $title)
' "$model" > "$out/index.html"

jq -r '
  [ "# \(.title)", "", .snapshot, "", "Scope: \(.scope)", "", "## Architecture summary",
    (.summary[] | "- \(.)"),
    (.nodes[] | "", "## \(.label) [\(.id)]", .purpose, "", "Pattern: \(.pattern)", "State: \(.state)",
      (.contracts[] | "- Contract: \(.)"), (.sources[] | "- Source: \(.)")),
    (.views[] | "", "## Connections: \(.label)", (.edges[] | "- \(.from) — \(.label) → \(.to) (\(.evidence))")),
    (.flows[] | "", "## Flow: \(.title)",
      (.steps | to_entries[] | "\(.key + 1). [\(.value.node)] \(.value.text) (\(.value.evidence))"),
      (if .sequence then (.sequence.participants | map({(.id): .label}) | add) as $a
        | "", "Messages:",
          (.sequence.messages[] | "- \($a[.from]) → \($a[.to]): \(.label) (step \(.step + 1); \(if .response then "response" else "request/update" end))")
       else empty end),
      "Failure and recovery: \(.failure)"),
    (.findings[] | "", "## \(.classification): \(.title)", .detail, "Keep separate: \(.preserve)", (.sources[] | "- Source: \(.)")),
    (.delegation[] | "", "## Delegation: \(.title)", "Scope: \(.scope)", "Contracts: \(.contracts)",
      (.checks[] | "- Check: \(.)"), (.sources[] | "- Source: \(.)")),
    "", "## Limits", (.unknowns[] | "- \(.)")
  ] | join("\n")
' "$model" > "$out/architecture.md"

echo "$out/index.html"
echo "$out/architecture.md"
