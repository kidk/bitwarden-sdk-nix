{
  description = "Bitwarden Secrets Manager SDK - Python bindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    # Add more systems here if needed (e.g. "x86_64-darwin", "x86_64-linux")
    supportedSystems = [ "aarch64-darwin" ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = pkgsFor system;
      in
      {
        bitwarden-sdk = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.bitwarden-sdk;
      }
    );

    # Overlay so consumers can add this to their nixpkgs
    overlays.default = final: prev: {
      bitwarden-sdk = final.callPackage ./package.nix { };
    };
  };
}
