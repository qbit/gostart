{
  description = "gostart: a tailscale aware start page";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    overlay = final: prev: {
      gostart = self.packages.${prev.system}.gostart;
    };
    nixosModule = import ./module.nix;
    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      gostart = pkgs.buildGoModule {
        pname = "gostart";
        version = "v0.2.13";
        src = ./.;

        vendorHash = "sha256-XPNQhwGRKjW/qiI/k+hEwVGJlpLRd6wvhGUORuRwHl8=";
      };
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.gostart);
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        shellHook = ''
          PS1='\u@\h:\@; '
          nix run github:qbit/xin#flake-warn
          echo "Go `${pkgs.go}/bin/go version`"
        '';
        nativeBuildInputs = with pkgs; [
          elmPackages.elm
          elmPackages.elm-json
          entr
          git
          go-tools
          go
          gopls
          rlwrap
          sqlc
          sqlite
          nodePackages.uglify-js
        ];
      };
    });
  };
}
