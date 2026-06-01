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

# Remove upstream Cargo.lock and patch rust-htslib to disable the "bindgen"
# feature. rust-htslib 1.0.0 hardcodes features = ["bindgen"] for hts-sys,
# which forces bindgen usage. Under conda's cross-compilation environment,
# bindgen generates opaque struct bindings. Without bindgen, hts-sys uses
# correct pre-built bindings.
rm -f cs-tag/Cargo.lock
sed -i 's/^rust-htslib = "1.0.0"/rust-htslib = { version = "1.0.0", default-features = false, features = ["bzip2", "lzma", "curl"] }/' cs-tag/Cargo.toml

# build statically linked binary with Rust
cargo install --no-track --root "$PREFIX" --path cs-tag

cd cs-tag && cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
