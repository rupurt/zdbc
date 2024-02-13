{
  description = "A performance oriented ODBC & Apache Arrow library for Zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    odbc-drivers = {
      url = "github:rupurt/odbc-drivers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    flake-utils,
    nixpkgs,
    zig-overlay,
    odbc-drivers,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          zig-overlay.overlays.default
          odbc-drivers.overlay
        ];
      };
      db2Driver =
        if pkgs.stdenv.isLinux
        then "${pkgs.odbc-driver-pkgs.db2-odbc-driver}/lib/libdb2o.so"
        else "${pkgs.odbc-driver-pkgs.db2-odbc-driver}/lib/libdb2o.dylib";
    in {
      # packages exported by the flake
      packages = {};

      # nix run
      apps = {
        db2-driver = {
          type = "app";
          program = toString (pkgs.writeScript "db2-driver" ''
            echo ${db2Driver}
          '');
        };
      };

      # nix fmt
      formatter = pkgs.alejandra;

      # nix develop -c $SHELL
      devShells.default = pkgs.mkShell.override {stdenv = pkgs.clangStdenv;} {
        name = "default dev shell";

        buildInputs = [
          pkgs.pkg-config
          pkgs.zigpkgs.master
          pkgs.odbc-driver-pkgs.db2-odbc-driver
          pkgs.odbc-driver-pkgs.postgres-odbc-driver
          pkgs.unixODBC
          pkgs.arrow-cpp
        ];

        packages =
          []
          ++ pkgs.lib.optionals (pkgs.stdenv.isLinux) [
            pkgs.strace
          ];

        DB2_DRIVER = db2Driver;
      };
    });
  in
    outputs;
}
