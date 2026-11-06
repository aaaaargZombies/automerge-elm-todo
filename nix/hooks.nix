{
  pkgs,
  git-hooks,
  system,
  elm2nix,
}:
git-hooks.lib.${system}.run {
  src = ./.;
  hooks = {
    nixfmt.enable = true;
    elm-test.enable = false;
    elm-format.enable = true;
    prettier.enable = true;

    elm = {
      enable = true;
      name = "elm";
      description = "Compile the elm project";
      language = "system";
      files = "\\.elm$";
      pass_filenames = false;
      entry = "${pkgs.elmPackages.elm}/bin/elm make --optimize  --output=elm-stuff/elm.js  elm/Main.elm";
    };

    elm-test-rs = {
      enable = true;
      name = "elm-test-rs";
      description = "Run Elm tests with elm-test-rs";
      language = "system";
      files = "\\.elm$";
      pass_filenames = false;
      entry = "${pkgs.elmPackages.elm-test-rs}/bin/elm-test-rs";
    };

    elm-lock = {
      enable = true;
      name = "elm-lock";
      description = "Generate elm.lock";
      language = "system";
      files = "elm.json$";
      pass_filenames = false;
      entry = "${elm2nix}/bin/elm2nix lock";
    };

    ts-check = {
      enable = true;
      name = "ts-check";
      description = "typecheck TS code";
      language = "system";
      files = "\\.ts$";
      pass_filenames = false;
      entry = "${pkgs.typescript}/bin/tsc --noEmit";
    };

    ts-test = {
      enable = true;
      name = "ts-test";
      description = "Run vitest via npm run test:ts";
      language = "system";
      files = "\\.(js|jsx|ts|tsx)$";
      pass_filenames = false;
      entry =
        let
          wrapper = pkgs.writeShellApplication {
            name = "run-ts-test";
            runtimeInputs = [ pkgs.nodejs_26 ];
            text = ''
              npm run test:ts -- run
            '';
          };
        in
        "${wrapper}/bin/run-ts-test";
    };
  };
}
