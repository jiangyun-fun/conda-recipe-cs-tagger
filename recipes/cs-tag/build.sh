#!/usr/bin/env bash

set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Point bindgen to Conda's libclang.so
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Only pass sysroot to bindgen — conda's full CFLAGS (with -isystem, -fdebug-prefix-map, etc.)
# interfere with hts-sys's bundled htslib header discovery by bindgen.
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=${BUILD_PREFIX}/${HOST}/sysroot"

# build statically linked binary with Rust
# Note: not using --locked because the upstream Cargo.lock enables the hts-sys
# "bindgen" feature which generates broken bindings under conda's cross-compilation
# environment. Without --locked, Cargo uses default features (no bindgen) and
# hts-sys falls back to pre-built bindings that work correctly.
cargo install --no-track --root "$PREFIX" --path cs-tag

cd cs-tag && cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
