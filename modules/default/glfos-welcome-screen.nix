{
  lib,
  config,
  pkgs,
  ...
}:

let
  glfos-welcome-screen = pkgs.callPackage ../../pkgs/glfos-welcome-screen {};
in

{
  environment.systemPackages = with pkgs; [
      glfos-welcome-screen
  ];
}
