# sudo nixos-rebuild switch --impure --flake  "/home/fedex/nixos-flakes-azula#azula"

{ config, pkgs, emacs-with-grammars, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "azula";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/Argentina/Cordoba";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  # services.xserver.enable = true;
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.cinnamon.enable = true;

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true; # or greetd, sddm, etc.
    windowManager.i3.enable = true;
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  # 3D stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Tell X/Wayland to use NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;                # 570 series supports the open kernel module
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;      # gives you the nvidia-settings GUI
  };

  # Pin to driver 570.133.07 (this exact snippet is confirmed working on NixOS 25.05 + linux 6.14.8).
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "570.133.07";

    sha256_64bit   = "sha256-LUPmTFgb5e9VTemIixqpADfvbUX1QoTT2dztwI3E3CY=";
    openSha256     = "sha256-9l8N83Spj0MccA8+8R1uqiXBS0Ag4JrLPjrU3TaXHnM=";
    settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU=";

    usePersistenced = false;
  };

  # Configure console keymap
  console.keyMap = "us-acentos";

  fonts = {
    enableDefaultPackages = true;
    fontconfig.enable = true;

    packages = with pkgs; [
      font-awesome
      inconsolata
      jetbrains-mono
      source-code-pro
      nerd-fonts.fira-code
    ];

    # Optional but nice: default monospace fonts
    fontconfig.defaultFonts.monospace = [
      "JetBrains Mono"
      "Source Code Pro"
      "Inconsolata"
    ];
  };

  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.fedex = {
    gid = 1000;
  };

  users.users.fedex = {
    isNormalUser = true;
    description = "Federico Martín Iachetti";
    uid = 1000;
    group = "fedex";  # primary group
    extraGroups = [ "users" "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "fedex";

  programs.firefox.enable = true;
  programs.zsh.enable = true;

  programs.npm.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    arandr
    audacity
    bat
    brave
    davinci-resolve
    discord
    docker
    docker-compose
    dunst
    emacs-with-grammars
    feh
    ferdium
    ffmpeg
    firefox-devedition
    flameshot
    font-awesome
    git
    github-cli
    gnome-calculator
    gnumake
    godot
    inconsolata
    jetbrains-mono
    libnotify
    mc
    nemo
    obs-studio
    opencode
    pandoc
    pavucontrol
    ripgrep
    rofi
    silver-searcher
    slack
    source-code-pro
    tealdeer
    telegram-desktop
    terminator
    tilda
    tree
    vim
    vlc
    watchman
    xclip
    xhost
    xmodmap
    zoom-us

    # Kalkomey
    awscli2
    openvpn
    teams-for-linux
    vault

    config.hardware.nvidia.package
  ];

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;

    daemon.settings = {
      # Force sane DNS servers inside containers, often fixes build-time resolution issues.
      dns = [ "1.1.1.1" "8.8.8.8" ];

      experimental = true;
      features = {
        buildkit = true;
      };
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.ip_forward" = 1;

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  hardware.opengl = {
    enable = true;
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Enable the unfree 1Password packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "1password-gui"
    "1password"
  ];
  # Alternatively, you could also just allow all unfree packages
  # nixpkgs.config.allowUnfree = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "fedex" ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
