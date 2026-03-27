#!/bin/sh
# Nix flake staleness check for macOS machines.
# Called weekly by launchd agent com.user.nix-staleness-check.
# Warns via macOS notification if any flake input is older than 14 days.

export PATH="/run/current-system/sw/bin:$PATH"

flake_dir="$HOME/nixos"
if [ ! -d "$flake_dir" ]; then exit 0; fi

cutoff=$(date -v-14d +%s 2>/dev/null || date -d '14 days ago' +%s)
stale=""

while IFS='=' read -r name date_str; do
  [ -z "$date_str" ] && continue
  ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$date_str" +%s 2>/dev/null || echo 0)
  if [ "$ts" -lt "$cutoff" ] 2>/dev/null; then
    stale="$stale $name"
  fi
done <<EOF
$(nix flake metadata --json "$flake_dir" 2>/dev/null | jq -r '.locks.nodes | to_entries[] | select(.value.locked.lastModified) | "\(.key)=\(.value.locked.lastModified | todate | split("T") | .[0] + "T" + (.[1] | split("+") | .[0]))"')
EOF

if [ -n "$stale" ]; then
  /usr/bin/osascript -e "display notification \"Stale inputs:$stale\" with title \"Nix flake inputs are outdated\" subtitle \"Run: nix flake update\""
fi
