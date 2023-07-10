{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }@inputs:
    let
      package = "sketch";
      version = "1.7.6";
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        sketch = pkgs.stdenv.mkDerivation {
          pname = package;
          version = version;

          src = pkgs.fetchurl {
            urls = [
              "https://people.csail.mit.edu/asolar/sketch-${version}.tar.gz"
            ];
            sha256 = "01x75pkxlv74s1lscdd6w1nxzjrq3av8rbgrbwhk5m8zhk7cknjw";
          };

          nativeBuildInputs = [ pkgs.bison pkgs.flex ];

          enableParallelBuilding = true;
          preConfigure = "cd sketch-backend";
          preBuild = "make clean";
          postInstall = ''
            cd ../sketch-frontend
            mkdir -p $out/share $out/lib $out/bin
            cp sketch-${version}-noarch.jar $out/lib/sketch.jar
            cp -r sketchlib runtime $out/share/
          '';
        };

        sketch-wrapper = pkgs.writeShellApplication {
          name = "sketch";

          runtimeInputs = [ pkgs.jdk11_headless sketch ];

          text = ''
            ${pkgs.jdk11_headless}/bin/java -cp ${sketch}/lib/sketch.jar -ea sketch.compiler.main.seq.SequentialSketchMain "$@"
          '';
        };
      in {
        packages = {
          sketch = sketch;
          sketch-wrapper = sketch-wrapper;
        };

        defaultPackage = sketch-wrapper;
      });
}
