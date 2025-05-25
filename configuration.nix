# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./genode-bootloader.nix
    ];

  networking.hostName = "nixos-and-genode";  ## Define your hostname. Use the same name in flake.nix
  networking.hostId = "57d429f6";  ## Required for zfs



  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  ## Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  ## Easiest to use and most distros use this by default.


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim tmux git
    wget
    htop atop
    chromium
  ];


  #virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.guest = {
    enable = true;  ## required for: <Display controller="VBoxSVGA"/> in machine.vbox6
    vboxsf = true;  ## allows: mount.vboxsf shared /mnt/
  };

  systemd.services."virtualbox".enable = false;  ## due to ERR_NOT_SUPPORTED

  fileSystems."/genode" = {
    fsType = "vboxsf";
    device = "shared";
    noCheck = true;
    options = [ "nofail" ];
  };


  ## fallback in case mbr-pt.vmdk doesn't contain the expected partlabels
  boot.initrd = {
    preLVMCommands = lib.mkBefore ''
      echo @@@ preLVMCommands @@@
      [ -e /dev/sda4 ] && ! [ -e /dev/disk/by-partlabel/disk-main-luks ] && ln -s /dev/sda4 /dev/disk/by-partlabel/disk-main-luks && ls -l /dev/disk/by-partlabel/disk-main-luks
      [ -e /dev/sda2 ] && ! [ -e /dev/disk/by-partlabel/disk-main-ESP ]  && ln -s /dev/sda2 /dev/disk/by-partlabel/disk-main-ESP  && ls -l /dev/disk/by-partlabel/disk-main-ESP
      echo @@@ preLVMCommands @@@
    '';
    postResumeCommands = lib.mkAfter ''
      echo @@@ postResumeCommands @@@
      ## We change the zfs-clone to be used as / by modifying initrd-fsinfo depending on /proc/cmdline
      cat /proc/cmdline

      for o in $(cat /proc/cmdline); do
        case $o in
          fsinfo.root=*)
            set -- $(IFS==; echo $o)
            DEV=$2
            DEV_ORIG="zroot/root"  ## TODO for now it is hardcoded, take it from fsinfo

            sed -i "s@^$DEV_ORIG\$@$DEV@" /nix/store/*initrd-fsinfo
            ;;
        esac
      done

      cat /nix/store/*initrd-fsinfo
      echo @@@ postResumeCommands @@@
    '';
  };


  specialisation."root2".configuration = {
    boot.kernelParams = [ "fsinfo.root=zroot/root2" ];
  };


  ## Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];



  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.mate.enable = true;
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."user" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [];
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # programs.firefox.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";  ## authorized_keys only

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
