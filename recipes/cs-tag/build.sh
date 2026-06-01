#!/usr/bin/env bash

set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Point bindgen to Conda's libclang.so
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Clear conda's BINDGEN_EXTRA_CLANG_ARGS — the cross-compilation sysroot
# lacks standard C headers (stdint.h etc.), causing bindgen to generate
# opaque struct bindings. Unsetting lets bindgen use the default compiler
# search paths which DO have the system headers.
unset BINDGEN_EXTRA_CLANG_ARGS

# Remove upstream Cargo.lock — it was generated with hts-sys's "bindgen" feature
# enabled, which causes bindgen to generate broken opaque bindings under conda's
# cross-compilation environment. Removing it lets cargo resolve fresh with default
# features (no bindgen), so hts-sys falls back to correct pre-built bindings.
rm -f cs-tag/Cargo.lock

# build statically linked binary with Rust
cargo install --no-track --root "$PREFIX" --path cs-tag

cd cs-tag && cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
