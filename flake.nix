{
  description = "Bitwarden Secrets Manager SDK - Python bindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];

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

    checks = forAllSystems (system:
      let
        pkgs = pkgsFor system;
        bitwarden-sdk = self.packages.${system}.bitwarden-sdk;
        python = pkgs.python3.withPackages (ps: [ bitwarden-sdk ]);
      in
      {
        # Verify the package builds successfully
        build = bitwarden-sdk;

        # Validate the SDK can be imported and basic types are accessible
        validation = pkgs.runCommand "bitwarden-sdk-validation" {
          nativeBuildInputs = [ python ];
        } ''
          python3 -c "
from bitwarden_sdk import BitwardenClient, DeviceType, client_settings_from_dict

# Verify core types are importable
assert callable(BitwardenClient), 'BitwardenClient is not callable'
assert DeviceType.SDK is not None, 'DeviceType.SDK is not accessible'
assert callable(client_settings_from_dict), 'client_settings_from_dict is not callable'

print('All validation checks passed.')
"
          touch $out
        '';
      }
    );

    # Overlay so consumers can add this to their nixpkgs
    overlays.default = final: prev: {
      bitwarden-sdk = final.callPackage ./package.nix { };
    };
  };
}
