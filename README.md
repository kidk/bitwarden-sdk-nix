# bitwarden-sdk-nix

Nix flake for the [Bitwarden Secrets Manager SDK](https://github.com/bitwarden/sdk-sm) Python bindings (v1.0.0).

Builds the `bitwarden_sdk` Python package from source using Maturin/Rust.

## Usage

### As a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    bitwarden-sdk.url = "github:kidk/bitwarden-sdk-nix";
    bitwarden-sdk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, bitwarden-sdk, ... }: {
    # Access the package directly
    # bitwarden-sdk.packages.aarch64-darwin.default

    # Or use the overlay
    # bitwarden-sdk.overlays.default
  };
}
```

### nix-darwin example

Add it to `specialArgs` in your `flake.nix`:

```nix
darwinConfigurations."pc" = nix-darwin.lib.darwinSystem {
  specialArgs = { inherit bitwarden-sdk; };
  modules = [ ./configuration.nix ];
};
```

Then use it in a module:

```nix
{ pkgs, bitwarden-sdk, ... }: {
  environment.systemPackages = [
    bitwarden-sdk.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

### Build directly

```sh
nix build github:kidk/bitwarden-sdk-nix
```

## Supported platforms

- x86_64-darwin
- x86_64-linux
- aarch64-linux
- aarch64-darwin
      
## License

The packaging code in this repo is provided as-is. The Bitwarden SDK itself is licensed under the [Bitwarden SDK License](https://github.com/bitwarden/sdk-sm/blob/main/LICENSE).
