#!/usr/bin/env zsh
# getting-started-new-codebase.zsh: comprehensive codebase analysis.
#
# Runs every available diagnostic on a git repository and collects the
# output in a single timestamped directory.  Each tool is optional: the
# script checks for its presence and skips gracefully when missing.
#
# Tools integrated (tier 1, native):
#   git log diagnostics (churn, bus factor, bug clusters, momentum, firefighting)
#   onefetch, scc, git-sizer, tokei
#
# Tools integrated (tier 2, Podman containers):
#   Hercules (srcd/hercules), code-maat (code-maat/code-maat)
#
# Usage:
#   getting-started-new-codebase.zsh [/path/to/repo]
#
# Defaults to the current directory when the argument is omitted.

setopt ERR_EXIT PIPE_FAIL NO_UNSET

# ── Helpers ──────────────────────────────────────────────────────────

# Portable ISO-8601 timestamp that works on both GNU date (Linux) and
# BSD date (macOS).  GNU coreutils from Nix shadow /usr/bin/date on
# NixOS but not necessarily on macOS, so try both forms.
portable_timestamp() {
  date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z
}

has() { command -v "$1" >/dev/null 2>&1 }

# Print a section banner.
banner() {
  printf '\n\e[1;34m── %s ──\e[0m\n' "$1"
}

# Run a command, redirect stdout to a file, tolerate failure.
run_to_file() {
  local label=$1 outfile=$2
  shift 2
  printf '  %s -> %s\n' "$label" "${outfile:t}"
  if ! "$@" > "$outfile" 2>/dev/null; then
    printf '    \e[33mwarning:\e[0m %s produced no output or failed\n' "$label"
    rm -f "$outfile"
  elif [[ ! -s "$outfile" ]]; then
    rm -f "$outfile"
  fi
}

# ── Argument handling ────────────────────────────────────────────────

REPO="${1:-.}"
REPO="${REPO:A}"  # zsh :A modifier: resolve to absolute path, following symlinks

if [[ ! -d "$REPO/.git" ]]; then
  print -u2 "Error: $REPO does not appear to be a git repository."
  exit 1
fi

TIMESTAMP="$(portable_timestamp)"
OUTDIR="codebase-analysis-${TIMESTAMP}"
mkdir -p "$OUTDIR"

# Track per-section pass/skip/fail counts for the final summary.
typeset -i sections_run=0 sections_skipped=0 sections_failed=0

print "Repository:       $REPO"
print "Output directory: $OUTDIR"

# ── Part 1: git diagnostic commands ─────────────────────────────────

banner "Git diagnostics"

# 1. Churn hotspots (most-changed files in the last year)
run_to_file "churn hotspots" "$OUTDIR/churn-hotspots.txt" \
  git -C "$REPO" log --format=format: --name-only --since="1 year ago"
# Post-process: sort | uniq -c | sort -nr | head -40
if [[ -f "$OUTDIR/churn-hotspots.txt" ]]; then
  sort "$OUTDIR/churn-hotspots.txt" | grep -v '^$' | uniq -c | sort -nr | head -40 \
    > "$OUTDIR/churn-hotspots-ranked.txt" && rm "$OUTDIR/churn-hotspots.txt"
fi

# 2. Bus factor (contributors ranked by commit count)
run_to_file "bus factor (all time)" "$OUTDIR/contributors-all-time.txt" \
  git -C "$REPO" shortlog -sn --no-merges

run_to_file "bus factor (6 months)" "$OUTDIR/contributors-6months.txt" \
  git -C "$REPO" shortlog -sn --no-merges --since="6 months ago"

# 3. Bug clusters
run_to_file "bug clusters (raw)" "$OUTDIR/bug-clusters.txt" \
  git -C "$REPO" log -i -E --grep="fix|bug|broken" --name-only --format=''
if [[ -f "$OUTDIR/bug-clusters.txt" ]]; then
  sort "$OUTDIR/bug-clusters.txt" | grep -v '^$' | uniq -c | sort -nr | head -40 \
    > "$OUTDIR/bug-clusters-ranked.txt" && rm "$OUTDIR/bug-clusters.txt"
fi

# 4. Project momentum (commits per month)
run_to_file "commits per month" "$OUTDIR/commits-per-month.txt" \
  git -C "$REPO" log --format='%ad' --date=format:'%Y-%m'
if [[ -f "$OUTDIR/commits-per-month.txt" ]]; then
  sort "$OUTDIR/commits-per-month.txt" | uniq -c \
    > "$OUTDIR/commits-per-month-counted.txt" && rm "$OUTDIR/commits-per-month.txt"
fi

# 5. Firefighting frequency (reverts, hotfixes)
run_to_file "firefighting" "$OUTDIR/firefighting.txt" \
  git -C "$REPO" log --oneline --since="1 year ago"
if [[ -f "$OUTDIR/firefighting.txt" ]]; then
  grep -iE 'revert|hotfix|emergency|rollback' "$OUTDIR/firefighting.txt" \
    > "$OUTDIR/firefighting-filtered.txt" 2>/dev/null && rm "$OUTDIR/firefighting.txt"
  # If grep found nothing the file does not exist; that is fine.
  [[ -f "$OUTDIR/firefighting.txt" ]] && rm "$OUTDIR/firefighting.txt"
fi

(( sections_run++ ))

# ── Part 2: native analysis tools (tier 1) ──────────────────────────

# onefetch
if has onefetch; then
  banner "onefetch"
  run_to_file "onefetch (text)" "$OUTDIR/onefetch.txt" \
    onefetch "$REPO" --no-art
  run_to_file "onefetch (json)" "$OUTDIR/onefetch.json" \
    onefetch "$REPO" -o json
  (( sections_run++ ))
else
  print "\n  skipping onefetch (not installed)"
  (( sections_skipped++ ))
fi

# scc
if has scc; then
  banner "scc"
  run_to_file "scc (text)" "$OUTDIR/scc.txt" \
    scc "$REPO"
  run_to_file "scc (json)" "$OUTDIR/scc.json" \
    scc "$REPO" --format json
  (( sections_run++ ))
else
  print "\n  skipping scc (not installed)"
  (( sections_skipped++ ))
fi

# git-sizer
if has git-sizer; then
  banner "git-sizer"
  run_to_file "git-sizer (verbose)" "$OUTDIR/git-sizer.txt" \
    git-sizer --path "$REPO" --verbose
  run_to_file "git-sizer (json)" "$OUTDIR/git-sizer.json" \
    git-sizer --path "$REPO" --json
  (( sections_run++ ))
else
  print "\n  skipping git-sizer (not installed)"
  (( sections_skipped++ ))
fi

# tokei
if has tokei; then
  banner "tokei"
  run_to_file "tokei" "$OUTDIR/tokei.txt" \
    tokei "$REPO"
  (( sections_run++ ))
else
  print "\n  skipping tokei (not installed)"
  (( sections_skipped++ ))
fi

# ── Part 3: Podman container analyses (tier 2) ──────────────────────

if has podman; then
  # Hercules
  banner "Hercules (Podman)"
  HERCULES_IMAGE="srcd/hercules"
  PB_FILE="$OUTDIR/analysis.pb"

  print "  Running Hercules analysis (may take a while for large repos)..."
  if podman run --rm \
       -v "$REPO":/repo:ro \
       "$HERCULES_IMAGE" hercules --pb /repo > "$PB_FILE" 2>/dev/null && [[ -s "$PB_FILE" ]]; then

    local -a labours_flags=(
      burndown-project
      burndown-file
      burndown-person
      overwrites-matrix
      ownership
      couples
      devs
      old-vs-new
      devs-efforts
      sentiment
    )

    for flag in "${labours_flags[@]}"; do
      printf '  Rendering: %s\n' "$flag"
      if ! podman run --rm -i \
             "$HERCULES_IMAGE" labours -m "$flag" -o "/dev/stdout" \
             < "$PB_FILE" > "$OUTDIR/hercules-${flag}.png" 2>/dev/null; then
        printf '    \e[33mwarning:\e[0m %s failed (may need more data)\n' "$flag"
        rm -f "$OUTDIR/hercules-${flag}.png"
      elif [[ ! -s "$OUTDIR/hercules-${flag}.png" ]]; then
        rm -f "$OUTDIR/hercules-${flag}.png"
      fi
    done

    (( sections_run++ ))
  else
    printf '  \e[33mwarning:\e[0m Hercules analysis failed (image may need pulling: podman pull %s)\n' "$HERCULES_IMAGE"
    rm -f "$PB_FILE"
    (( sections_failed++ ))
  fi

  # code-maat
  banner "code-maat (Podman)"
  CODEMAAT_IMAGE="code-maat/code-maat"
  GITLOG_FILE="$OUTDIR/gitlog-codemaat.txt"

  print "  Exporting git log for code-maat..."
  if git -C "$REPO" log --all --numstat --date=short \
       --pretty=format:'--%h--%ad--%aN' --no-renames \
       > "$GITLOG_FILE" 2>/dev/null && [[ -s "$GITLOG_FILE" ]]; then

    local -a codemaat_analyses=(coupling abs-churn entity-ownership)
    local codemaat_ok=false

    for analysis in "${codemaat_analyses[@]}"; do
      printf '  Running code-maat: %s\n' "$analysis"
      if podman run --rm \
           -v "$OUTDIR":/data:ro \
           "$CODEMAAT_IMAGE" -l /data/gitlog-codemaat.txt -c git2 -a "$analysis" \
           > "$OUTDIR/codemaat-${analysis}.csv" 2>/dev/null && [[ -s "$OUTDIR/codemaat-${analysis}.csv" ]]; then
        codemaat_ok=true
      else
        printf '    \e[33mwarning:\e[0m %s failed\n' "$analysis"
        rm -f "$OUTDIR/codemaat-${analysis}.csv"
      fi
    done

    if $codemaat_ok; then
      (( sections_run++ ))
    else
      printf '  \e[33mwarning:\e[0m all code-maat analyses failed (image may need pulling: podman pull %s)\n' "$CODEMAAT_IMAGE"
      (( sections_failed++ ))
    fi
  else
    print "  warning: git log export failed; skipping code-maat"
    rm -f "$GITLOG_FILE"
    (( sections_failed++ ))
  fi
else
  print "\n  skipping Podman container analyses (podman not installed)"
  (( sections_skipped++ ))
fi

# ── Summary ──────────────────────────────────────────────────────────

banner "Summary"
print "Sections run: $sections_run  skipped: $sections_skipped  failed: $sections_failed"
print ""

# List only files that were actually produced.
local -a produced=("$OUTDIR"/*(N))
if (( ${#produced} == 0 )); then
  print "No output files were generated."
else
  print "Generated files in $OUTDIR:"
  for f in "${produced[@]}"; do
    printf '  %s  (%s)\n' "${f:t}" "$(du -h "$f" 2>/dev/null | cut -f1)"
  done
fi
