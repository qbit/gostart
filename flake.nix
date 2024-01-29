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
      gostart = pkgs.buildGo121Module {
        pname = "gostart";
        version = "v0.2.12";
        src = ./.;

        vendorHash = "sha256-E6MaIzAVNz0zS5rtN1LdE32U54BJXNzt6s8p8efNryo=";
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
          echo "Go `${pkgs.go_1_21}/bin/go version`"
        '';
        nativeBuildInputs = with pkgs; [
          elmPackages.elm
          elmPackages.elm-json
          entr
          git
          go-tools
          go_1_21
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
