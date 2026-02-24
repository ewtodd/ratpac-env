# RAT-PAC Nix Flake
<!---->
Nix flake that packages [ratpac-two](https://github.com/rat-pac/ratpac-two) (RAT, Plus Additional Codes v2), a Geant4+ROOT simulation framework.
<!---->
`nix build` has been tested successfully on `x86_64-linux`, but the resulting package still needs to be exercised on actual ratpac simulation code to be fully verified.
<!---->
## Usage
<!---->
Initialize a dev shell template in a new project directory:
```
nix flake init -t github:ewtodd/ratpac-env --refresh
```
