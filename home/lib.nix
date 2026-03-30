# Shared helpers for Home Manager modules.
{
  # Skip packages that fail to evaluate (unsupported platform, broken, …)
  # instead of aborting the entire build.  Emits a trace line so the
  # skipped package is still visible in `--show-trace` / verbose output.
  filterAvailable = builtins.filter (
    p: let
      tried = builtins.tryEval (builtins.seq p.outPath p);
      nameEval = builtins.tryEval (p.pname or p.name or "unknown");
      name =
        if nameEval.success
        then nameEval.value
        else "unknown";
    in
      if tried.success
      then true
      else builtins.trace "filterAvailable: skipping unavailable package: ${name}" false
  );
}
