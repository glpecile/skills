#!/bin/sh
# Small renderer check: sh skills/codebase-map/scripts/test.sh
set -eu
render="$(dirname "$0")/render.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/map.json" <<'EOF'
{"title": "Map </script><script>alert(1)</script> __DATA__",
 "snapshot": "Example commit", "scope": "Example slice", "summary": ["Summary"],
 "nodes": [{"id": "a", "label": "Component", "group": "UI", "purpose": "Purpose", "pattern": "Pattern",
            "state": "State", "contracts": ["Keep behavior"], "sources": ["src/a.ts:1"]}],
 "views": [{"id": "overview", "label": "Overview", "nodes": ["a"], "edges": [],
            "columns": [{"label": "UI", "nodes": ["a"]}]}],
 "flows": [], "findings": [], "delegation": [], "unknowns": []}
EOF

fail() { echo "FAIL: $1" >&2; exit 1; }

sh "$render" "$tmp/map.json" "$tmp/out" >/dev/null
page="$tmp/out/index.html"
grep -qF '</script><script>alert(1)' "$page" && fail 'unescaped script in page'
grep -qF '<title>Map &lt;/script&gt;&lt;script&gt;alert(1)&lt;/script&gt; __DATA__</title>' "$page" || fail 'title not escaped'
grep -qF 'src="http' "$page" && fail 'page loads a remote script'
grep -qF 'Copy report handoff' "$page" || fail 'missing report handoff'
grep -qF 'Clipboard access is unavailable' "$page" || fail 'missing manual-copy fallback'
grep -qF 'Map </script><script>alert(1)</script> __DATA__' "$tmp/out/architecture.md" || fail 'markdown title'

jq '.views[0].columns[0].nodes += ["a"]' "$tmp/map.json" > "$tmp/dup.json"
sh "$render" "$tmp/dup.json" "$tmp/x" 2>/dev/null && fail 'accepted duplicate column node'

jq '.flows = [{"title": "f", "steps": [{"node": "a", "evidence": "src/a.ts:1"}],
               "sequence": {"participants": [{"id": "ui"}, {"id": "cache"}],
                            "messages": [{"from": "ui", "to": "unknown", "step": 0}]}}]' "$tmp/map.json" > "$tmp/seq.json"
sh "$render" "$tmp/seq.json" "$tmp/x" 2>/dev/null && fail 'accepted unknown sequence participant'

echo OK
