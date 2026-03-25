# Home Manager base module (cross-platform).
#
# Imported by both C40C04 (NixOS) and work (standalone macOS).
# Per-host overrides live in home/C40C04.nix and home/work.nix.
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
}: {
  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  #  Packages: cross-platform CLI tools (both hosts)

  home.packages =
    [
      # Build toolchain
      unstable.gcc
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
      unstable.neil # manage deps.edn aliases & deps

      # Language servers (eglot)
      unstable.clojure-lsp
      unstable.texlab # LaTeX language server
      unstable.pyright
      unstable.nodePackages.typescript-language-server
      unstable.nodePackages.typescript
      unstable.ltex-ls
      unstable.jdt-language-server
      unstable.bash-language-server
      unstable.dockerfile-language-server
      unstable.sqls
      unstable.yaml-language-server

      # Formatters
      unstable.alejandra # Nix formatter (opinionated)
      unstable.black
      unstable.isort
      unstable.ruff
      unstable.yamlfmt
      unstable.shfmt
      unstable.nodePackages.prettier

      # Linters
      unstable.shellcheck
      unstable.yamllint

      # Search & navigation
      unstable.ripgrep
      unstable.tealdeer # fast tldr with simplified man pages

      # CLI utilities
      unstable.fortune
      unstable.macchina
      unstable.jq
      unstable.yq-go
      unstable.curl
      unstable.tokei
      unstable.asciinema
      unstable.bmon
      unstable.coreutils
      unstable.duckdb
      unstable.enca
      unstable.fx
      unstable.qrencode
      unstable.silver-searcher
      unstable.tree
      unstable.poppler-utils # pdftotext, pdfinfo, etc. (xpdf is CVE-marked)
      unstable.yt-dlp
      unstable.ffmpeg # media processing (also used by yt-dlp)
      unstable.ispell
      unstable.age # modern file encryption
      unstable.graphviz
      unstable.pandoc
      unstable.inxi
      unstable.lsof

      # IaC / Cloud
      unstable.awscli2
      unstable.aws-vault # secure AWS credential management
      unstable.granted # fast AWS role switching
      unstable.ssm-session-manager-plugin
      unstable.podman
      unstable.sops
      unstable.tenv
      unstable.terraform-ls
      unstable.terraform-lsp
      unstable.terraform-landscape

      # CloudFormation
      pkgs.python3Packages.cfn-lint # CloudFormation template linter
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

      # AI / ML
      unstable.ollama
      unstable.openai-whisper
      unstable.open-webui # local web UI for Ollama / OpenAI-compatible LLMs
    ]
    ++ (import ../fonts.nix {inherit unstable;})
    ++ [
      # Build tools
      unstable.meson
      unstable.ninja

      # Email
      unstable.mu
      unstable.mu.mu4e # prebuilt mu4e elisp (added to load-path below)
      unstable.isync # provides mbsync

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
      unstable.aspell
      unstable.aspellDicts.en
      unstable.aspellDicts.fr
      unstable.aspellDicts.pl
      unstable.aspellDicts.la
      unstable.aspellDicts.es
      unstable.aspellDicts.de
    ];

  #  Fonts

  fonts.fontconfig.enable = true;

  #  Program modules: structured config via Home Manager

  # Zsh
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
  programs.starship = let
    upstream = builtins.fromTOML (builtins.readFile starship-gruvbox-rainbow);
  in {
    enable = true;
    enableZshIntegration = true;
    settings = lib.recursiveUpdate upstream {
      os.symbols.NixOS = ""; # nf-linux-nixos
    };
  };

  # Git
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

  # Delta (diff pager)
  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = false; # That breaks magit: either override it in magit, or disable it here.
      syntax-theme = "ansi";
    };
  };

  # Bat
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      style = "numbers,changes,header";
    };
  };

  # Fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = ["--multi" "--height=40%" "--layout=reverse"];
  };

  # Zoxide
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Eza (ls replacement)
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = ["--group-directories-first"];
  };

  # Direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Btop
  programs.btop.enable = true;

  # Htop
  programs.htop = {
    enable = true;
    settings = {
      show_program_path = false;
      tree_view = true;
      sort_key = 46; # PERCENT_CPU
      highlight_base_name = true;
    };
  };

  # GnuPG
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

  # GPG agent
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

  # mu4e: prebuilt elisp on Emacs load-path
  # Append (not override): the trailing ":" tells Emacs to keep defaults.
  home.sessionVariables.EMACSLOADPATH = "${unstable.mu.mu4e}/share/emacs/site-lisp/mu4e:";

  # Native-module compilation (jinx, vterm, …)
  # NixOS has no /usr/include, so expose enchant (+ other lib) headers
  # and pkg-config metadata so `gcc` invoked from inside Emacs can
  # find them.
  home.sessionVariables.PKG_CONFIG_PATH = "${unstable.enchant.dev}/lib/pkgconfig";
  home.sessionVariables.C_INCLUDE_PATH = "${unstable.enchant.dev}/include";
  home.sessionVariables.LIBRARY_PATH = "${lib.getLib unstable.enchant}/lib";

  # Hunspell / Enchant / Aspell paths
  home.sessionVariables.DICPATH = lib.concatStringsSep ":" [
    "${unstable.hunspellDicts.en_GB-ise}/share/hunspell"
    "${unstable.hunspellDicts.en_US}/share/hunspell"
    "${unstable.hunspellDicts.fr-classique}/share/hunspell"
    "${unstable.hunspellDicts.pl_PL}/share/hunspell"
    "${unstable.hunspellDicts.es_ES}/share/hunspell"
    "${unstable.hunspellDicts.de_DE}/share/hunspell"
  ];

  xdg.configFile."enchant/enchant.ordering".text = lib.fileContents ../config/enchant.ordering;

  home.file.".aspell.conf".text = lib.fileContents ../config/aspell.conf;

  # SSH
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

  # Ripgrep XDG config
  home.sessionVariables.RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";

  xdg.configFile."ripgrep/config".text = lib.fileContents ../config/ripgrep.conf;

  #  XDG base directories
  # Practicalli Clojure deps.edn
  # Community aliases for tools.deps.  Tracked as a flake input so
  # `nix flake update` always pulls the latest main commit.
  xdg.configFile."clojure/deps.edn".source = "${practicalli-clojure-deps-edn}/deps.edn";

  xdg.enable = true;
}
