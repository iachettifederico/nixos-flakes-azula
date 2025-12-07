{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mise
    git

    # build deps for compiling Ruby via mise and native gems
    autoconf
    bison
    gcc
    gnumake
    libyaml
    openssl
    pkg-config
    readline
    zlib
  ];

  environment.variables = {
    MISE_DATA_DIR = "/home/fedex/.local/share/mise";

    # Tell Ruby / mkmf which compiler to use
    CC = "${pkgs.gcc}/bin/gcc";
  };

  environment.interactiveShellInit = ''
    if [ -x "${pkgs.mise}/bin/mise" ]; then
      eval "$(${pkgs.mise}/bin/mise activate posix)"
    fi
  '';

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      gmp
      libxcrypt
      libyaml
      openssl
      readline
      stdenv.cc.cc  # glibc, libstdc++, etc.
      zlib
    ];
  };
}
