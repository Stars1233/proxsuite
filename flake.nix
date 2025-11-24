{
  description = "Advanced Proximal Optimization Toolbox";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, lib, ... }:
      {
        systems = inputs.nixpkgs.lib.systems.flakeExposed;
        flake.overlays = {
          default = final: prev: {
            proxsuite = prev.proxsuite.overrideAttrs {
              src = lib.fileset.toSource {
                root = ./.;
                fileset = lib.fileset.unions [
                  ./benchmark
                  ./bindings
                  ./cmake-external
                  ./CMakeLists.txt
                  ./doc
                  ./examples
                  ./include
                  ./package.xml
                  ./test
                ];
              };
              postPatch = "";
            };
          };
          eigen_5 = final: prev: {
            eigen = final.eigen_5;
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (python-final: python-prev: {
                scipy = python-prev.scipy.overrideAttrs {
                  # broken on linux arm
                  doInstallCheck = false;
                };
              })
            ];
          };
        };
        perSystem =
          {
            pkgs,
            pkgs-eigen_5,
            self',
            system,
            ...
          }:
          {
            _module.args = {
              pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = [ self.overlays.default ];
              };
              pkgs-eigen_5 = import inputs.nixpkgs {
                inherit system;
                overlays = [
                  self.overlays.eigen_5
                  self.overlays.default
                ];
              };
            };
            apps.default = {
              type = "app";
              program = pkgs.python3.withPackages (_: [ self'.packages.default ]);
            };
            packages = {
              default = self'.packages.proxsuite;
              proxsuite = pkgs.python3Packages.proxsuite;
              proxsuite-eigen_5 = pkgs-eigen_5.python3Packages.proxsuite;
            };
          };
      }
    );
}
