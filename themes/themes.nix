{ config, pkgs, ... }:

let

  c = config.lib.stylix.colors;
  themeDir = builtins.dirOf config.stylix.base16Scheme;

  # Function to load application-specific colors (falling back to palette 'c' for missing values)
  loadColors = path: if builtins.pathExists path 
                     then c // (import path) 
                     else c;

  # Load color definitions for individual applications from their respective theme directories
  colors = {
    niri = loadColors (themeDir + "/niri/theme.nix");
    foot = loadColors (themeDir + "/foot/theme.nix");
    waybar = loadColors (themeDir + "/waybar/theme.nix");
    rofi = loadColors (themeDir + "/rofi/theme.nix");
    rmpc = loadColors (themeDir + "/rmpc/theme.nix");
    yazi = loadColors (themeDir + "/yazi/theme.nix");
    swaylock = loadColors (themeDir + "/swaylock/theme.nix");
    #program = loadColors (themeDir + "/program/theme.nix");
    btop = loadColors (themeDir + "/btop/theme.nix");
  };

  # Array of all targeted base16 placeholder tags
  tags = [ "@base00@" "@base01@" "@base02@" "@base03@" "@base04@" "@base05@" "@base06@" "@base07@" "@base08@" "@base09@" "@base0A@" "@base0B@" "@base0C@" "@base0D@" "@base0E@" "@base0F@" ];
  
  # Generator function mapping base16 colors to an array of replacement strings with a specified prefix
  genColors = prefix: cols: [
    "${prefix}${cols.base00}" "${prefix}${cols.base01}" "${prefix}${cols.base02}" "${prefix}${cols.base03}"
    "${prefix}${cols.base04}" "${prefix}${cols.base05}" "${prefix}${cols.base06}" "${prefix}${cols.base07}"
    "${prefix}${cols.base08}" "${prefix}${cols.base09}" "${prefix}${cols.base0A}" "${prefix}${cols.base0B}"
    "${prefix}${cols.base0C}" "${prefix}${cols.base0D}" "${prefix}${cols.base0E}" "${prefix}${cols.base0F}"
  ];

  # ---------------------------------------------------------
  # CORE FUNCTION FOR DIRECTORY MERGING AND THEME INJECTION
  # ---------------------------------------------------------
  mergeFiles = appName: colorPrefix: filesToColor:
    let
      defaultDir = ../config/${appName};
      themeAppDir = themeDir + "/${appName}";

      # Recursive function to traverse directories and subdirectories
      walk = currentPath: relativePath:
        let
          defPath = defaultDir + relativePath;
          thmPath = themeAppDir + relativePath;

          defFiles = if builtins.pathExists defPath then builtins.readDir defPath else {};
          thmFiles = if builtins.pathExists thmPath then builtins.readDir thmPath else {};

          # Array of all unique entries across default and theme directories (theme overrides default)
          allEntries = builtins.attrNames (defFiles // thmFiles);

          processEntry = name:
            let
              relName = relativePath + "/" + name;
              isDir = (thmFiles.${name} or defFiles.${name}) == "directory";

              # Determine the file source, prioritizing the theme directory over the default directory
              actualSource = if builtins.pathExists (themeAppDir + relName)
                             then themeAppDir + relName
                             else defaultDir + relName;
            in
              if isDir then
                # Recursively process subdirectories
                walk actualSource relName

              # EXCEPTION 1: Exclude theme.nix (contains Nix color definitions only)
              else if name == "theme.nix" then
                []

              # EXCEPTION 2: Exclude auxiliary files that should not be deployed to ~/.config
              else if name == ".DS_Store" then
                []

              else
                # If the file is targeted for colorization, apply the replaceStrings substitution
                if builtins.elem name filesToColor then
                  [ {
                    name = "${appName}${relName}";
                    value = {
                      text = builtins.replaceStrings 
                        (tags ++ (if appName == "niri" then ["@wallpaper@"] else [])) 
                        ((genColors colorPrefix colors.${appName}) ++ (if appName == "niri" then ["${config.stylix.image}"] else [])) 
                        (builtins.readFile actualSource);
                    };
                  } ]
                # Otherwise, provision the file verbatim via source linking
                else
                  [ {
                    name = "${appName}${relName}";
                    value = { source = actualSource; };
                  } ];
        in
          # Flatten the results into a single list
          builtins.concatLists (map processEntry allEntries);
    in
      # Convert the list to an attribute set compatible with xdg.configFile
      builtins.listToAttrs (walk defaultDir "");

in
{
  # Consolidate and deploy all generated application configurations
  xdg.configFile = {}
    // (mergeFiles "niri" "#" [ "config.kdl" ])
    // (mergeFiles "foot" "" [ "foot.ini" ])
    // (mergeFiles "waybar" "#" [ "style.css" ])
    // (mergeFiles "rofi" "#" [ "config.rasi" ])
    // (mergeFiles "rmpc" "#" [ "theme.ron" ])
    // (mergeFiles "btop" "#" [ "theme.theme" ])
    // (mergeFiles "yazi" "#" [ "theme.toml" ])
    #// (mergeFiles "program" "#" []);
    // (mergeFiles "swaylock" "#" []);
}
