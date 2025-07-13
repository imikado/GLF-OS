{ lib, config, pkgs, ... }:

let

  wireplumberConfig = {
    "10-disable-camera" = {
      "wireplumber.profiles" = {
        main = {
          "monitor.libcamera" = "disabled";
        };
      };
    };
  };

  pipewireExtraConfig = {
    pipewire."10-umc404hd" = {
      "context.modules" = [
        {
          name = "libpipewire-module-loopback";
          args = {
            node.description = "UMC Speakers";
            capture.props = {
              node.name = "UMC_Speakers";
              media.class = "Audio/Sink";
              audio.position = "FL,FR";
            };
            playback.props = {
              node.name = "playback.UMC_Speakers";
              audio.position = "AUX0,AUX1";
              target.object = "alsa_output.usb-BEHRINGER_UMC404HD_192k-00.pro-output-0";
              stream.dont-remix = true;
              node.passive = true;
            };
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            node.description = "UMC Headphones";
            capture.props = {
              node.name = "UMC_Headphones";
              media.class = "Audio/Sink";
              audio.position = "FL,FR";
            };
            playback.props = {
              node.name = "playback.UMC_Headphones";
              audio.position = "AUX2,AUX3";
              target.object = "alsa_output.usb-BEHRINGER_UMC404HD_192k-00.pro-output-0";
              stream.dont-remix = true;
              node.passive = true;
            };
          };
        }
      ];
    };
    
    pipewire."91-min-quantum" = {
      "context.properties" = {
        "default.clock.min-quantum" = 1024;
      };
    };
    
    # Configuration pour désactiver le microphone d'entrée par défaut
    pipewire."01-microphone" = {
      "context.filter" = {
        in.ports = [ "alsa_input.usb-..." ];
        out.props = { "node.disable" = true; };
      };
    };
  };

in {

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

      alsa = {
        enable = true;
        support32Bit = true;
      };

      wireplumber.extraConfig = wireplumberConfig;

      extraConfig = pipewireExtraConfig;
    };

  };

}
