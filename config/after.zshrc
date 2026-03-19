# zsh-init-content.sh — loaded by home-manager via programs.zsh.initContent.
# Runs in interactive shells after compinit.

# ── fzf keybindings ────────────────────────────────────────────────
export FZF_DEFAULT_OPTS="--multi"
source <(fzf --zsh)

# ── VSCode integrated terminal shell integration ─────────────────
[[ "$TERM_PROGRAM" == 'vscode' ]] && \
  command -v code &>/dev/null && . "$(code --locate-shell-integration-path zsh)"

# ── eat shell integration ──────────────────────────────────────────
[[ -n "$EAT_SHELL_INTEGRATION_DIR" ]] &&
    source "$EAT_SHELL_INTEGRATION_DIR/zsh"

# Align erase character to DEL so eat's delete key works.
[[ -n "$EAT_SHELL_INTEGRATION_DIR" ]] && stty erase '^?'

# ── OSC 133 prompt annotations (mistty) ────────────────────────────
autoload -Uz add-zsh-hook
_emt_precmd()  { printf '\e]133;A\e\\'; }
_emt_preexec() { printf '\e]133;C\e\\'; }
_emt_chpwd()   { printf '\e]7;file://%s%s\e\\' "${HOST:-$(hostname -s)}" "$PWD"; }
add-zsh-hook precmd  _emt_precmd
add-zsh-hook preexec _emt_preexec
add-zsh-hook chpwd   _emt_chpwd
_emt_chpwd  # fire once at startup for initial directory tracking

# ── VISUAL: reuse Emacs frame inside eat/mistty ────────────────────
if [[ -n "$MISTTY" || -n "$EAT_SHELL_INTEGRATION_DIR" ]]; then
    export VISUAL='emacsclient --reuse-frame'
else
    export VISUAL='emacsclient --create-frame'
fi

# ── Enter = newline; C-j = run command (inside Emacs terminals) ────
_emt_insert_newline() { BUFFER="$BUFFER"$'\n'; CURSOR=$#BUFFER; }
zle -N _emt_insert_newline
if [[ -n "$MISTTY" || -n "$EAT_SHELL_INTEGRATION_DIR" ]]; then
    bindkey '^M' _emt_insert_newline   # Enter → insert newline
    bindkey '^J' accept-line           # C-j   → run command
fi

# ── Login greeting (once per boot) ─────────────────────────────────
if [[ -t 1 && ! -f "$HOME/.hushlogin" ]]; then
    touch "$HOME/.hushlogin"
    macchina 2>/dev/null
    echo "$(fortune)\n"
fi
