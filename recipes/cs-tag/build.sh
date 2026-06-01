#!/usr/bin/env bash
set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Tell bindgen where to find libclang
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Provide include paths for bindgen so it can find C headers.
# The conda sysroot lacks some headers, so we point directly at
# the prefix include dirs where zlib, bzip2, etc. are installed.
export BINDGEN_EXTRA_CLANG_ARGS="\
 -I${PREFIX}/include \
 -I${BUILD_PREFIX}/include \
 -I${BUILD_PREFIX}/${HOST}/sysroot/usr/include \
 -I${BUILD_PREFIX}/lib/gcc/${HOST}/12/include \
 -I${BUILD_PREFIX}/${HOST}/include \
 -D__GNU_LIBRARY__=6 -D__GLIBC__=2 -D__GLIBC_MINOR__=17 \
 -D_DEFAULT_SOURCE -D_POSIX_SOURCE"

cd cs-tag
cargo install --no-track --root "$PREFIX" --path .

cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
