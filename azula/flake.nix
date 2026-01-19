{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode/dev";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, opencode, nixpkgs-ruby, emacs-overlay }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ emacs-overlay.overlays.default ];
      };

      # Pin bun to 1.3.5 for opencode compatibility
      bun-1-3-5 = pkgs.bun.overrideAttrs (oldAttrs: rec {
        version = "1.3.5";
        src = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
          hash = "sha256-cFHYapJK7+o+C5YhO1/Y95wHk/nK5lNCM+Yn5cPbRmk=";
        };
      });

      # Custom Emacs build with tree-sitter grammars
      emacs-with-grammars = pkgs.emacsWithPackagesFromUsePackage {
        config = "";
        defaultInitFile = false;
        alwaysEnsure = true;
        package = pkgs.emacs-gtk;

        extraEmacsPackages = epkgs: with epkgs; [
          # Tree-sitter grammars
          treesit-grammars.with-all-grammars

          # Common packages
          use-package
          envrc
          yaml-mode
          nix-mode
          dockerfile-mode
        ];
      };
    in {
      nixosConfigurations.azula = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          ruby-packages = nixpkgs-ruby.packages.${system};
          inherit emacs-with-grammars;
        };

        modules = [
          ./configuration.nix
          ./modules/ruby.nix
          ./modules/npm.nix

          # Install OpenCode from the official dev branch.
          ({ pkgs, ... }: {
            environment.systemPackages = [
              (opencode.packages.${system}.default.override {
                bun = bun-1-3-5;
              })
            ];
          })
        ];
      };

      # Expose Ruby packages for direnv
      packages.${system} = nixpkgs-ruby.packages.${system} // {
        default = nixpkgs-ruby.packages.${system}."ruby-4";
      };

      # Expose devShells for each Ruby version
      devShells.${system} = builtins.mapAttrs (name: ruby:
        pkgs.mkShell {
          buildInputs = [
            ruby
            # Build dependencies for Ruby gems with native extensions
            pkgs.libyaml      # for psych gem (YAML)
            pkgs.openssl      # for SSL-related gems
            pkgs.zlib         # for compression
            pkgs.readline     # for readline support
            pkgs.pkg-config   # for finding libraries
            pkgs.gcc          # C compiler
            pkgs.gnumake      # make utility
            pkgs.libffi       # for fiddle gem (FFI)
            pkgs.gtk3         # for glimmer-dsl-libui
          ];

          # Configure gem installation to use a writable directory per Ruby version
          shellHook = ''
          export GEM_HOME="$HOME/.local/share/gem/${name}"
          export GEM_PATH="$GEM_HOME"
          export PATH="$GEM_HOME/bin:$PATH"

          # Add GTK3 and related libraries to LD_LIBRARY_PATH for glimmer-dsl-libui
          export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
                        pkgs.gtk3
                        pkgs.pango
                        pkgs.cairo
                        pkgs.gdk-pixbuf
                        pkgs.glib
                        pkgs.atk
                      ]}:$LD_LIBRARY_PATH"

          mkdir -p "$GEM_HOME"
        '';
        }
      ) nixpkgs-ruby.packages.${system};
    };
}
