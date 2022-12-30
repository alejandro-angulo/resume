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
          inherit (pkgs.texlive) scheme-basic latex-bin latexmk enumitem multirow titlesec xcolor fontspec chktex latexindent;
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
              DEBUG=false
              DIR=$(mktemp -d)
              RES=$(pwd)/alejandro_resume.pdf
              LOG=$(pwd)/alejandro_resume.log

              function usage {
                echo "Usage: $(basename $0) [-h] [-d] [-e EMAIL] [-p PHONENUMBER]"
                echo '    -h              Prints this usage message.'
                echo ""
                echo '    -d              Saves latexmk log file (will be named alejandro_resume.log)'
                echo ""
                echo '    -e EMAIL        Sets email address used when building document.'
                echo '                    Can also be set with EMAIL environment variable.'
                echo ""
                echo '    -p PHONENUMBER  Sets phone number used when building the document.'
                echo '                    Can also be set with PHONENUMBER environment variable.'
              }

              while getopts ':de:p:h' flag; do
                case $flag in
                  'd') DEBUG=true;;
                  # Overrides EMAIL and PHONENUMBER envvars if set
                  'e') EMAIL="$OPTARG";;
                  'p') PHONENUMBER="$OPTARG";;
                  'h') usage && exit;;
                  ?) usage && exit 1;;
                esac
              done

              cd $prefix/share
              mkdir -p "$DIR/.texcache/texmf-var"

              env TEXFMHOME="$DIR/.texcache" TEXMFVAR="$DIR/.texcache/texmf-var" \
                  OSFONTDIR=${nerdfonts-hack}/share/fonts \
                latexmk -interaction=nonstopmode -pdf -lualatex \
                -output-directory="$DIR" \
                -pretex="${texvars}"\
                -usepretex alejandro_resume.tex

              mv "$DIR/alejandro_resume.pdf" "$RES"

              if $DEBUG; then
                mv "$DIR/alejandro_resume.log" "$LOG"
              fi

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
