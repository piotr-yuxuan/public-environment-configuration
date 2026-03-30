# zsh-init-content.sh is loaded by home-manager via programs.zsh.initContent.
# Runs in interactive shells after compinit.

# Shell options
setopt AUTO_CD              # Type a directory name to cd into it.
setopt CORRECT              # Offer spelling correction for commands.
setopt EXTENDED_GLOB        # Enable #, ~, ^ as glob operators.
setopt GLOB_DOTS            # Include dotfiles in glob matches.
setopt INTERACTIVE_COMMENTS # Allow # comments in interactive shell.
setopt NO_BEEP              # Silence terminal bell.
setopt PIPE_FAIL            # Pipeline exit code is the rightmost non-zero.
setopt HIST_FIND_NO_DUPS    # Skip duplicates during Ctrl-R search.
setopt HIST_REDUCE_BLANKS   # Strip superfluous blanks before recording.

# Emacs key bindings
bindkey -e

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"


# VSCode integrated terminal shell integration
[[ "$TERM_PROGRAM" == 'vscode' ]] && \
  command -v code &>/dev/null && . "$(code --locate-shell-integration-path zsh)"

# eat shell integration
[[ -n "$EAT_SHELL_INTEGRATION_DIR" ]] &&
    source "$EAT_SHELL_INTEGRATION_DIR/zsh"

# Align erase character to DEL so eat's delete key works.
[[ -n "$EAT_SHELL_INTEGRATION_DIR" ]] && stty erase '^?'

# OSC 133 prompt annotations (mistty)
autoload -Uz add-zsh-hook
_emt_precmd()  { printf '\e]133;A\e\\'; }
_emt_preexec() { printf '\e]133;C\e\\'; }
_emt_chpwd()   { printf '\e]7;file://%s%s\e\\' "${HOST:-$(hostname -s)}" "$PWD"; }
add-zsh-hook precmd  _emt_precmd
add-zsh-hook preexec _emt_preexec
add-zsh-hook chpwd   _emt_chpwd
_emt_chpwd  # fire once at startup for initial directory tracking

# VISUAL: reuse Emacs frame inside eat/mistty
if [[ -n "$MISTTY" || -n "$EAT_SHELL_INTEGRATION_DIR" ]]; then
    export VISUAL='emacsclient --reuse-frame'
else
    export VISUAL='emacsclient --create-frame'
fi

# Enter = newline; C-j = run command (inside Emacs terminals)
_emt_insert_newline() { BUFFER="$BUFFER"$'\n'; CURSOR=$#BUFFER; }
zle -N _emt_insert_newline
if [[ -n "$MISTTY" || -n "$EAT_SHELL_INTEGRATION_DIR" ]]; then
    bindkey '^M' _emt_insert_newline   # Enter → insert newline
    bindkey '^J' accept-line           # C-j   → run command
fi

# Login greeting (once per boot)
if [[ -t 1 && ! -f "$HOME/.hushlogin" ]]; then
    touch "$HOME/.hushlogin"
    macchina 2>/dev/null
    echo "$(fortune)\n"
fi
