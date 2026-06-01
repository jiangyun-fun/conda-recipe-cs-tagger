#!/usr/bin/env bash
set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Tell bindgen where to find libclang
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Remove any lock file from upstream so cargo resolves fresh
rm -f cs-tag/Cargo.lock

# Vendor all dependencies locally
cd cs-tag
mkdir -p .cargo
cargo vendor vendor/ > .cargo/config.toml

# Patch rust-htslib to remove bindgen feature from hts-sys dependency.
# rust-htslib 1.0.0 hardcodes features = ["bindgen"] on hts-sys,
# which forces runtime bindgen that produces opaque struct bindings
# in conda's cross-compilation environment.
sed -i 's/features = \["bindgen"\]/features = []/' \
    vendor/rust-htslib-*/Cargo.toml

# Verify patch
grep -A3 '\[dependencies.hts-sys\]' vendor/rust-htslib-*/Cargo.toml

# Build from vendored deps (offline mode, vendor dir specified in .cargo/config.toml)
cargo install --no-track --root "$PREFIX" --path .

cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
