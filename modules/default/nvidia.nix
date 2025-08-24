{ config, lib, ... }:
with lib;
let
  cfg = config.glf.nvidia_config;

  nvidiaDriverPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.76.05";
    sha256_64bit = "sha256-IZvmNrYJMbAhsugR4O/4hzY8cx+KlAqHtzvAVNBdl/0=";
    sha256_aarch64 = "sha256-p/sE/9e5UNy63RI2jpF6a5A43C+yO3z3dY3E6q4R8aE=";
    openSha256 = "sha256-4Yt3dYl3nZ3hA5fHjYk3eX9vYl2cZ9mJ5cI8jW7kH4A=";
    settingsSha256 = "sha256-qHYDad9UoNW9H/R5DuIo+gdXEqTAfAXML3GsA3UJLcM=";
    persistencedSha256 = "sha256-e+W4rY9aF0cZ8sW7kLp8jX/yB7tG3jV/bN6cK9sX2jA=";
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
