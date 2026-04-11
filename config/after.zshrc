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

# Completion styling (minimal: case-insensitive matching + cache)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
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

# edit-command-line: C-x C-e opens the current command in $VISUAL/$EDITOR.
# Standard zsh feature; works in every terminal emulator.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Disable autosuggestions inside eat: ghost text clashes with eat's rendering.
# Keep them in mistty (shell renders natively), Gnome Console, and Ghostty.
[[ -n "$EAT_SHELL_INTEGRATION_DIR" ]] && ZSH_AUTOSUGGEST_STRATEGY=()

# Login greeting (once per boot)
if [[ -t 1 && ! -f "$HOME/.hushlogin" ]]; then
    touch "$HOME/.hushlogin"
    macchina 2>/dev/null
    echo "$(fortune)\n"
fi
