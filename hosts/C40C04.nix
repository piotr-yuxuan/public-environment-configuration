{ config, lib, pkgs, unstable, ... }:

{
  networking.hostName = "C40C04";

  # ── Boot ────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
    autoGenerateKeys.enable = true;
    autoEnrollKeys = {
      enable = true;
      includeMicrosoftKeys = true;
    };
  };

  # ── Initrd ──────────────────────────────────────────────────────
  boot.initrd.systemd.enable = true;
  # LUKS device is declared by disko — do NOT redeclare it here.
  # Early KMS (amdgpu in initrd) is handled by nixos-hardware's
  # framework-16-7040-amd profile via hardware.amdgpu.initrd.enable.

  # ── Hibernate ───────────────────────────────────────────────────
  boot.resumeDevice = "/dev/vg-C40C04/lv-swap";

  # ── Kernel ──────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Keyboard layout — EVERYWHERE ────────────────────────────────
  # 1. XKB layout (used by GNOME/Wayland and as source for console)
  services.xserver.xkb = {
    layout = "fr";
    variant = "oss";
  };

  # 2. Virtual console (TTY) — derive from xkb so they always match
  console.useXkbConfig = true;
  # Push the keymap into initrd so LUKS passphrase prompt is also French
  console.earlySetup = true;

  # ── GNOME + Wayland ─────────────────────────────────────────────
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Force Wayland (GDM defaults to Wayland, but be explicit)
  services.displayManager.gdm.wayland = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;

  # ── Sound ───────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Time synchronisation ─────────────────────────────────────────
  # NTP via systemd-timesyncd: keeps the hardware clock accurate.
  services.timesyncd.enable = true;

  # ── Btrfs tools ──────────────────────────────────────────────────
  environment.systemPackages = [ pkgs.compsize ];

  # ── Btrfs maintenance ──────────────────────────────────────────
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # ── Automated btrfs snapshots (home directory) ─────────────────
  # Hourly local snapshots of /home/caocoa into /.snapshots/.
  # Persistent=true on the timer guarantees a snapshot on every boot
  # (catches up missed runs while the machine was off).
  services.btrbk.instances.home = {
    onCalendar = "hourly";
    settings = {
      snapshot_create  = "always";       # no remote target — force local snapshots
      snapshot_preserve_min = "2h";
      snapshot_preserve     = "24h 5d 3w";  # 24 hourly, 5 daily, 3 weekly

      volume."/" = {
        snapshot_dir = ".snapshots";
        subvolume."home/caocoa" = {};
      };
    };
  };

  systemd.timers."btrbk-home".timerConfig.Persistent = true;

  # ── Snapshot failure alert ─────────────────────────────────────
  # Wall message + critical desktop notification when btrbk fails.
  systemd.services."btrbk-home".unitConfig.OnFailure = [ "btrbk-home-failure-alert.service" ];
  systemd.services."btrbk-home-failure-alert" = {
    description = "Alert on btrbk snapshot failure";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "btrbk-failure-alert" ''
        ${pkgs.util-linux}/bin/wall "SNAPSHOT FAILURE: btrbk-home.service failed. Run: journalctl -u btrbk-home.service"
        uid=$(${pkgs.coreutils}/bin/id -u caocoa)
        if [ -d "/run/user/$uid" ]; then
          /run/wrappers/bin/sudo -u caocoa \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            ${pkgs.libnotify}/bin/notify-send -u critical \
            "Snapshot FAILED" \
            "btrbk-home.service failed — run: journalctl -u btrbk-home.service"
        fi
      '';
    };
  };

  # ── Power management ────────────────────────────────────────────
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandlePowerKey = "hibernate";
  };

  systemd.sleep.extraConfig = "HibernateDelaySec=30min";

  # ── Kernel hardening ────────────────────────────────────────────
  security.protectKernelImage = true;   # block /dev/mem + kexec (protects Secure Boot chain)

  boot.kernel.sysctl = {
    # Restrict ptrace to direct parent only (blocks debugger-based escalation)
    "kernel.yama.ptrace_scope" = 2;
    # Hide kernel pointers from unprivileged users
    "kernel.kptr_restrict" = 2;
    # Disable Magic SysRq (not needed on a personal laptop)
    "kernel.sysrq" = 0;
    # Prevent unprivileged BPF (large kernel attack surface)
    "kernel.unprivileged_bpf_disabled" = 1;
    # Harden BPF JIT compiler
    "net.core.bpf_jit_harden" = 2;
  };

  # ── Thunderbolt / USB4 authorisation ────────────────────────────
  # Framework 16 AMD 7040 has USB4 (Thunderbolt 4). Bolt lets GNOME
  # prompt the user before authorising new Thunderbolt/USB4 devices,
  # preventing rogue DMA attacks from plugged-in peripherals.
  services.hardware.bolt.enable = true;

  # ── Crash logging (pstore) ──────────────────────────────────────
  # On kernel panic, the firmware writes the last dmesg to UEFI NVRAM
  # ("pstore").  systemd-pstore (already enabled by NixOS) archives it
  # to /var/lib/systemd/pstore/ on the next boot.  The kernel param
  # below ensures the full ring buffer is flushed to pstore on panic.
  boot.kernelParams = [
    "printk.always_kmsg_dump=1"
    "quiet"
    "splash"
  ];

  # ── Plymouth — graphical boot splash ────────────────────────────
  boot.plymouth.enable = true;

  # ── GPU acceleration (AMD Radeon 780M / Phoenix iGPU) ───────────
  # nixos-hardware already enables:
  #   • hardware.graphics.enable       (Mesa: OpenGL + Vulkan/RADV)
  #   • hardware.graphics.enable32Bit  (32-bit Mesa for Wine/Steam)
  #   • hardware.amdgpu.initrd.enable  (early KMS in initrd)
  #
  # VA-API: hardware video decode/encode — saves battery on laptop.
  hardware.graphics.extraPackages = with pkgs; [
    # AMD VA-API driver (H.264, HEVC, VP9, AV1 decode on the iGPU)
    libvdpau-va-gl          # VDPAU-over-VA-API shim for apps that use VDPAU
  ];

  # Tell VA-API to use the radeonsi driver (Mesa's built-in)
  environment.variables.LIBVA_DRIVER_NAME = "radeonsi";

  # OpenCL via ROCm — for GPU compute (Blender, Darktable, AI, etc.)
  hardware.amdgpu.opencl.enable = true;

  system.stateVersion = "25.11";
  
  
  # maestral daemon — background sync
  systemd.user.services.maestral = {
    description = "Maestral Dropbox daemon";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.maestral}/bin/maestral start --foreground";
      ExecStop  = "${pkgs.maestral}/bin/maestral stop";
      Restart   = "on-failure";
      Nice      = 10;
    };
  };

  # maestral-qt tray icon — needs GTK schemas in XDG_DATA_DIRS to avoid crash
  systemd.user.services.maestral-gui = {
    description = "Maestral Qt tray icon";
    wantedBy = [ "graphical-session.target" ];
    after    = [ "maestral.service" ];
    environment = {
      # Provide the GTK3 GSettings schemas that maestral_qt requires
      XDG_DATA_DIRS = lib.concatStringsSep ":" [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
        "/run/current-system/sw/share"
        "%h/.local/share"
      ];
    };
    serviceConfig = {
      ExecStart = "${pkgs.maestral-gui}/bin/maestral_qt";
      Restart   = "on-failure";
    };
  };
}
