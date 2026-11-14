{ config, pkgs, unstable, ... }:

let
  theme = import ./themes/active-theme.nix;
  activeTheme = theme.path;
  themeName = theme.name;
  isSpecialKde = theme.isSpecialKde;

  dotfiles = "${config.home.homeDirectory}/nixos.files/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    #program = "program";
    swayimg = "swayimg";
  };
in

{ 
  programs.home-manager.enable = true;
  home.stateVersion = "26.05";
  home.username = "linuxdrak";  
  home.homeDirectory = "/home/linuxdrak";  


  home.packages = with pkgs; [
    foot
    rofi
    waybar
    swaybg
    swaylock-effects
    yazi
    pamixer
    calcurse      
    psmisc
    fastfetch
    pulsemixer
    bluetuith
    btop
    xwayland-satellite
    libreoffice-fresh
    pkgs.kdePackages.okular
    hyprpicker
    wl-clipboard
    pass
    wtype
    jq
    mpv          
    swayimg
    unzip
    zip
    p7zip
    ffmpeg
    yt-dlp
    dust
    ripgrep
    unimatrix
    asciiquarium-transparent
    #mapscii
    rmpc
    mpc
    hexchat
    nvd
    exiftool
    mat2
    gocryptfs
    pastel
    grim
    slurp
    tesseract
    #sherlock
    unstable.brave
    unstable.localsend
    unstable.fetch
    #unstable.proton-vpn
    #unstable.simplex-chat-desktop
    #unstable.briar-desktop
    #unstable.cwtch-ui
    #unstable.tor-browser
    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        unstable.nix-search-tv
      ];
      text = builtins.readFile "${unstable.nix-search-tv.src}/nixpkgs.sh";
    })

    (pkgs.writeShellScriptBin "nmtui-run" ''
      export NEWT_COLORS='root=default,default;window=default,default;border=blue,default;title=blue,default;label=default,default;textbox=default,default;listbox=default,default;actlistbox=default,default;sellistbox=black,blue;actsellistbox=black,blue;button=default,default;actbutton=black,blue;compactbutton=default,default'
      nmtui "$@"
    '')

    (writeShellScriptBin "colors" ''
      echo "$*" | grep -oE '#?[0-9a-fA-F]{6}' | xargs -r pastel format hex
    '')

     (writeShellScriptBin "ocr" ''
      AREA=$(slurp) || exit 1
      grim -g "$AREA" - | tesseract -l ces+eng stdin stdout | wl-copy
    '')

    (writeShellScriptBin "cava" ''
    printf "\033[?1049h"
    trap 'printf "\033[?1049l\033[?25h\033[0m"' EXIT HUP INT TERM
    ${pkgs.cava.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i 's/system("clear");//g' output/terminal_ncurses.c output/terminal_noncurses.c || true
      sed -i 's/\\033\[c/\\033[0m/g; s/\\033c/\\033[0m/g' output/terminal_ncurses.c output/terminal_noncurses.c || true
      '';
    })}/bin/cava "$@"
    '')

    (writeShellScriptBin "rmpc-run" ''
    cleanup() {
      trap - EXIT HUP INT TERM
    if [ -n "$RMPC_PID" ]; then
      kill -TERM "$RMPC_PID" 2>/dev/null || true
    fi
      systemctl --user --no-block stop mpd.service
    exit 0
    }
    trap cleanup EXIT HUP INT TERM
    systemctl --user start mpd.service
    ${pkgs.rmpc}/bin/rmpc "$@" &
    RMPC_PID=$!
    wait "$RMPC_PID"
    '')

    (writeShellScriptBin "rofi-passmenu" ''
    PREFIX="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
    if [ ! -d "$PREFIX" ]; then
        rofi -e "Passwords were not found in $PREFIX"
        exit 1
    fi
    cd "$PREFIX" || exit
    ITEM=$(find . -type f -name "*.gpg" | sed 's|^\./||; s|\.gpg$||' | sort | rofi -dmenu -i -p "pass")
    [ -z "$ITEM" ] && exit 0
    CONTENT=$(pass show "$ITEM")
    PASSWORD=$(echo "$CONTENT" | head -n 1)
    USERNAME=$(echo "$CONTENT" | grep -iE '^(login|user):' | sed -E 's/^(login|user):[ \t]*//i')
    sleep 0.5
    if [ -n "$USERNAME" ]; then
        wtype "$USERNAME"
        wtype -k tab
        wtype "$PASSWORD"
    else
        wtype "$PASSWORD"
    fi
    '')

    (pkgs.writeShellApplication {
      name = "collect-garbage";
      text = ''
          echo "=== Current System Generations ==="
          sudo nix-env -p /nix/var/nix/profiles/system --list-generations
          echo ""
          echo "Specify the generations you wish to delete:"
          echo "  - Enter a range (e.g., '{2..40}')"
          echo "  - Enter specific numbers (e.g., '10 11 12')"
          echo "  - Enter 'old' (deletes all except the current generation)"
          echo "  - Or press Enter to skip deletion"
        read -r -p "> " gens
        if [ -n "$gens" ]; then
          echo "Deleting selected generations: $gens..."
          sudo bash -c "nix-env -p /nix/var/nix/profiles/system --delete-generations $gens"
          echo "Updating the boot menu to remove deleted generations..."
          sudo /run/current-system/bin/switch-to-configuration boot
        else
          echo "Skipping deletion of specific generations."
        fi
          echo ""
          echo "=== Initiating System Cleanup ==="
          echo "Step 1/5: Removing orphaned system packages..."
          sudo nix-collect-garbage
          echo "Step 2/5: Removing orphaned user packages..."
          nix-collect-garbage
          echo "Step 3/5: Optimizing the Nix store (deduplication in progress, please wait)..."
          sudo nix-store --optimize
          echo "Step 4/5: Vacuuming systemd journal logs (retaining the last 3 days)..."
          sudo journalctl --vacuum-time=3d
          echo "Step 5/5: Clearing temporary Nix cache..."
          rm -rf ~/.cache/nix
          echo ""
          echo "Cleanup complete. The system has been optimized successfully."
      '';
    })
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-qt; 
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/.Music";  #MusicAdressLoadd
    network.listenAddress = "127.0.0.1"; 
    extraConfig = ''
    audio_output {
       type   "pipewire"
       name   "PipeWire Output"
    }
    audio_output {
       type   "fifo"
       name   "my_fifo"
       path   "/tmp/mpd.fifo"
       format "44100:16:2"
    }
  '';
  };
  systemd.user.services.mpd.Install.WantedBy = pkgs.lib.mkForce [ ];

  services.cliphist.enable = true;

  services.udiskie.enable = true;
  systemd.user.services.udiskie.Install.WantedBy = pkgs.lib.mkForce [ ];

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = createSymlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs; 

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 22;
    gtk.enable = true;
    x11.enable = true;
  };

  stylix.targets = {
    waybar.enable = false;
    foot.enable = false;
    rofi.enable = false;
    btop.enable = false;
    yazi.enable = false;
    swaylock.enable = false;
    qt.enable = !isSpecialKde;
    kde.enable = !isSpecialKde;
  };
   
  imports = [
    ./themes/themes.nix
  ];

  home.sessionVariables = {
    SAL_USE_VCLPLUGIN = "gtk3";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "$HOME"; 
    music = "$HOME";      
    templates = "$HOME";   
    publicShare = "$HOME"; 
    desktop = "$HOME";  
    projects = "$HOME";
    videos = "$HOME";   
    pictures = "$HOME/Obrázky";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.kde.okular.desktop" ];
      "image/jpeg" = [ "swayimg.desktop" ];
      "image/png" = [ "swayimg.desktop" ];
      "image/gif" = [ "swayimg.desktop" ];
      "image/webp" = [ "swayimg.desktop" ];
      "image/svg+xml" = [ "swayimg.desktop" ];
    };
  };

  xdg.desktopEntries = {
    yazi = {
      name = "Yazi";
      exec = "footclient -a Yazi -T Yazi yazi";
      terminal = false;
      categories = [ "System" "FileTools" "FileManager" "Utility" ];
      mimeType = [ "inode/directory" ];
    };

    mpv = {
      name = "mpv";
      exec = "mpv %U";
      terminal = false;
      type = "Application";
      categories = [ "AudioVideo" "Audio" "Video" "Player" ];
      mimeType = [ "video/mp4" "video/x-matroska" "audio/mpeg" "audio/flac" ];
      noDisplay = true;
    };
    
    btop = {
      name = "Btop++";
      exec = "footclient -a Btop++ -T Btop++ btop";
      terminal = false;
      categories = [ "System" "Monitor" ];
    };

    bluetuith = {
      name = "Bluetuith";
      exec = "footclient -a Bluetuith -T Bluetuith bluetuith";
      terminal = false;
      categories = [ "Settings" "HardwareSettings" ];
    };

    pulsemixer = {
      name = "Pulsemixer";
      exec = "footclient -a Pulsemixer -T Pulsemixer pulsemixer";
      terminal = false;
      categories = [ "Audio" "AudioVideo" "Settings" ];
    };

    nmtui = {
      name = "NMtui";
      exec = "footclient -a NMtui -T NMtui nmtui-run";
      terminal = false;
      categories = [ "Settings" "Network" ];
    };

    rmpc = {
      name = "rmpc";
      exec = "footclient -a rmpc -T rmpc rmpc-run";
      terminal = false;
      categories = [ "Audio" "AudioVideo" ];
    };

    calcurse = {
      name = "Calcurse";
      exec = "footclient -a Calcurse -T Calcurse calcurse";
      terminal = false;
      categories = [ "Office" "Calendar" ];
    };

    qt5ct = {
      name = "Qt5 Settings";
      noDisplay = true; 
    };

    qt6ct = {
      name = "Qt6 Settings";
      noDisplay = true;
    };

    kvantummanager = {
      name = "Kvantum Manager";
      noDisplay = true;
    };

    #asuss
    #rog-control-center = {  
    #  name = "ROG Control Center";
    #  noDisplay = true;
    #};
  };

  programs.bash = {
    enable = true;
    shellAliases = {  
      rebuild = "git -C ~/nixos.files add . && sudo nixos-rebuild switch --flake ~/nixos.files#asus && nvd diff $(ls -d1v /nix/var/nix/profiles/system-*-link | tail -n 2)";
      update = "nix flake update --flake ~/nixos.files && git -C ~/nixos.files add . && sudo nixos-rebuild switch --flake ~/nixos.files#asus && nvd diff $(ls -d1v /nix/var/nix/profiles/system-*-link | tail -n 2)";
      update-unstable = "nix flake update unstable --flake ~/nixos.files && git -C ~/nixos.files add . && sudo nixos-rebuild switch --flake ~/nixos.files#asus && nvd diff $(ls -d1v /nix/var/nix/profiles/system-*-link | tail -n 2)";
      load-state-backup = "bash ~/nixos.files/state-backup/load-state-backup.sh";
      usb-on = "systemctl --user start udiskie.service && echo 'USB detection was turned on (to /run/media/linuxdrak/).'";
      usb-off = "sync && systemctl --user stop udiskie.service && sudo systemctl stop udisks2.service && echo 'USB detection was turned off.'";
      nmtui = "nmtui-run";
      rmpc = "echo 'bash: rmpc: příkaz nenalezen'";
      rmpc-run = "echo 'bash: rmpc-run: příkaz nenalezen'";
      weather = "bash -c 'niri msg action set-column-width 60%; sleep 0.1; tput smcup; tput civis; clear; curl -s wttr.in/Praha | grep -v Follow; while read -rsn1 k; do [[ $k == q ]] && break; done; tput cnorm; tput rmcup; niri msg action set-column-width 50%'";
      unimatrix = "PYTHONWARNINGS=ignore::SyntaxWarning unimatrix -s 95";
      aquarium = "asciiquarium -t";
      fetch = "fetch --infinite";
    };

    initExtra = ''
      fastfetch
      ytdlp() {
        if [ -z "$1" ]; then
          echo "Usage: ytdlp <URL>"
          return 1
        fi
        yt-dlp \
          --extract-audio \
          --audio-format mp3 \
          --embed-metadata \
          --embed-thumbnail \
          --convert-thumbnails jpg \
          --ppa "ThumbnailsConvertor+ffmpeg_o:-c:v mjpeg -vf crop=ih:ih" \
          -o "~/.Music/%(title)s.%(ext)s" "$1"
        }  
    '';
  };
}
