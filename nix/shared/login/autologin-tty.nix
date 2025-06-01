{ config, lib, pkgs, ... }:
{
  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = [ ""
      "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin root --noclear --keep-baud tty1 115200,38400,9600 $TERM"
    ];
  };

  boot.kernelParams = [ "nomodeset" ];  ## otherwise tty doesn't work with virtualbox.guest.enable
}
