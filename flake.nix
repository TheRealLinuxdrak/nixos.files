{
  description = "NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix/release-26.05";
  };

  outputs = { self, nixpkgs, unstable, home-manager, lanzaboote, stylix, ... }: 
  let
    system = "x86_64-linux";
    pkgs-unstable = import unstable { 
      inherit system;
    };

  in {
    nixosConfigurations.asus = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { unstable = pkgs-unstable; }; 
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { unstable = pkgs-unstable; };
          home-manager.users.linuxdrak = import ./home.nix;
          home-manager.backupFileExtension = "bak";
        }
        #lanzaboote.nixosModules.lanzaboote  #secureboott
        stylix.nixosModules.stylix
      ];
    };
  };
}
