{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self
    , nixpkgs
    , ...
  }:
  let
    systems = [ "aarch64-linux" "riscv64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

    bootstrapSystem = {modules, system ? "aarch64-linux", ... }@config: nixpkgs.lib.nixosSystem (
        config
        // {
          inherit system;
          modules = modules ++ [
            self.nixosModules.default
            {
              sbc.bootstrap.initialBootstrapImage = true;
              sbc.version = "0.1";
            }
          ];
        }
      );
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      import ./pkgs { inherit pkgs; }
    );

    nixosModules = import ./modules;

    nixosConfigurations = {
      bananapi-bpir3 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.bananapi.bpir3
        ];
      };
    };
  };
}
