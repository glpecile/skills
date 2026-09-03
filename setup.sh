#!/usr/bin/env bash
# Link skills/* into ~/.claude/skills and install upstream skills from manifest. Idempotent.
set -euo pipefail
cd "$(dirname "$0")"
dest="$HOME/.claude/skills"
mkdir -p "$dest"

# Drop symlinks into this repo that no longer resolve (e.g. after a skill is renamed/moved).
for link in "$dest"/*; do
  [[ -L $link && ! -e $link && $(readlink "$link") == "$PWD"/* ]] && { rm "$link"; echo "pruned  $(basename "$link")"; }
done

for dir in skills/*/; do
  name=$(basename "$dir")
  if [[ -e $dest/$name && ! -L $dest/$name ]]; then
    echo "skip    $name (real directory exists in $dest, move it aside first)"; continue
  fi
  ln -sfn "$PWD/$dir" "$dest/$name" && echo "linked  $name"
done

command -v bunx >/dev/null || { echo "bunx not found, skipping manifest"; exit 0; }
grep -vE '^\s*(#|$)' manifest | while read -r repo skill; do
  bunx skills add "$repo" --skill "$skill" -g -y -a claude-code </dev/null
done
