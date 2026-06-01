#!/usr/bin/env bash

set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Point bindgen to Conda's libclang.so
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Only pass sysroot to bindgen — conda's full CFLAGS (with -isystem, -fdebug-prefix-map, etc.)
# interfere with hts-sys's bundled htslib header discovery by bindgen.
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=${BUILD_PREFIX}/${HOST}/sysroot"

# Remove upstream Cargo.lock — it was generated with hts-sys's "bindgen" feature
# enabled, which causes bindgen to generate broken opaque bindings under conda's
# cross-compilation environment. Removing it lets cargo resolve fresh with default
# features (no bindgen), so hts-sys falls back to correct pre-built bindings.
rm -f cs-tag/Cargo.lock

# build statically linked binary with Rust
cargo install --no-track --root "$PREFIX" --path cs-tag

cd cs-tag && cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
