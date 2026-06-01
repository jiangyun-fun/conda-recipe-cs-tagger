#!/usr/bin/env bash
set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_LTO=fat

# Tell bindgen where to find libclang
export LIBCLANG_PATH="${BUILD_PREFIX}/lib"

# Vendor all dependencies locally so we can patch them
cd cs-tag
mkdir -p .cargo
cargo vendor vendor/ > .cargo/config.toml

# rust-htslib 1.0.0 hardcodes features = ["bindgen"] on hts-sys in its
# [dependencies.hts-sys] section. This forces runtime bindgen which produces
# opaque struct bindings in conda's cross-compilation environment because
# the sysroot lacks standard C headers. Patch it out so hts-sys uses its
# pre-built bindings instead.
sed -i 's/features = \["bindgen"\]/features = []/' \
    vendor/rust-htslib/Cargo.toml

# Update the checksum for the patched file so cargo doesn't reject it
PATCHED_SHA=$(sha256sum vendor/rust-htslib/Cargo.toml | cut -d' ' -f1)
sed -i "s|\"Cargo.toml\":\"[a-f0-9]*\"|\"Cargo.toml\":\"${PATCHED_SHA}\"|" \
    vendor/rust-htslib/.cargo-checksum.json

# Fix pre-built bindings type mismatches between bindgen output and
# what rust-htslib expects:
# 1. size_t should be usize (not c_ulong/u64) to match rust-htslib usage
# 2. bam1_core_t.isize should be isize_ to match rust-htslib field access
BINDINGS=vendor/hts-sys/linux_prebuilt_bindings.rs
sed -i 's/pub type size_t = ::std::os::raw::c_ulong;/pub type size_t = usize;/' "$BINDINGS"
sed -i 's/pub isize:/pub isize_:/' "$BINDINGS"
sed -i 's/stringify!(isize)/stringify!(isize_)/' "$BINDINGS"

# Build from vendored deps
cargo install --no-track --root "$PREFIX" --path .

cargo-bundle-licenses --format yaml --output "${SRC_DIR}/cs-tag/THIRDPARTY.yml"
