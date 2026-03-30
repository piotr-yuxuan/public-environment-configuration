#!/usr/bin/env bats
# Tests for scripts/home-layout.sh (cross-platform HOME layout).
#
# The script is designed to be sourced inside a Home Manager activation
# function.  Each test runs it under an isolated $HOME in a temp directory
# and inspects the resulting filesystem.
#
# Isolation guarantees:
#   - setup() asserts tmpdir is non-empty before any test body runs.
#   - teardown() uses ${tmpdir:?} so zsh aborts the rm -rf instead of
#     expanding to rm -rf "" if the variable were somehow empty or unset.
#   - All paths are passed to zsh subprocesses via exported environment
#     variables, never interpolated into the -c string, so a path that
#     contains single quotes or other metacharacters cannot inject code.

SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/scripts/home-layout.sh"

setup() {
    tmpdir=$(mktemp -d)
    # Abort the test immediately if mktemp failed rather than continuing
    # with an empty variable that teardown would pass to rm -rf.
    [[ -n $tmpdir ]]
}

teardown() {
    # :? causes zsh to error and halt before rm receives an empty argument,
    # preventing rm -rf "" from touching the working directory.
    rm -rf "${tmpdir:?}"
}

# Run the script live (DRY_RUN_CMD empty: commands are executed).
# Paths are injected via env vars so the single-quoted -c body is never
# subject to word splitting or metacharacter expansion from our variables.
live() {
    TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        DRY_RUN_CMD=
        source $TEST_SCRIPT
    '
}

# ---------------------------------------------------------------------------
# Plain working directories
# ---------------------------------------------------------------------------

@test "creates bin directory" {
    live
    [[ -d $tmpdir/bin ]]
}

@test "creates man directory" {
    live
    [[ -d $tmpdir/man ]]
}

@test "creates pkg directory" {
    live
    [[ -d $tmpdir/pkg ]]
}

@test "creates src directory" {
    live
    [[ -d $tmpdir/src ]]
}

@test "seeds src/github.com when src is a plain directory" {
    live
    [[ -d $tmpdir/src/github.com ]]
}

@test "does not seed src/github.com when src is already a symlink" {
    mkdir -p "$tmpdir/elsewhere"
    ln -s "$tmpdir/elsewhere" "$tmpdir/src"
    live
    [[ ! -d $tmpdir/elsewhere/github.com ]]
}

@test "creates Pictures directory" {
    live
    [[ -d $tmpdir/Pictures ]]
}

@test "creates Pictures/screenshots directory" {
    live
    [[ -d $tmpdir/Pictures/screenshots ]]
}

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------

@test "img is a symlink pointing to Pictures" {
    live
    [[ -L $tmpdir/img ]]
    [[ $(readlink "$tmpdir/img") == "$tmpdir/Pictures" ]]
}

@test "net is a symlink pointing to Downloads" {
    live
    [[ -L $tmpdir/net ]]
    [[ $(readlink "$tmpdir/net") == "$tmpdir/Downloads" ]]
}

@test "pvt is a symlink pointing to Documents" {
    live
    [[ -L $tmpdir/pvt ]]
    [[ $(readlink "$tmpdir/pvt") == "$tmpdir/Documents" ]]
}

@test "snd is a symlink pointing to Music" {
    live
    [[ -L $tmpdir/snd ]]
    [[ $(readlink "$tmpdir/snd") == "$tmpdir/Music" ]]
}

@test "dist is a symlink pointing to .m2/repository" {
    live
    [[ -L $tmpdir/dist ]]
    [[ $(readlink "$tmpdir/dist") == "$tmpdir/.m2/repository" ]]
}

# ---------------------------------------------------------------------------
# Idempotency and no-overwrite guards
# ---------------------------------------------------------------------------

@test "is idempotent: second run succeeds without error" {
    live
    live
}

@test "does not overwrite an existing img symlink" {
    ln -s "$tmpdir/custom" "$tmpdir/img"
    live
    [[ $(readlink "$tmpdir/img") == "$tmpdir/custom" ]]
}

@test "does not overwrite a real img directory" {
    mkdir -p "$tmpdir/img"
    live
    [[ -d $tmpdir/img && ! -L $tmpdir/img ]]
}

@test "does not overwrite an existing net symlink" {
    ln -s "$tmpdir/custom" "$tmpdir/net"
    live
    [[ $(readlink "$tmpdir/net") == "$tmpdir/custom" ]]
}

@test "does not overwrite a broken dangling symlink for pvt" {
    ln -s "$tmpdir/nonexistent" "$tmpdir/pvt"
    live
    [[ $(readlink "$tmpdir/pvt") == "$tmpdir/nonexistent" ]]
}

# ---------------------------------------------------------------------------
# Dry-run mode (DRY_RUN_CMD=echo)
# ---------------------------------------------------------------------------

@test "dry run: no directories or symlinks created" {
    run env TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        DRY_RUN_CMD=echo
        source $TEST_SCRIPT
    '
    [[ $status -eq 0 ]]
    [[ ! -d $tmpdir/bin ]]
    [[ ! -d $tmpdir/src ]]
    [[ ! -L $tmpdir/img ]]
}

@test "dry run: mkdir commands are printed to stdout" {
    run env TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        DRY_RUN_CMD=echo
        source $TEST_SCRIPT
    '
    [[ $output == *"mkdir"* ]]
}

@test "dry run: ln -s commands are printed to stdout" {
    run env TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        DRY_RUN_CMD=echo
        source $TEST_SCRIPT
    '
    [[ $output == *"ln -s"* ]]
}
