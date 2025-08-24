{ config, lib, ... }:
with lib;
let
  cfg = config.glf.nvidia_config;

  nvidiaDriverPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.76.05";
    sha256_64bit = "sha256-IZvmNrYJMbAhsujB4O/4hzY8cx+KlAyqh7zAVNBdl/0=";
    sha256_aarch64 = "sha256-NL2DswzVWQQMVM092NmfImqKbTk9VRgLL8xf4QEvGAQ=";
    openSha256 = "sha256-xEPJ9nskN1kISnSbfBigVaO6Mw03wyHebqQOQmUg/eQ=";
    settingsSha256 = "sha256-ll7HD7dVPHKUyp5+zvLeNqAb6hCpxfwuSyi+SAXapoQ=";
    persistencedSha256 = "sha256-bs3bUi8LgBu05uTzpn2ugcNYgR5rzWEPaTlgm0TIpHY=";
  };
in
{
  # declare option
  options.glf.nvidia_config = {
    enable = mkOption {
      type = with types; bool;
      default = false;
      description = "Enable nvidia support";
    };
    laptop = mkOption {
      type = with types; bool;
      default = false;
      description = "Enable nvidia laptop management";
    };
    intelBusId = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    nvidiaBusId = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    amdgpuBusId = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  # nvidia configuration
  config = mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      package = nvidiaDriverPackage;
      open = true;

      nvidiaSettings = true;
      modesetting.enable = true;

      prime = {
        intelBusId = optionalString (cfg.intelBusId != null) cfg.intelBusId;
        nvidiaBusId = optionalString (cfg.nvidiaBusId != null) cfg.nvidiaBusId;
        amdgpuBusId = optionalString (cfg.amdgpuBusId != null) cfg.amdgpuBusId;
      };

      dynamicBoost.enable = cfg.laptop;
      powerManagement.enable = cfg.laptop;

    };
  };
}
