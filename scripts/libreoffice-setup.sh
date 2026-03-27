#!/usr/bin/env bash

# One-off LibreOffice post-install configuration.
#
# Installs the Grammalecte French grammar extension via unopkg,
# then prints a reminder to configure the local LanguageTool server.

set -euo pipefail

GRAMMALECTE_OXT_URL="https://www.grammalecte.net/oxt/Grammalecte-fr-v2.3.0.oxt"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/libreoffice-setup"
OXT_FILE="$CACHE_DIR/Grammalecte-fr-v2.3.0.oxt"

if ! command -v unopkg >/dev/null 2>&1; then
  echo "ERROR: unopkg not found. Is LibreOffice installed?" >&2
  exit 1
fi

# Install Grammalecte extension if not already present.
if unopkg list 2>/dev/null | grep -qi grammalecte; then
  echo "Grammalecte extension is already installed."
else
  mkdir -p "$CACHE_DIR"
  if [[ ! -f "$OXT_FILE" ]]; then
    echo "Downloading Grammalecte v2.3.0 extension..."
    curl -fSL -o "$OXT_FILE" "$GRAMMALECTE_OXT_URL"
  fi
  echo "Installing Grammalecte extension..."
  unopkg add "$OXT_FILE"
  echo "Grammalecte installed. Restart LibreOffice to activate."
fi

cat <<'EOF'

Post-install checklist
  1. Grammalecte: open LibreOffice, go to
     Tools > Extension Manager and verify Grammalecte is listed.
     In Grammalecte options, confirm the dictionary is set to
     "Classique" (the default, not "Réforme 1990").

  2. LanguageTool server (port 47193): go to
     Tools > Options > Language Settings > LanguageTool Server.
     Set base URL to:  http://localhost:47193/v2
     Leave username and API key empty.

  3. Dictionaries: hunspell dictionaries (en_GB, en_US, fr-classique,
     pl_PL, es_ES, de_DE) are exposed via DICPATH and should appear
     under Tools > Options > Language Settings > Writing Aids.
EOF
