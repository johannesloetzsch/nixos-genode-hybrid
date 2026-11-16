## Seeds the Genode partition and keeps the pinned Sculpt versions in sync.
##
## GENODE*:/boot holds exactly one system image and belongs to Sculpt: we seed
## it once, then Sculpt replaces it on its own on-target updates. We only touch
## it again with `genode.install.force` (repair).
##
## The versions pinned by this repository (`latestVersion` + `extraVersions`)
## live on the ESP below /sculpt/<version>/ and are maintained here,
## independent of any previous state: pinned versions are re-synced, unknown
## ones are removed.
{ config, lib, pkgs, ... }:
let
  cfg = config.genode.install;

  sculpt = import ./sculpt { inherit pkgs; };
  pinned = lib.attrNames sculpt;
  versions = lib.optional cfg.useLatestVersion cfg.latestVersion ++ cfg.extraVersions;

  syncCalls = lib.concatMapStrings (v: ''
    sync ${v} ${sculpt.${v}}
  '') versions;

  script = pkgs.writeShellApplication {
    name = "genode-install";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.rsync
      pkgs.util-linux
    ];
    text = ''
      target=${lib.escapeShellArg cfg.target}
      esp=${lib.escapeShellArg cfg.espPath}
      keep=" ${lib.concatStringsSep " " versions} "
      force=${if cfg.force then "1" else "0"}

      ## never write into (or garbage-collect) an unmounted ESP: that would hit
      ## the root filesystem instead
      mountpoint -q "$esp" || {
        echo "genode-install: $esp is not mounted, refusing to touch it." >&2
        exit 1
      }

      seed() {
        local src=$1
        if [ -e "$target/boot/grub/grub.cfg" ] && [ "$force" != 1 ]; then
          echo "genode-install: $target/boot already holds a Sculpt system image, leaving it to Sculpt."
          echo "genode-install: use --force (or genode.install.force = true) to repair it."
        elif ! mountpoint -q "$target"; then
          echo "genode-install: $target is not mounted, skipping the seed."
        else
          echo "genode-install: seeding $target/boot with Sculpt ${cfg.latestVersion}"
          mkdir -p "$target/boot"
          cp -r --no-preserve=mode "$src"/boot/. "$target/boot"/
        fi
      }

      sync() {
        local v=$1 src=$2 dir
        dir=$esp/sculpt/$1
        mkdir -p "$dir"
        rsync -r --delete --no-perms --no-owner --no-group --no-times --chmod=Du+w,Fu+w "$src"/boot/ "$dir"/
        sed -i "s|/boot/|/sculpt/$v/|g" "$dir/grub/grub.cfg"
        grep -q "/sculpt/$v/bender" "$dir/grub/grub.cfg"
        echo "genode-install: Sculpt $v is installed at $dir"
      }

      seed ${sculpt.${cfg.latestVersion}}

${syncCalls}
      for dir in "$esp"/sculpt/*; do
        [ -d "$dir" ] || continue
        v=$(basename "$dir")
        case "$keep" in
          *" $v "*) ;;
          *)
            echo "genode-install: removing $dir, Sculpt $v is no longer pinned"
            rm -rf "$dir"
            ;;
        esac
      done
    '';
  };
in
{
  options.genode.install = {
    enable = lib.mkEnableOption "installing and updating the pinned Sculpt OS versions";

    target = lib.mkOption {
      type = lib.types.str;
      default = "/genode/rw";
      description = "Mountpoint of the GENODE partition (genode.disk.genode.mountpoint).";
    };

    espPath = lib.mkOption {
      type = lib.types.str;
      default = "/boot";
      description = "Mountpoint of the ESP; pinned versions go to `espPath/sculpt/<version>`.";
    };

    latestVersion = lib.mkOption {
      type = lib.types.str;
      default = lib.last pinned;
      description = "Sculpt version offered as \"Genode (latest)\". Defaults to the newest pinned release.";
    };

    useLatestVersion = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Provide the latest version as its own GRUB entry and ESP tree.";
    };

    extraVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      ## a version that already has its own entry as the latest one is not
      ## pinned twice; the same applies to repeated entries
      apply =
        vs:
        lib.unique (lib.subtractLists (lib.optional cfg.useLatestVersion cfg.latestVersion) vs);
      description = "Additional pinned Sculpt versions, each with its own GRUB entry and ESP tree.";
    };

    force = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Overwrite an existing Sculpt system image on the GENODE partition (repair).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = lib.elem cfg.latestVersion pinned;
          message = "genode.install.latestVersion must be one of: ${lib.concatStringsSep ", " pinned}";
        }
        {
          assertion = lib.all (v: lib.elem v pinned) cfg.extraVersions;
          message = "genode.install.extraVersions must be a subset of: ${lib.concatStringsSep ", " pinned}";
        }
      ];

      system.build.genodeInstall = script;

      ## also available as `genode-install` in PATH (e.g. inside `nixos-enter`)
      environment.systemPackages = [ script ];

      systemd.services.genode-install = {
        description = "Seed Sculpt OS and sync the pinned Sculpt versions to the ESP";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${script}/bin/genode-install";
        };
      };
    })
  ];
}
