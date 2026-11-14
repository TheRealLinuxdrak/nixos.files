{ config, pkgs, ... }:

let
  theme = import ./themes/active-theme.nix;
  activeTheme = theme.path;
  themeName = theme.name;
  isSpecialBrave = theme.isSpecialBrave;
  themeDir = builtins.dirOf activeTheme;
  themeWallpaper = themeDir + "/wallpaper.jpg"; 
  defaultWallpaper = ./wallpapers/wallpaper.jpg;
in

{

  boot.loader.efi.canTouchEfiVariables = true;  
  
  #boott
  boot.loader.systemd-boot.enable = pkgs.lib.mkForce true;

  #secureboott
  #boot.lanzaboote = {  
  #  enable = true;
  #  pkiBundle = "/var/lib/sbctl";
  #};

  #tpm22
  #boot.initrd.systemd.enable = true;  
  #security.tpm2.enable = true;  
  #boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];  

  services.greetd = {
  enable = true;
  settings = {
  #autologinn
  #  initial_session = {   
  #    command = "niri-session"; 
  #    user = "linuxdrak";  
  #    };
    default_session = {
      command = "env LC_ALL=en_US.UTF-8 ${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --cmd niri-session --background doom";
      user = "greeter";
      };
    };
  };

  security.pam.services.swaylock = {};

  system.stateVersion = "26.05";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];  

  nix.settings.auto-optimise-store = true;

  services.journald.extraConfig = "SystemMaxUse=100M\nMaxRetentionSec=3day";

  programs.niri.enable = true;

  #graphicss
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  #services.xserver.videoDrivers = [ "amdgpu" ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  stylix = {
    enable = true;
    base16Scheme = activeTheme;
    image = if builtins.pathExists themeWallpaper 
            then themeWallpaper 
            else defaultWallpaper;
    icons = {
    enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };
    fonts = {
    monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font";
    };
    sizes = {
      applications = 10; 
      desktop = 10;
      popups = 10;
    };
    };
    targets = {
      console.enable = false;
      regreet.enable = false;
      qt.enable = false;
      chromium.enable = !isSpecialBrave;
    }; 
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  networking.hostName = "asus";  #PCnamee
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "cs_CZ.UTF-8";
  i18n.supportedLocales = [
    "cs_CZ.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LC_TIME = "en_US.UTF-8";       
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; 
  };
  
  #Camera+LocationOff
  services.geoclue2.enable = false;
  boot.blacklistedKernelModules = [ "uvcvideo" ];

  zramSwap.enable = true;

  services.udisks2.enable = true;

  programs.dconf.enable = true;
 
  services.power-profiles-daemon.enable = true;  

  #services.asusd.enable = true;  #asuss

  users.users.linuxdrak = {  
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    git
    sbctl
    #brightnessctl  #brightness 
  ];

  systemd.tmpfiles.rules = [
    "R /home/linuxdrak/.cache/cliphist/db - - - - -"  
    #"d /etc/asusd 0755 root root -"  #asuss?
  ];

  systemd.user.services."backup-state-files" = {
    script = ''
      mkdir -p ~/nixos.files/state-backup/brave
      mkdir -p ~/nixos.files/state-backup/okular
      mkdir -p ~/nixos.files/state-backup/libreoffice

      cp ~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks ~/.config/BraveSoftware/Brave-Browser/Default/Preferences ~/nixos.files/state-backup/brave/ 2>/dev/null || true
      cp ~/.config/okularrc ~/.config/okularpartrc ~/nixos.files/state-backup/okular/ 2>/dev/null || true
      cp ~/.config/libreoffice/4/user/registrymodifications.xcu ~/nixos.files/state-backup/libreoffice/ 2>/dev/null || true
    '';
  };
}
