{
  description = "Build a cargo project without extra checks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        craneLib = crane.lib.${system};

        synctexFilter = path: _type: builtins.match "^synctex" path != null;
        synctexOrCargo = path: type:
          (synctexFilter path type) || (craneLib.filterCargoSources path type);

        my-crate = craneLib.buildPackage {
          # src = pkgs.lib.cleanSourceWith {
          #   src = craneLib.path ./.;
          #   filter = synctexOrCargo;
          # };
          src = craneLib.path ./.;
          strictDeps = true;

          buildInputs = with pkgs; [
            clang
            libclang
            llvm
            pkg-config
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            pkgs.libiconv
          ];

          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          # Additional environment variables can be set directly
          # MY_CUSTOM_VAR = "some value";
        };
      in
      {
        checks = {
          inherit my-crate;
        };

        packages.default = my-crate;

        apps.default = flake-utils.lib.mkApp {
          drv = my-crate;
        };

        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          # Additional dev-shell environment variables can be set directly
          # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

          # Extra inputs can be added here; cargo and rustc are provided by default.
          packages = [
            # pkgs.ripgrep
          ];
        };
      });
}
