{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-ruby, emacs-overlay }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ emacs-overlay.overlays.default ];
      };

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
      nixosConfigurations.toph = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          ruby-packages = nixpkgs-ruby.packages.${system};
          inherit emacs-with-grammars;
        };

        modules = [
          ./configuration.nix
          ./modules/ruby.nix
          ./modules/npm.nix
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
          ];

          # Configure gem installation to use a writable directory per Ruby version
          shellHook = ''
          export GEM_HOME="$HOME/.local/share/gem/${name}"
          export GEM_PATH="$GEM_HOME"
          export PATH="$GEM_HOME/bin:$PATH"

          mkdir -p "$GEM_HOME"
        '';
        }
      ) nixpkgs-ruby.packages.${system};
    };
}
