{
  disko.devices = {
    disk.nvme0n1 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings = {
                # TRIM passthrough: trades a small metadata leak (which blocks
                # are free) for SSD longevity and performance.  Acceptable on
                # a personal laptop with physical security.
                allowDiscards = true;
              };
              content = {
                type = "lvm_pv";
                vg = "vg-C40C04";
              };
            };
          };
        };
      };
    };

    lvm_vg."vg-C40C04" = {
      type = "lvm_vg";
      lvs = {
        lv-swap = {
          size = "72G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        lv-btrfs = {
          size = "100%FREE";
          content = {
            type = "btrfs";
            extraArgs = ["-f"];

            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "@caocoa" = {
                mountpoint = "/home/caocoa";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "@caocoa-cache" = {
                mountpoint = "/home/caocoa/.cache";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "@.snapshots" = {
                mountpoint = "/.snapshots";
                mountOptions = ["compress=zstd" "noatime"];
              };
            };
          };
        };
      };
    };
  };
}
