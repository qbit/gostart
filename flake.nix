{
  description = "gostart: a tailscale aware start page";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      overlays.default = final: prev: {
        gostart = self.packages.${prev.stdenv.hostPlatform.system}.gostart;
      };
      nixosModules.default = import ./module.nix;
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          gostart = pkgs.buildGoModule {
            pname = "gostart";
            version = "v0.2.15";
            src = ./.;

            vendorHash = "sha256-ftJES1lZWWC83SDgAwHaYJ5YBA8p2ESKqfbY2Z7zstM=";
            vendorProxy = true;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
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
              go
              go-tools
              gopls
              nodePackages.uglify-js
              rlwrap
              sqlc
              sqlite
            ];
          };
        }
      );
    };
}
