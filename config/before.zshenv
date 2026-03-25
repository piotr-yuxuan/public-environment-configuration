# zsh-env-extra.sh is loaded by home-manager via programs.zsh.envExtra.
# Appended to ~/.zshenv; sourced by every zsh instance (interactive and not).
# Use for dynamic exports that cannot be expressed as static sessionVariables.

# Editors
export EDITOR='emacsclient'
export ALTERNATE_EDITOR='emacs -nw'

# New files: owner rw, group r, world nothing (rw-r-----).
# On NixOS, pair this with security.loginDefs.settings.UMASK = "027" in
# configuration.nix so the setting applies at PAM login before any shell runs.
umask 027

# GPG_TTY must be evaluated at shell startup from the actual controlling terminal.
export GPG_TTY=$(tty)

# Secrets: never store tokens in the nix store or in source control.
# Create ~/.zshenv.secrets (gitignored) containing lines such as:
#   export GITLAB_PERSONAL_ACCESS_TOKEN='glpat-...'
[[ -f "$HOME/.zshenv.secrets" ]] && source "$HOME/.zshenv.secrets"
