{
  description = "Resume";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    with flake-utils.lib;
      eachSystem allSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
        nerdfonts-hack = pkgs.nerdfonts.override {
          fonts = ["Hack"];
        };
        tex = pkgs.texlive.combine {
          # I'm being lazy and using scheme-full instead of specifying what's
          # actually required
          inherit (pkgs.texlive) scheme-full latex-bin latexmk;
        };
        vars = ["email" "phonenumber"];
        # Create definitions like \def\email{$EMAIL}
        # Each \email command in the tex document will be populated by an EMAIL
        # variable (can be set as an environment variable)
        texvars = toString (pkgs.lib.concatMapStrings (x: ''\def\${x}{${"$" + pkgs.lib.toUpper x}}'') vars);
      in rec {
        packages = {
          alejandro-resume = pkgs.stdenvNoCC.mkDerivation rec {
            name = "alejandro-resume";
            src = self;
            propogatedBuildInputs = [pkgs.coreutils nerdfonts-hack tex];
            phases = ["unpackPhase" "buildPhase" "installPhase"];
            SCRIPT = ''
              #!/usr/bin/env bash

              prefix=${builtins.placeholder "out"}
              export PATH="${pkgs.lib.makeBinPath propogatedBuildInputs}";
              DIR=$(mktemp -d)
              RES=$(pwd)/alejandro_resume.pdf

              cd $prefix/share
              mkdir -p "$DIR/.texcache/texmf-var"

              env TEXFMHOME="$DIR/.texcache" TEXMFVAR="$DIR/.texcache/texmf-var" \
                  OSFONTDIR=${nerdfonts-hack}/share/fonts
                latexmk -interaction=nonstopmode -pdf -lualatex \
                -output-directory="$DIR" \
                -pretex="${texvars}"\
                -usepretex alejandro_resume.tex

              mv "$DIR/alejandro_resume.pdf" $RES
              rm -rf $DIR
            '';
            buildPhase = ''
              printenv SCRIPT > alejandro-resume
            '';
            installPhase = ''
              mkdir -p $out/{bin,share}
              cp alejandro_resume.tex $out/share/alejandro_resume.tex
              cp alejandro-resume $out/bin/alejandro-resume
              chmod u+x $out/bin/alejandro-resume
            '';
          };
        };
        defaultPackage = packages.alejandro-resume;

        devShells = {
          default = pkgs.mkShell {
            name = "default";
            buildInputs = with pkgs; [
              alejandra
              direnv
              git
              pre-commit
              tex #TODO: Is this necessary?
              zathura # PDF Viewer
            ];

            shellHook = ''
              PATH=${pkgs.writeShellScriptBin "nix" ''
                ${pkgs.nixVersions.stable}/bin/nix --experimental-features "nix-command flakes" "$@"
              ''}/bin:$PATH

              if [ ! -f ".git/hooks/pre-commit" ]; then
                pre-commit install &> /dev/null
              fi
            '';
          };
        };
      });
}
