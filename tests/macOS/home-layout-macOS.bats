#!/usr/bin/env bats
# Tests for scripts/home-layout-macOS.sh (macOS HOME layout additions).
#
# 'chflags' is mocked via a fake executable prepended to PATH, so these
# tests run on any platform (Linux and macOS alike).
#
# Isolation guarantees:
#   - setup() asserts tmpdir is non-empty before any test body runs.
#   - teardown() uses ${tmpdir:?} so zsh aborts the rm -rf instead of
#     expanding to rm -rf "" if the variable were somehow empty or unset.
#   - All paths are passed to zsh subprocesses via exported environment
#     variables, never interpolated into the -c string, so a path that
#     contains single quotes or other metacharacters cannot inject code.

SCRIPT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)/scripts/home-layout-macOS.sh"

setup() {
    tmpdir=$(mktemp -d)
    [[ -n $tmpdir ]]

    # Fake chflags: records each invocation as "chflags <args>" in a log
    # file inside the test HOME so the real chflags binary is never called.
    mkdir -p "$tmpdir/bin"
    cat > "$tmpdir/bin/chflags" << 'EOF'
#!/bin/sh
echo "chflags $*" >> "$HOME/.chflags-calls"
EOF
    chmod +x "$tmpdir/bin/chflags"
}

teardown() {
    rm -rf "${tmpdir:?}"
}

# Run the script live with the fake chflags on PATH.
# Paths flow in via env vars to keep the -c body injection-safe.
live() {
    TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        export PATH=$HOME/bin:$PATH
        DRY_RUN_CMD=
        source $TEST_SCRIPT
    '
}

# Read the chflags call log (empty string when no calls were made).
chflags_log() { cat "$tmpdir/.chflags-calls" 2>/dev/null || true; }

# ---------------------------------------------------------------------------
# mov symlink
# ---------------------------------------------------------------------------

@test "creates mov symlink pointing to Movies" {
    mkdir -p "$tmpdir/Movies"
    live
    [[ -L $tmpdir/mov ]]
    [[ $(readlink "$tmpdir/mov") == "$tmpdir/Movies" ]]
}

@test "does not overwrite an existing mov symlink" {
    mkdir -p "$tmpdir/Movies"
    ln -s "$tmpdir/custom" "$tmpdir/mov"
    live
    [[ $(readlink "$tmpdir/mov") == "$tmpdir/custom" ]]
}

@test "does not overwrite a real mov directory" {
    mkdir -p "$tmpdir/Movies" "$tmpdir/mov"
    live
    [[ -d $tmpdir/mov && ! -L $tmpdir/mov ]]
}

# ---------------------------------------------------------------------------
# chflags hidden for default folders
# ---------------------------------------------------------------------------

@test "calls chflags hidden for each existing default folder" {
    for d in Desktop Documents Downloads Movies Music Pictures Public; do
        mkdir -p "$tmpdir/$d"
    done
    live
    for d in Desktop Documents Downloads Movies Music Pictures Public; do
        [[ $(chflags_log) == *"hidden $tmpdir/$d"* ]]
    done
}

@test "does not call chflags when no default folders exist" {
    live
    [[ -z $(chflags_log) ]]
}

@test "calls chflags only for folders that actually exist" {
    mkdir -p "$tmpdir/Desktop" "$tmpdir/Documents"
    live
    [[ $(chflags_log) == *"hidden $tmpdir/Desktop"* ]]
    [[ $(chflags_log) == *"hidden $tmpdir/Documents"* ]]
    [[ $(chflags_log) != *"hidden $tmpdir/Downloads"* ]]
    [[ $(chflags_log) != *"hidden $tmpdir/Music"* ]]
}

# ---------------------------------------------------------------------------
# Dry-run mode (DRY_RUN_CMD=echo)
# ---------------------------------------------------------------------------

@test "dry run: no mov symlink created" {
    mkdir -p "$tmpdir/Movies"
    run env TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        export PATH=$HOME/bin:$PATH
        DRY_RUN_CMD=echo
        source $TEST_SCRIPT
    '
    [[ $status -eq 0 ]]
    [[ ! -L $tmpdir/mov ]]
}

@test "dry run: ln -s command is printed to stdout" {
    mkdir -p "$tmpdir/Movies"
    run env TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        export PATH=$HOME/bin:$PATH
        DRY_RUN_CMD=echo
        source $TEST_SCRIPT
    '
    [[ $output == *"ln -s"*"Movies"*"mov"* ]]
}

@test "dry run: chflags commands are printed to stdout" {
    mkdir -p "$tmpdir/Desktop"
    run env TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        export PATH=$HOME/bin:$PATH
        DRY_RUN_CMD=echo
        source $TEST_SCRIPT
    '
    [[ $output == *"chflags hidden"*"Desktop"* ]]
}

@test "dry run: real chflags never invoked" {
    mkdir -p "$tmpdir/Desktop"
    run env TEST_HOME="$tmpdir" TEST_SCRIPT="$SCRIPT" zsh -c '
        export HOME=$TEST_HOME
        export PATH=$HOME/bin:$PATH
        DRY_RUN_CMD=echo
        source $TEST_SCRIPT
    '
    [[ -z $(chflags_log) ]]
}
    [[ -z $(chflags_log) ]]
}
