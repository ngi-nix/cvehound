{
  description = "An over-engineered Hello World in bash";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  outputs = { self, nixpkgs }:
    let
      version = builtins.substring 0 8 self.lastModifiedDate;
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = final: prev: {
        cvehound = prev.python3Packages.buildPythonPackage rec {
          pname = "cvehound";
          version = "1.0.4";

          src = prev.fetchFromGitHub {
            owner = "evdenis";
            repo = "cvehound";
            rev = version;
            sha256 = "sha256-m8vpea02flQ8elSvGWv9FqBhsEcBzRYjcUk+dc4kb2M=";
          };

          buildInputs = with final; [
            coccinelle
            gnugrep
          ];

          propagatedBuildInputs = with final.python3Packages; [
            psutil
            setuptools
            sympy
          ];

          checkInputs = with final.python3Packages; [
            GitPython
            pytest
          ];
        };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) cvehound;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.cvehound);

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) cvehound;
      });

    };
}
