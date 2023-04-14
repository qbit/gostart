{
  description = "gostart: a tailscale aware start page";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      overlay = final: prev: {
        gostart = self.packages.${prev.system}.gostart;
      };
      nixosModule = import ./module.nix;
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          gostart = pkgs.buildGo120Module {
            pname = "gostart";
            version = "v0.1.12";
            src = ./.;

            vendorSha256 =
              "sha256-DvtZQK0bOXJfBYXnT8cRH6W2BOktJMsQCB8BQFw30T0=";
          };
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.gostart);
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            shellHook = ''
              PS1='\u@\h:\@; '
              echo "Go `${pkgs.go}/bin/go version`"
            '';
            nativeBuildInputs = with pkgs; [
              git
              go_1_20
              gopls
              go-tools
              sqlc
              sqlite
              rlwrap
              nodePackages.typescript
            ];
          };
        });
    };
}

