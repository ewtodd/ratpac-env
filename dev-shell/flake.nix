{
  description = "RAT-PAC development environment.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    ratpac-env.url = "github:ewtodd/ratpac-env";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ratpac-env,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Choose which ratpac-two to use:
        #   .ratpac-two       — upstream (rat-pac/ratpac-two)
        #   .ratpac-two-sandk — fork (sandK-31/ratpac-two)
        ratpac = ratpac-env.packages.${system}.ratpac-two;
        isDarwin = pkgs.stdenv.isDarwin;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            ratpac
            pkgs.root
            pkgs.cmake
            pkgs.bash
            (pkgs.python3.withPackages (ps: [
              ps.numpy
              ps.root
            ]))
          ];
          shellHook = ''
            export SHELL="${pkgs.bash}/bin/bash"
            export QT_PLUGIN_PATH="${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}"
            ${
              if !isDarwin then
                ''
                  export QT_QPA_PLATFORM=wayland
                  export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
                  export G4VIS_DEFAULT_DRIVER=TSG_QT_ZB
                  export AMD_VULKAN_ICD=RADV
                  export RADV_PERFTEST=gpl
                  export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
                  export mesa_glthread=false
                  export __GL_THREADED_OPTIMIZATIONS=0
                  export DISPLAY=:0
                ''
              else
                ''
                  export QT_QPA_PLATFORM=cocoa
                ''
            }
            echo "ratpac-two: ${ratpac}"
            echo "ROOT version: $(root-config --version)"

            RATPAC_INC="${ratpac}/include"
            RATPAC_LIB="${ratpac}/lib"

            STDLIB_PATH="${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}"
            STDLIB_MACHINE_PATH="$STDLIB_PATH/${
              if isDarwin then "arm64-apple-darwin" else "x86_64-unknown-linux-gnu"
            }"
            ROOT_INC="$(root-config --incdir)"

            export CPLUS_INCLUDE_PATH="$PWD/include:$STDLIB_PATH:$STDLIB_MACHINE_PATH:$RATPAC_INC:$ROOT_INC''${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"
            export ROOT_INCLUDE_PATH="$PWD/include:$RATPAC_INC''${ROOT_INCLUDE_PATH:+:$ROOT_INCLUDE_PATH}"

            export LD_LIBRARY_PATH="$PWD/lib:$RATPAC_LIB''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          '';
        };
      }
    );
}
