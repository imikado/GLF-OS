{ lib, config, ... }:

{

  options.glf.pipewire.enable = lib.mkOption {
    description = "Enable GLF pipewire configurations";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.glf.pipewire.enable {

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      jack.enable = true;
      pulse.enable = true;

extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 128;
      "default.clock.min-quantum" = 128;
      "default.clock.max-quantum" = 128;
    };
  };
      alsa = {
        enable = true;
        support32Bit = true;
      };

      wireplumber.extraConfig = {
        "10-disable-camera" = {
          "wireplumber.profiles" = {
            main = {
              "monitor.libcamera" = "disabled";
            };
          };
        };
      };

    };
  };

}
