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
        startpage = self.packages.${prev.system}.startpage;
      };
      nixosModule = import ./module.nix;
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          gostart = pkgs.buildGoModule {
            pname = "gostart";
            version = "v0.0.0";
            src = ./.;

            vendorSha256 =
              "sha256-k2WVSfW/5yayEpdfNdYq22hKxP7/7qbY/d+VYLAWtyQ=";
            proxyVendor = true;
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
              go
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

