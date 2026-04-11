# Ollama models to pre-pull on all machines.
#
# This list is the single source of truth consumed by:
#   - services.ollama.loadModels   (NixOS, hosts/C40C04.nix)
#   - programs.opencode            (cross-platform, home/base.nix)
#   - ollama-pull-models.sh        (macOS, docs/macos-nix-darwin.org)
#
# The script reads this file at runtime with `nix eval -f`.
[
  {
    model = "gemma4:26b";
    name = "Gemma 4 26B";
  }
  {
    model = "qwen3-coder-next:q4_K_M";
    name = "Qwen 3 Coder Next Q4_K_M";
  }
  {
    model = "qwen3.5:0.8b";
    name = "Qwen 3.5 0.8B";
  }
]
