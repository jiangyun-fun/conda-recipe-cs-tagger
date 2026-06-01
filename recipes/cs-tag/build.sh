#!/usr/bin/env bash
set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Tell bindgen where to find libclang
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Remove any lock file from upstream so cargo resolves fresh
rm -f cs-tag/Cargo.lock

# Download all crates first so we can patch them before compilation
cargo fetch --path cs-tag

# rust-htslib 1.0.0 hardcodes features = ["bindgen"] on hts-sys.
# This forces bindgen to run at build time, which produces opaque
# struct bindings in conda's cross-compilation environment.
# Patch the downloaded rust-htslib Cargo.toml to remove bindgen,
# so hts-sys uses its pre-built bindings instead.
sed -i 's/features = \["bindgen"\]/features = []/' \
    "${CARGO_HOME}/registry/src/index.crates.io-"*/rust-htslib-1.0.0/Cargo.toml

cargo install --no-track --root "$PREFIX" --path cs-tag

cd cs-tag
cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
