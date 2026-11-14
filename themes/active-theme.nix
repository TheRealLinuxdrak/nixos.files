rec {
  path = ./gruvbox-material-dark-hard/theme.yaml;
  name = builtins.baseNameOf (builtins.dirOf path);

  isSpecialKde = builtins.elem name [ "tokyo-night" "nord" ];
  isSpecialBrave = builtins.elem name [ "tokyo-night" ];
}
