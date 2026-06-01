#!/usr/bin/env bash

set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Pass Conda's C flags to bindgen
export BINDGEN_EXTRA_CLANG_ARGS="${CFLAGS} ${CPPFLAGS}"

# Point bindgen directly to Conda's libclang.so
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# build statically linked binary with Rust
cargo install --no-track --locked --root "$PREFIX" --path cs-tag

cd cs-tag && cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
