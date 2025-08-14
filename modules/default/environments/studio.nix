{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

{
    config = lib.mkIf(config.glf.environment.enable && (config.glf.environment.edition == "studio" || config.glf.environment.edition == "studio-pro")) {
boot.extraModulePackages = [
    (pkgs.linuxKernel.packages.linux_6_12.v4l2loopback.overrideAttrs
      ({
        version = "0.13.2-manual";
        src = (pkgs.fetchFromGitHub {
          owner = "umlaeute";
          repo = "v4l2loopback";
          rev = "v0.13.2";
          hash = "sha256-rcwgOXnhRPTmNKUppupfe/2qNUBDUqVb3TeDbrP5pnU=";
        });
      })
    )
  ];

programs.obs-studio = {
enable = true;
package = pkgs.obs-studio.override {cudaSupport = true;};
plugins = with pkgs.obs-studio-plugins; [obs-vkcapture  move-transition];
};

 fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      dina-font
      roboto
      lato
      montserrat
      raleway
      oswald
      merriweather
      poppins
      source-sans-pro
      league-spartan
    ];

systemd.tmpfiles.rules = 
  let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [
        rocblas
        hipblas
        clr
      ];
    };
  in [
    "L+    /opt/rocm/hip  -    -    -     -    ${rocmEnv}"
  ];  

        hardware.graphics = {
            enable = true; 
            extraPackages = with pkgs; [
            mesa.opencl # Assure que l'implémentation OpenCL de Mesa (Rusticl) est installée
            ];
          };

        environment.variables = {
          ROC_ENABLE_PRE_VEGA = "1";
          RUSTICL_ENABLE = "radeonsi"; 
        };
    
    environment.systemPackages =
      if config.glf.environment.edition == "studio-pro" then
        with pkgs; [
          davinci-resolve-studio
          gimp3-with-plugins
          audacity
          freetube
          ]
      else
        with pkgs; [
          davinci-resolve
          gimp3-with-plugins
          audacity
          freetube  
          ];
  };
}
