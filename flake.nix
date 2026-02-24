{
  description = "ratpac-two: RAT, Plus Additional Codes (v2) — Geant4+ROOT simulation framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        isDarwin = pkgs.stdenv.isDarwin;

        geant4 = pkgs.geant4.override { enableQt = true; };
        geant4Datasets = with pkgs.geant4.data; [
          G4ABLA
          G4INCL
          G4PhotonEvaporation
          G4RealSurface
          G4EMLOW
          G4NDL
          G4PII
          G4SAIDDATA
          G4ENSDFSTATE
          G4PARTICLEXS
          G4TENDL
          G4RadioactiveDecay
        ];

        python = pkgs.python3;

        # Nixpkgs' fftw doesn't ship a cmake config with FFTW3::fftw3 target.
        fftw3-cmake = pkgs.writeTextDir "lib/cmake/FFTW3/FFTW3Config.cmake" ''
          if(NOT TARGET FFTW3::fftw3)
            add_library(FFTW3::fftw3 SHARED IMPORTED)
            set_target_properties(FFTW3::fftw3 PROPERTIES
              IMPORTED_LOCATION "${pkgs.fftw}/lib/libfftw3${if isDarwin then ".dylib" else ".so"}"
              INTERFACE_INCLUDE_DIRECTORIES "${pkgs.fftw.dev}/include"
            )
          endif()
          set(FFTW3_FOUND TRUE)
        '';

        ratpac-two = pkgs.stdenv.mkDerivation rec {
          pname = "ratpac-two";
          version = "3.3.0";

          src = pkgs.fetchFromGitHub {
            owner = "rat-pac";
            repo = "ratpac-two";
            rev = version;
            hash = "sha256-6N6HvZo8flIPsUGMxjUuyqZEwEaMI02UVkZdnSDOVKU=";
          };

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
            qt5.wrapQtAppsHook
          ];

          buildInputs = [
            geant4
            pkgs.root
            python
          ]
          ++ (with pkgs; [
            fftw
            fftwFloat
            xercesc
            clhep
            curl
            openssl
            zlib

            libx11
            libxpm
            libxft
            libxext
            libGL
            libGLU
            qt5.qtbase

            (python.withPackages (ps: [
              ps.numpy
            ]))
          ])
          ++ pkgs.lib.optionals (!isDarwin) [
            pkgs.libxkbcommon
          ];

          propagatedBuildInputs = geant4Datasets;

          cmakeFlags = [
            "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DROOT_DIR=${pkgs.root}/cmake"
            "-DFFTW3_DIR=${fftw3-cmake}/lib/cmake/FFTW3"
          ];

          postPatch = ''
            # 1. Remove copy-compile-commands target (writes to read-only source dir)
            sed -i '/add_custom_target(/,/^)/{/copy-compile-commands/,/^)/d; /add_custom_target(/d}' CMakeLists.txt

            # 2. GCC 14 no longer transitively includes <regex>
            sed -i '1i #include <regex>' src/physics/src/PhysicsList.cc

            # 3. ROOT in nixpkgs renamed TPython::Eval -> TPython::Exec
            sed -i 's/TPython::Eval/TPython::Exec/g' src/core/src/PythonProc.cc
          '';

          dontWrapQtApps = true;

          meta = with pkgs.lib; {
            description = "Simulation and analysis package built with Geant4, ROOT, and C++";
            homepage = "https://ratpac.readthedocs.io";
            license = licenses.bsd3;
            platforms = platforms.unix;
          };
        };
      in
      {
        packages.default = ratpac-two;
        packages.ratpac-two = ratpac-two;
      }
    );
}
