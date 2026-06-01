#!/usr/bin/env bash
set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Tell bindgen where to find libclang
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Remove any lock file from upstream so cargo resolves fresh
rm -f cs-tag/Cargo.lock

# Download all crates first so we can patch them before compilation
cargo fetch --manifest-path cs-tag/Cargo.toml

# rust-htslib 1.0.0 hardcodes features = ["bindgen"] on hts-sys.
# Patch the downloaded rust-htslib Cargo.toml to remove bindgen,
# so hts-sys uses its pre-built bindings instead.
# Also ensure compression features are passed through.
HTSLIB_TOML="${CARGO_HOME}/registry/src/index.crates.io-"*/rust-htslib-1.0.0/Cargo.toml
# shellcheck disable=SC2086
sed -i 's/features = \["bindgen"\]/features = []/' $HTSLIB_TOML

# Debug: verify the patch applied
# shellcheck disable=SC2086
grep -A3 '\[dependencies.hts-sys\]' $HTSLIB_TOML

# Build in offline mode to use patched registry cache
cargo install --offline --no-track --root "$PREFIX" --path cs-tag

cd cs-tag
cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
