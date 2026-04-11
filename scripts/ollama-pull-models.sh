#!/usr/bin/env bash

# Sourced as a home-manager activation script on macOS. Ensures that
# the models declared in config/ollama-models.nix are available
# locally. OLLAMA_BIN and OLLAMA_MODELS_NIX are set by Nix
# interpolation in macOS.nix before this script runs.
#
# On NixOS the equivalent is handled by services.ollama.loadModels;
# this script covers macOS where there is no system service module.

if [[ ! -x "$OLLAMA_BIN" ]]; then
	echo "ollamaPullModels: skipping because ollama binary not found at $OLLAMA_BIN" >&2
	return 0 2>/dev/null || exit 0
fi

# Read the model list from the Nix config at runtime.
models=$(nix eval -f "$OLLAMA_MODELS_NIX" --apply 'ms: builtins.map (m: m.model) ms' --json |
	jq -r '.[]')

if [[ -z "$models" ]]; then
	echo "ollamaPullModels: could not read model list from $OLLAMA_MODELS_NIX" >&2
	return 0 2>/dev/null || exit 0
fi

# Start the server in the background if it is not already running.
already_running=false
if "$OLLAMA_BIN" list >/dev/null 2>&1; then
	already_running=true
else
	"$OLLAMA_BIN" serve >/dev/null 2>&1 &
	ollama_pid=$!
	# Wait for the API to become reachable.
	for _ in $(seq 1 30); do
		"$OLLAMA_BIN" list >/dev/null 2>&1 && break
		sleep 1
	done
fi

for model in $models; do
	if "$OLLAMA_BIN" list 2>/dev/null | grep -q "^${model}"; then
		echo "ollamaPullModels: ${model} already present"
	else
		echo "ollamaPullModels: pulling ${model}…"
		$DRY_RUN_CMD "$OLLAMA_BIN" pull "$model"
	fi
done

# Stop the server only if we started it ourselves.
if [[ "$already_running" != "true" ]] && [[ -n "${ollama_pid:-}" ]]; then
	kill "$ollama_pid" 2>/dev/null
	wait "$ollama_pid" 2>/dev/null
fi
