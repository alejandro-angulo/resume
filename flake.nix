{
  description = "Resume";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    pkgs = import nixpkgs {
      inherit system;
    };
    lib = pkgs.lib;
    system = "x86_64-linux";
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
    texvars = toString (lib.concatMapStrings (x: ''\\def\\${x}{${"$" + lib.toUpper x}}'') vars);
  in {
    packages.${system} = {
      # inherit system;
      alejandro-resume = pkgs.stdenvNoCC.mkDerivation rec {
        name = "alejandro-resume";
        src = self;
        propogatedBuildInputs = [pkgs.coreutils nerdfonts-hack tex];
        phases = ["unpackPhase" "buildPhase" "installPhase"];
        buildPhase = ''
          cp build.sh alejandro-resume
          sed -i 's!PREFIX=""!PREFIX="${builtins.placeholder "out"}"!g' alejandro-resume
          sed -i 's!PATH=""!PATH="${lib.makeBinPath propogatedBuildInputs}"!g' alejandro-resume
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
    };

    devShells.${system} = {
      default = pkgs.mkShell {
        name = "default";
        buildInputs = with pkgs; [
          alejandra
          direnv
          git
          pre-commit
          tex #TODO: Is this necessary?
          zathura # PDF Viewer
          shellcheck
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
  };
}
