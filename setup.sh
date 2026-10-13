#!/usr/bin/env bash
# Link skills/* (plus ~/dotfiles/skills/* when present) into every agent skills dir and install upstream skills from manifest. Idempotent.
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")"

# ~/.agents/skills is the cross-agent convention; the rest are linked only if the agent is installed.
dests=("$HOME/.agents/skills" "$HOME/.claude/skills")
for d in "$HOME/.cursor/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills"; do
  [[ -d $(dirname "$d") ]] && dests+=("$d")
done

# Third-party skills without an installable upstream live in the private dotfiles repo, not here.
srcs=("$PWD"/skills/*/)
[[ -d $HOME/dotfiles/skills ]] && srcs+=("$HOME"/dotfiles/skills/*/)

for dest in "${dests[@]}"; do
  mkdir -p "$dest"
  for link in "$dest"/*; do
    target=$(readlink "$link" || true)
    [[ -L $link && ! -e $link && ( $target == "$PWD"/* || $target == "$HOME/dotfiles"/* ) ]] && { rm "$link"; echo "pruned  $link"; }
  done
  for dir in "${srcs[@]}"; do
    name=$(basename "$dir")
    if [[ -e $dest/$name && ! -L $dest/$name ]]; then
      echo "skip    $dest/$name (real directory, move it aside first)"; continue
    fi
    ln -sfn "$dir" "$dest/$name"
  done
  echo "linked  ${#srcs[@]} skills -> $dest"
done

command -v bunx >/dev/null || { echo "bunx not found, skipping manifest"; exit 0; }
grep -vE '^\s*(#|$)' manifest | while read -r repo skill; do
  bunx skills add "$repo" --skill "$skill" -g -y --full-depth -a claude-code cursor codex opencode </dev/null
done
