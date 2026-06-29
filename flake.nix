{
  description = "Yorick Adaptive Optics (YAO) tool packaged for Nix.";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.wrappers.url = "github:lassulus/wrappers";
  inputs.self.submodules = true;

  outputs = { self, nixpkgs, flake-utils, wrappers }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        packages = rec {
          spydr = wrappers.lib.wrapPackage rec {
            inherit pkgs;
            exePath = "${package}/bin/_spydr";
            package = yorick-nowrap;
            binName = "spydr";
            env = {
              GDK_SCALE = "1";
              GDK_BACKEND = "x11";
            };
            runtimeInputs = [ pkgs.rlwrap yorick ];
          };
          yao = wrappers.lib.wrapPackage rec {
            inherit pkgs;
            exePath = "${package}/bin/_yao";
            package = yorick-nowrap;
            binName = "yao";
            runtimeInputs = [ pkgs.rlwrap yorick ];
          };
          yorick = wrappers.lib.wrapPackage rec {
            inherit pkgs;
            exePath = "${pkgs.rlwrap}/bin/rlwrap ${package}/bin/_yorick";
            binName = "yorick";
            package = yorick-nowrap;
            runtimeInputs = [ pkgs.rlwrap ];
          };
          yorick-nowrap = pkgs.stdenv.mkDerivation {
            description = "YAO, and all Yorick plugins required for the full YAO experience. ";
            buildInputs = with pkgs; [ 
              libx11 fftw fftwFloat
              gtk3 gobject-introspection wrapGAppsHook3
              (python3.withPackages (p: with p; [ pygobject3 ]))
            ];
            name = "yorick-nowrap";
            src = ./.;
            hardeningDisable = [ "fortify" ];
            buildPhase = ''
              cd yorick
              make install
              cp -r relocate $out
              cd ..
              export GDK_SCALE=1
              export GDK_BACKEND=x11
              for p in yorick-yutils yorick-imutil yorick-soy yorick-spydr yao
              do
                cd $p
                $out/bin/yorick -batch make.i
                make install
                cd ..
              done

              cd yp-svipc/yorick
              $out/bin/yorick -batch make.i
              make install
              cd ..
              
              cd VMLMB/yorick
              ./configure
              make install
              cd ..
              
              mv $out/bin/yorick $out/bin/_yorick
              mv $out/bin/yao $out/bin/_yao
              mv $out/bin/spydr $out/bin/_spydr
            '';
            installPhase = ''
            '';
          };
          default = yao;
        };
      }
    );
}
