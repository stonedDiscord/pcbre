{
  description = "A flake for building Hello World";

  inputs.nixpkgs.url = github:NixOS/nixpkgs;
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = {self, nixpkgs, flake-utils}:
   flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system}; 
        my-python = pkgs.python3;
      in
      rec {
        packages = rec {
          # Local version to support pycapnp
          # Nixos has updated to capnproto 0.9, but pycapnp does not yet support
          # Local rule to build old capnp
          capnproto8 = pkgs.stdenv.mkDerivation rec {
            pname = "capnproto8";
            version = "0.8.0";

            # release tarballs are missing some ekam rules
            src = pkgs.fetchurl {
              url = "https://capnproto.org/capnproto-c++-${version}.tar.gz";
              sha256 = "03f1862ljdshg7d0rg3j7jzgm3ip55kzd2y91q7p0racax3hxx6i";
            }; 

            # No cmake - breaks version information
            meta = with pkgs.lib; {
              homepage    = "https://capnproto.org/";
              description = "Cap'n Proto cerealization protocol";
              longDescription = ''
                Cap’n Proto is an insanely fast data interchange format and
                capability-based RPC system. Think JSON, except binary. Or think Protocol
                Buffers, except faster.
              '';
              license     = licenses.mit;
              platforms   = platforms.all;
            };
          };

          pycapnp8 = pkgs.python3Packages.buildPythonPackage rec {
            pname = "pycapnp";
            version = "1.1.0";

            src = pkgs.fetchFromGitHub {
              owner = "capnproto";
              repo = pname;
              rev = "v${version}";
              sha256 = "1xi6df93ggkpmwckwbi356v7m32zv5qry8s45hvsps66dz438kmi";
            };

            nativeBuildInputs = [ capnproto8 pkgs.python3Packages.cython pkgs.python3Packages.pkgconfig pkgs.pkgconfig];

            buildInputs = [ capnproto8 ];

            # Tests depend on schema_capnp which fails to generate
            doCheck = false;

            pythonImportsCheck = [ "capnp" ];
          };
          

          p2t = pkgs.python3Packages.buildPythonPackage rec {
            pname = "p2t";
            version = "0.0.1";
            src = pkgs.fetchFromGitHub {
              owner = "davidcarne";
              repo = "poly2tri.python";
              rev = "refs/heads/master";
              sha256 = "sha256-nD0vRvpi44xLXJluoym2yldfTvgrbqwHXLRn+4ITTQU=";

            };

            # TODO - fix bad "time.clock" and remove this
            doCheck = false;

            buildInputs = [ pkgs.python3Packages.cython ];
          };

          pcbre = pkgs.python3Packages.buildPythonPackage rec {
            name = "pcbre";
            src = self;
            propagatedBuildInputs = with pkgs.python3Packages; [
              opencv4 qtpy numpy scipy freetype-py shapely Rtree pyopengl cython pyqt5 pip setuptools cffi mypy setuptools-rust typed-ast psutil mypy-extensions typing-extensions p2t pycapnp8
            ];
            doCheck = false;

            nativeBuildInputs = [ pkgs.qt5.wrapQtAppsHook ];
            dontWrapQtApps = true;

            preFixup = ''
                  wrapQtApp "$out/bin/pcbre-app"
                  wrapQtApp "$out/bin/pcbre-launcher"
              '';
            postShellHook = ''
                  wrapQtApp "$tmp_path/bin/pcbre-app"
                  wrapQtApp "$tmp_path/bin/pcbre-launcher"
              '';
          };
          default = pcbre;
        };
        

      }
    );
    
}
