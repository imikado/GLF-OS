{ config, lib, ... }:
with lib;
let
  cfg = config.glf.nvidia_config;

  nvidiaDriverPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "575.64.05";
    sha256_64bit = "sha256-hfK1D5EiYcGRegss9+H5dDr/0Aj9wPIJ9NVWP3dNUC0=";
    sha256_aarch64 = "sha256-GRE9VEEosbY7TL4HPFoyo0Ac5jgBHsZg9sBKJ4BLhsA=";
    openSha256 = "sha256-mcbMVEyRxNyRrohgwWNylu45vIqF+flKHnmt47R//KU=";
    settingsSha256 = "sha256-o2zUnYFUQjHOcCrB0w/4L6xI1hVUXLAWgG2Y26BowBE=";
    persistencedSha256 = "sha256-2g5z7Pu8u2EiAh5givP5Q1Y4zk4Cbb06W37rf768NFU=";
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
