{
  description = "EunoiaCody's Multi-platform Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      # 变量提取
      nodename = "EunoiadeMac-mini";
    in
    {
      # macOS 配置入口
      darwinConfigurations."${nodename}" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/mac-mini/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.eunoiacody = import ./modules/home.nix;
          }
        ];
      };

      # 将来如果你有了 NixOS，只需在这里添加一行 nixosConfigurations
      # nixosConfigurations.my-pc = nixpkgs.lib.nixosSystem { ... };
    };
}
