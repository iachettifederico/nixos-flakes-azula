{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-ruby }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.azula = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          ruby-packages = nixpkgs-ruby.packages.${system};
        };

        modules = [
          ./configuration.nix
          ./modules/ruby.nix
          ./modules/npm.nix
        ];
      };

      # Expose Ruby packages for direnv
      packages.${system} = nixpkgs-ruby.packages.${system} // {
        default = nixpkgs-ruby.packages.${system}."ruby-3";
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

          # Create the gem directory if it doesn't exist
          mkdir -p "$GEM_HOME"
        '';
        }
      ) nixpkgs-ruby.packages.${system};
    };
}
