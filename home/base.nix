# Home Manager base module (cross-platform).
#
# Imported by both C40C04 (NixOS) and macOS (standalone macOS).
# Per-host overrides live in home/C40C04.nix and home/macOS.nix.
#
# RULE: Only settings that are picked up and applied on *both*
#       NixOS and macOS belong here.  Platform-specific config
#       goes in the corresponding host file.
#
# `unstable` is passed via extraSpecialArgs from the flake.
{
  pkgs,
  lib,
  config,
  unstable,
  starship-gruvbox-rainbow,
  practicalli-clojure-deps-edn,
  ...
}: let
  inherit (import ./lib.nix) filterAvailable;
  ollamaModels = import ../config/ollama-models.nix;
in {
  # Let Home Manager manage itself.
  programs.home-manager.enable = true;

  #  Packages: cross-platform CLI tools (both hosts)
  home.packages = filterAvailable [
    # Build toolchain
    unstable.cmake
    unstable.pkg-config
    unstable.enchant # libenchant for jinx / spell compile-time dep

    # Languages & runtimes
    unstable.python3
    unstable.nodejs
    unstable.go
    unstable.rustup # provides cargo, rustc, rustfmt, rust-analyzer

    # Clojure ecosystem
    unstable.babashka # fast Clojure scripting (no JVM startup)
    unstable.clj-kondo # Clojure linter / static analysis
    unstable.leiningen # Clojure project automation & build tool
    unstable.neil # manage deps.edn aliases & deps

    # Language servers (eglot)
    unstable.clojure-lsp
    unstable.texlab # LaTeX language server
    unstable.pyright
    unstable.typescript-language-server
    unstable.typescript
    unstable.ltex-ls
    unstable.jdt-language-server
    unstable.bash-language-server
    unstable.dockerfile-language-server
    unstable.yaml-language-server
    unstable.terraform-ls
    unstable.terraform-lsp

    # Formatters
    unstable.alejandra # Nix formatter
    unstable.black
    unstable.isort
    unstable.yamlfmt
    unstable.shfmt
    unstable.prettier

    # Linters
    unstable.shellcheck
    unstable.yamllint
    pkgs.python3Packages.cfn-lint # CloudFormation template linter

    # Testing
    unstable.bats # shell test framework (tests/ directory)

    # CLI utilities
    unstable.fortune
    unstable.macchina
    unstable.yq-go
    unstable.curl
    unstable.tokei
    unstable.onefetch
    unstable.scc
    unstable.gource # animated 3D visualisation of repository history
    unstable.bmon
    unstable.coreutils
    unstable.duckdb
    unstable.enca
    unstable.fx
    unstable.qrencode
    unstable.silver-searcher
    unstable.tree
    unstable.poppler-utils # pdftotext, pdfinfo, etc. (xpdf is CVE-marked)
    unstable.ffmpeg # media processing (also used by yt-dlp)
    unstable.ispell
    unstable.age # modern file encryption
    unstable.graphviz
    unstable.inxi
    unstable.lsof

    # IaC / Cloud
    unstable.aws-vault # secure AWS credential management
    unstable.ssm-session-manager-plugin
    unstable.git-sizer # repository size metrics and health check
    unstable.podman
    unstable.sops
    unstable.tenv
    unstable.terraform-landscape

    # CloudFormation
    pkgs.rain # CloudFormation deploy / diff CLI

    # Load testing / monitoring
    pkgs.k6 # modern load testing (scripted in JS)
    pkgs.vegeta # HTTP load testing CLI
    pkgs.hey # simple HTTP load generator

    # LaTeX
    pkgs.texliveFull # full TeX Live (XeLaTeX, LuaLaTeX, latexmk, …)
    pkgs.tectonic # modern self-contained TeX engine

    # Profiling / flamegraphs
    pkgs.visualvm # JVM monitoring & profiling GUI
    pkgs.async-profiler # low-overhead JVM sampling profiler
    pkgs.flamegraph # Brendan Gregg's FlameGraph scripts

    # System management
    unstable.nh # Nix CLI helper: human-friendly rebuild, diff, GC, and search

    # AI / ML
    unstable.ollama
    unstable.open-webui
    unstable.openai-whisper

    # Build tools
    unstable.meson
    unstable.ninja

    # Email (mu, mu4e, and isync/mbsync managed via programs.mu and
    # programs.mbsync; email account config lives in home/C40C04.nix)

    # Spell & grammar
    unstable.languagetool # grammar checker (EN, FR, PL, …)
    unstable.python3Packages.grammalecte # French grammar checker
    unstable.hunspell
    unstable.hunspellDicts.en_GB-ise
    unstable.hunspellDicts.en_US
    unstable.hunspellDicts.fr-classique
    unstable.hunspellDicts.pl_PL
    unstable.hunspellDicts.es_ES
    unstable.hunspellDicts.de_DE
    (unstable.callPackage ../packages/hunspell-dict-la.nix {})
    unstable.aspell
    unstable.aspellDicts.en
    unstable.aspellDicts.fr
    unstable.aspellDicts.pl
    unstable.aspellDicts.la
    unstable.aspellDicts.es
    unstable.aspellDicts.de
  ];

  xdg.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    completionInit = "autoload -Uz compinit && compinit";
    plugins = [
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
      }
      {
        name = "nix-zsh-completions";
        src = pkgs.nix-zsh-completions;
      }
    ];

    # History (keep everything, delete nothing)
    history = {
      size = 10000000;
      save = 10000000;
      extended = true; # :start:elapsed;command format
      share = true; # share across sessions (implies INC_APPEND)
      ignoreDups = true; # skip consecutive duplicates
      ignoreSpace = true; # prefix with space to omit from history
      expireDuplicatesFirst = true; # safety net if size limit is ever hit
    };

    shellAliases = {
      cat = "bat --paging never";
    };

    # ~/.zshenv is sourced for every zsh invocation
    envExtra = lib.fileContents ../config/before.zshenv;

    # initContent replaces the older initExtra/initExtraFirst (HM ≥ 25.11).
    # All interactive-shell init goes here.
    initContent = lib.fileContents ../config/after.zshrc;
  };

  # Starship prompt (gruvbox-rainbow preset, declarative)
  # The preset TOML is fetched from upstream via the
  # starship-gruvbox-rainbow flake input; `nix flake update`
  # pulls the latest version automatically.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile starship-gruvbox-rainbow)) {
      os.symbols.NixOS = ""; # nf-linux-nixos
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name = lib.mkDefault "caocoa";
        email = lib.mkDefault "caocoa@users.noreply.github.com";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      fetch.prune = true;
      rerere.enabled = true;
      merge.conflictstyle = "zdiff3";
      diff.algorithm = "histogram";

      core = {
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
      };

      # Supply-chain hardening to verify integrity of all received objects.
      transfer.fsckObjects = true;
      fetch.fsckObjects = true;
      receive.fsckObjects = true;

      # Block cleartext git:// protocol; allow only https and ssh.
      protocol.allow = "never";
      "protocol.https".allow = "always";
      "protocol.ssh".allow = "always";
      "protocol.file".allow = "user";

      # core.pager and interactive.diffFilter are set automatically
      # by programs.delta, so no need to declare them here.
    };

    ignores = lib.splitString "\n" (lib.fileContents ../config/gitignore);
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = false; # That breaks magit: either override it in magit, or disable it here.
      syntax-theme = "ansi";
    };
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      style = "numbers,changes,header";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # fd respects .gitignore, follows symlinks, and shows hidden files.
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    defaultOptions = [
      "--multi"
      "--height=50%"
      "--layout=reverse"
      "--border=rounded"
      "--info=inline"
      "--bind=ctrl-a:toggle-all"
      "--bind=ctrl-/:toggle-preview"
      "--bind=ctrl-u:preview-half-page-up"
      "--bind=ctrl-d:preview-half-page-down"
      "--bind=alt-up:preview-top"
      "--bind=alt-down:preview-bottom"
    ];
    fileWidgetOptions = [
      "--preview='bat --color=always --style=numbers,changes --line-range=:300 {}'"
      "--preview-window=right:55%:wrap:hidden"
    ];
    changeDirWidgetOptions = [
      "--preview='eza --tree --color=always --icons=auto --level=3 {}'"
      "--preview-window=right:45%:hidden"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
      "--preview='echo {}'"
      "--preview-window=down:3:wrap:hidden"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = ["--group-directories-first"];
  };
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
    escapeTime = 10; # ms; keep low so Emacs M-... sequences are fast
    baseIndex = 1;
    extraConfig = lib.fileContents ../config/tmux.conf;
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.btop.enable = true;
  programs.htop = {
    enable = true;
    settings = {
      show_program_path = false;
      tree_view = true;
      sort_key = 46; # PERCENT_CPU
      highlight_base_name = true;
    };
  };
  programs.gpg = {
    enable = true;
    settings = {
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      keyid-format = "0xlong";
      with-fingerprint = true;
      use-agent = true;
    };
  };
  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = lib.fileContents ../config/gpg-agent.conf;
    pinentry.package =
      if unstable.stdenv.hostPlatform.isDarwin
      then unstable.pinentry-curses
      else if unstable.stdenv.hostPlatform.isLinux
      then unstable.pinentry-gnome3
      else throw "pinentry: unsupported platform";
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
  };

  # nh: NH_OS_FLAKE (set by programs.nh.flake on NixOS) takes precedence
  # over NH_FLAKE for `nh os` commands.  NH_FLAKE is intentionally unset
  # here: the flake path is user-specific and must be supplied at the call
  # site (e.g. `nh home switch /path/to/repo`) or via a shell alias.

  # mu4e: prebuilt elisp on Emacs load-path
  # Append (not override): the trailing ":" tells Emacs to keep defaults.
  home.sessionVariables.EMACSLOADPATH = "${config.programs.mu.package.mu4e}/share/emacs/site-lisp/mu4e:";

  # Native-module compilation (jinx, vterm, …)
  # NixOS has no /usr/include, so expose enchant (+ other lib) headers
  # and pkg-config metadata so `gcc` invoked from inside Emacs can
  # find them.
  home.sessionVariables.PKG_CONFIG_PATH = "${unstable.enchant.dev}/lib/pkgconfig";
  home.sessionVariables.C_INCLUDE_PATH = "${unstable.enchant.dev}/include";
  home.sessionVariables.LIBRARY_PATH = "${lib.getLib unstable.enchant}/lib";

  home.sessionVariables.DICPATH = lib.concatStringsSep ":" [
    "${unstable.hunspellDicts.en_GB-ise}/share/hunspell"
    "${unstable.hunspellDicts.en_US}/share/hunspell"
    "${unstable.hunspellDicts.fr-classique}/share/hunspell"
    "${unstable.hunspellDicts.pl_PL}/share/hunspell"
    "${unstable.hunspellDicts.es_ES}/share/hunspell"
    "${unstable.hunspellDicts.de_DE}/share/hunspell"
    "${unstable.callPackage ../packages/hunspell-dict-la.nix {}}/share/hunspell"
  ];

  xdg.configFile."enchant/enchant.ordering".text = lib.fileContents ../config/enchant.ordering;
  home.file.".aspell.conf".text = lib.fileContents ../config/aspell.conf;

  home.activation.homeLayout = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${lib.fileContents ../scripts/home-layout.sh}
  '';
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      hostname = "github.com";
      identityFile = "~/.ssh/3686502+piotr-yuxuan@users.noreply.github.com_ed25519";
    };
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      forwardAgent = false;
      controlMaster = "auto";
      controlPath = "~/.ssh/control-%C";
      controlPersist = "10m";
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
      hashKnownHosts = true;
      extraOptions = {
        IdentitiesOnly = "yes";
        PasswordAuthentication = "no";
        StrictHostKeyChecking = "accept-new";
      };
    };
  };

  programs.asciinema.enable = true;
  programs.awscli.enable = true;
  programs.fd = {
    enable = true;
    hidden = true;
  };
  programs.gcc.enable = true;
  programs.granted = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.jq.enable = true;
  programs.mu.enable = true;
  programs.opencode = {
    enable = true;
    settings = {
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options.baseURL = "http://localhost:11434/v1";
          models = builtins.listToAttrs (builtins.map (m: {
              name = m.model;
              value = {name = "${m.name} (ollama)";};
            })
            ollamaModels);
        };
      };
    };
  };
  programs.pandoc.enable = true;
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/"
      "--glob=!node_modules/"
      "--glob=!.direnv/"
      "--glob=!straight/repos/"
      "--glob=!eln-cache/"
    ];
  };
  programs.ruff = {
    enable = true;
    settings = {};
  };
  programs.sqls.enable = true;
  programs.tealdeer.enable = true;
  programs.yt-dlp.enable = true;

  #  XDG base directories
  # Practicalli Clojure deps.edn
  # Community aliases for tools.deps.  Tracked as a flake input so
  # `nix flake update` always pulls the latest main commit.
  xdg.configFile."clojure/deps.edn".source = "${practicalli-clojure-deps-edn}/deps.edn";
}
