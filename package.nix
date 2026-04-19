{ lib
, pkgs
, python3Packages
, rustPlatform
}:

python3Packages.buildPythonPackage rec {
  pname = "bitwarden-sdk";
  version = "1.0.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "bitwarden";
    repo = "sdk-sm";
    rev = "python-v1.0.0";
    hash = "sha256-DBcsHSs3duIWzjg2MKzo6POIHL4pSGWXr2/XuuBwvWU=";
  };

  propagatedBuildInputs = with python3Packages; [
    dateutils
  ];

  npmDeps = pkgs.fetchNpmDeps {
    inherit src;
    hash = "sha256-Y3pyQcnApy9w7V2BDWtibVKbVPFYw9m1Rl1uqU2lQM4=";
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "passkey-0.2.0" = "sha256-dCQUu4lWqdQ6EiNLPRVHL1dLVty4r8//ZQzV8XCBhmY=";
    };
  };

  sourceRoot = "source/languages/python";
  cargoRoot = "../..";

  postPatch = ''
    # Maturin refuses to bundle license files that live outside the Python
    # project root (languages/python/).  The bitwarden-py crate inherits
    # license-file from the workspace, which resolves to the repo-root
    # LICENSE — outside the project root.
    # Fix: copy LICENSE *into* languages/python/ (the project root) and
    # point the crate at it via a relative path from crates/bitwarden-py/.
    cp ../../LICENSE ./LICENSE
    chmod +w ../../crates/bitwarden-py
    substituteInPlace ../../crates/bitwarden-py/Cargo.toml \
      --replace-warn 'license-file.workspace = true' \
                     'license-file = "../../languages/python/LICENSE"'
  '';

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    pkgs.pkg-config

    pkgs.nodejs_20
    pkgs.jq
  ];

  buildInputs = [
    pkgs.openssl
  ];

  preBuild = ''
    export CARGO_TARGET_DIR="$TMPDIR/cargo-target"
    mkdir -p "$CARGO_TARGET_DIR"

    # Writable copy of repo root
    cp -R ../.. "$TMPDIR/repo"
    chmod -R u+w "$TMPDIR/repo"

    # Writable copy of offline npm cache
    cp -R ${npmDeps} "$TMPDIR/npm-cache"
    chmod -R u+w "$TMPDIR/npm-cache"

    (
      cd "$TMPDIR/repo"

      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"

      export npm_config_cache="$TMPDIR/npm-cache"
      export npm_config_offline="true"
      export npm_config_audit="false"
      export npm_config_fund="false"

      # Install deps into $TMPDIR/repo/node_modules (writable)
      npm ci --offline --no-audit --fund=false

      # Equivalent of the "schemas" script but without executing .bin shims.
      # 1) delete support/schemas using rimraf's JS entry via node
      RIMRAF_MAIN="$(node -e 'console.log(require.resolve("rimraf"))')"
      node "$RIMRAF_MAIN" ./support/schemas

      # 2) run the Rust generator
      cargo run --bin sdk-schemas --all-features

      # 3) run the TS generator script with ts-node, but call it via node too.
      TS_NODE_MAIN="$(node -e 'console.log(require.resolve("ts-node/dist/bin.js"))')"
      node "$TS_NODE_MAIN" ./support/scripts/schemas.ts
    )

    # Copy generated schemas.py into the actual build tree
    cp "$TMPDIR/repo/languages/python/bitwarden_sdk/schemas.py" \
       ./bitwarden_sdk/schemas.py
  '';

  maturinFlags = [
    "--release"
    "--locked"
  ];

  pythonImportsCheck = [ "bitwarden_sdk" ];

  meta = with lib; {
    description = "Python bindings for the Bitwarden Secrets Manager SDK";
    homepage = "https://github.com/bitwarden/sdk-sm";
    platforms = platforms.unix;
    license = licenses.unfreeRedistributable;
  };
}
