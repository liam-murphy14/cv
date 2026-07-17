{
  description = "Nix flake for my cv in latex";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );
      tex =
        pkgs:
        pkgs.texliveBasic.withPackages (
          ps: with ps; [
            latexmk
            geometry
            hyperref
            xcolor
            fontspec
            tex-gyre
            enumitem
            ulem
            cmap
          ]
        );
    in
    {
      packages = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.stdenvNoCC.mkDerivation rec {
            name = "documents";
            src = self;
            buildInputs = [
              pkgs.coreutils
              (tex pkgs)
            ];
            phases = [
              "unpackPhase"
              "buildPhase"
              "installPhase"
            ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              export HOME=$(mktemp -d)
              mkdir -p $HOME/.cache/texmf-var
              export TEXMFHOME=$HOME/.cache
              export TEXMFVAR=$HOME/.cache/texmf-var
              export SOURCE_DATE_EPOCH=${toString self.lastModified}
              latexmk -interaction=nonstopmode -pdf -lualatex \
                -pretex="\pdfvariable suppressoptionalinfo 512\relax" -usepretex cv.tex
              luaotfload-tool --cache=erase --flush-lookups --force
            '';
            installPhase = ''
              mkdir -p $out
              cp cv.pdf $out/
            '';
          };
        }
      );
      devShells = forEachSupportedSystem (
        { pkgs }: {
          default = pkgs.mkShell {
            packages = [
              (tex pkgs)
            ];

          };
        }
      );
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixfmt-tree);
    };
}
