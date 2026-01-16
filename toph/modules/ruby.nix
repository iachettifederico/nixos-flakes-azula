{ config, pkgs, lib, ruby-packages, ... }:

{
  # Install direnv and nix-direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Install bundix and default Ruby globally
  environment.systemPackages = with pkgs; [
    bundix
    direnv
    ruby-packages."ruby-4"  # Latest Ruby 4.x as system default
  ];

  # Configure zsh to add gem bin directory to PATH
  programs.zsh.interactiveShellInit = ''
    # Add Ruby gem binaries to PATH for system-installed gems
    export GEM_HOME="$HOME/.local/share/gem/ruby/4.0.0"
    export PATH="$GEM_HOME/bin:$PATH"
  '';

  # Make Ruby packages available via overlay so direnv can find them
  nixpkgs.overlays = [
    (final: prev: ruby-packages)
  ];
}
