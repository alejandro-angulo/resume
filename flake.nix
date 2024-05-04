{
  description = "Resume";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= alejandr0angul0-resume.cachix.org-1:tLOx+VCWz+yMyONGbgPnhQ3F3E4GylO8QAFxoCwnC34=";
    extra-substituters = "https://devenv.cachix.org https://alejandr0angul0-resume.cachix.org";
  };

  outputs = {
    self,
    nixpkgs,
    devenv,
    systems,
    ...
  } @ inputs: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    packages = forEachSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        alejandro-resume = let
          lib = pkgs.lib;
          nerdfonts-hack = pkgs.nerdfonts.override {
            fonts = ["Hack"];
          };
          tex = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-basic latex-bin latexmk enumitem multirow titlesec xcolor fontspec chktex latexindent etoolbox;
          };
          vars = ["email" "phonenumber"];
          # Create definitions like \def\email{$EMAIL}
          # Each \email command in the tex document will be populated by an EMAIL
          # variable (can be set as an environment variable)
          texvars = toString (lib.concatMapStrings (x: ''\\def\\${x}{${"$" + lib.toUpper x}}'') vars);
        in
          pkgs.stdenvNoCC.mkDerivation rec {
            name = "alejandro-resume";
            src = self;
            propagatedBuildInputs = [pkgs.coreutils nerdfonts-hack tex];
            phases = ["unpackPhase" "buildPhase" "installPhase"];
            buildPhase = ''
              cp build.sh alejandro-resume
              sed -i 's!PREFIX=""!PREFIX="${builtins.placeholder "out"}"!g' alejandro-resume
              sed -i 's!PATH=""!PATH="${lib.makeBinPath propagatedBuildInputs}"!g' alejandro-resume
              sed -i 's!TEXVARS=""!TEXVARS="${texvars}"!g' alejandro-resume
              sed -i 's!NERDFONTS=""!NERDFONTS="${nerdfonts-hack}"!g' alejandro-resume
            '';
            installPhase = ''
              mkdir -p $out/{bin,share}
              cp alejandro_resume.tex $out/share/alejandro_resume.tex
              cp alejandro-resume $out/bin/alejandro-resume
              chmod u+x $out/bin/alejandro-resume
            '';
          };

        default = self.packages.${system}.alejandro-resume;
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      }
    );

    devShells = forEachSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        latexIndent = pkgs.perl538Packages.LatexIndent;
      in {
        default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              pre-commit.hooks = {
                actionlint.enable = true;
                alejandra.enable = true;
                check-added-large-files.enable = true;
                chktex.enable = true;
                end-of-file-fixer.enable = true;
                shellcheck.enable = true;
                trim-trailing-whitespace.enable = true;
                typos = {
                  enable = true;
                  always_run = true;
                };

                latexindent = {
                  enable = true;
                  name = "latexindent";
                  entry = "${latexIndent}/bin/latexindent.pl --overwriteIfDifferent --silent --local";
                  language = "system";
                  types = ["tex"];
                };
              };

              packages = with pkgs; [
                alejandra
                latexIndent
                shellcheck
                zathura
              ];
            }
          ];
        };
      }
    );
  };
}
