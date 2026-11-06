{
  description = "Development environment for a breathwork app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    elm2nix.url = "github:dwayne/elm2nix";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      elm2nix,
      git-hooks,
      ...
    }@inputs:
    let
      inherit (inputs.nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );

      perSystem = forEachSupportedSystem (
        { pkgs, system }:
        {
          prepElmHome = pkgs.callPackage ./nix/prep-elm-home.nix {
            elm2nixLib = elm2nix.lib.elm2nix pkgs;
            elmLock = ./elm.lock;
            patches = elm2nix.lib.elmSafeVirtualDom.elmHtml;
          };
        }
      );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default =
            let
              inherit
                (import ./nix/hooks.nix {
                  elm2nix = elm2nix.packages.${system}.default;
                  inherit git-hooks pkgs system;
                })
                shellHook
                enabledPackages
                ;
            in
            pkgs.mkShellNoCC {

              shellHook = shellHook + ''
                export ELM_HOME="$PWD/.elm"
              '';

              packages =
                with pkgs;
                [
                  self.formatter.${system}
                  pkgs.elmPackages.elm
                  pkgs.elmPackages.elm-test-rs
                  elm2nix.packages.${system}.default
                  pkgs.nodejs_26
                  pkgs.typescript
                  perSystem.${system}.prepElmHome
                ]
                ++ enabledPackages;
            };
        }
      );

      packages = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.buildNpmPackage {
            name = "Site";

            nativeBuildInputs = [
              pkgs.elmPackages.elm
              elm2nix.packages.${system}.default
              pkgs.nodejs_26
              perSystem.${system}.prepElmHome
            ];
            src = self;
            npmDeps = pkgs.importNpmLock { npmRoot = self; };
            npmConfigHook = pkgs.importNpmLock.npmConfigHook;

            ELM_HOME = ".elm";
            preBuild = ''
              prep-elm-home
            '';

            installPhase = ''
              mkdir -p "$out/share"
              cp -R dist/. "$out/share"/
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
