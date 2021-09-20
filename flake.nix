{
  description = "A tool to check linux kernel source dump for known CVEs";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = final: prev: {
        cvehound = with final; python3Packages.buildPythonPackage rec {
          pname = "cvehound";
          version = "1.0.4";

          src = fetchFromGitHub {
            owner = "evdenis";
            repo = "cvehound";
            rev = version;
            sha256 = "sha256-m8vpea02flQ8elSvGWv9FqBhsEcBzRYjcUk+dc4kb2M=";
          };

          makeWrapperArgs = [ "--prefix" "PATH" ":" (lib.makeBinPath [
            coccinelle
            gnugrep
          ])];

          propagatedBuildInputs = with python3Packages; [
            psutil
            setuptools
            sympy
          ];

          checkInputs = with python3Packages; [
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
