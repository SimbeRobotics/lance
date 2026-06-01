#!/usr/bin/env bash
# Builds a manylinux_2_28 x86_64 wheel of pylance in a container.
# Usage: ./scripts/build-wheel-manylinux.sh
# Output: ./dist/pylance-*.whl
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$REPO_ROOT/dist"
mkdir -p "$HOME/.cache/lance-cargo/registry" "$HOME/.cache/lance-cargo/git"

docker run --rm \
    -v "$REPO_ROOT:/io" \
    -v "$HOME/.cache/lance-cargo/registry:/root/.cargo/registry" \
    -v "$HOME/.cache/lance-cargo/git:/root/.cargo/git" \
    -w /io/python \
    -e CARGO_TARGET_DIR=/io/target-manylinux \
    -e CC=clang -e CXX=clang++ \
    quay.io/pypa/manylinux_2_28_x86_64 \
    bash -c '
        set -euo pipefail
        yum install -y -q openssl-devel clang unzip curl
        curl -sL https://github.com/protocolbuffers/protobuf/releases/download/v24.4/protoc-24.4-linux-x86_64.zip -o /tmp/protoc.zip
        unzip -q /tmp/protoc.zip -d /usr/local
        curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.94.0 --profile minimal
        export PATH=/root/.cargo/bin:$PATH
        curl -sL https://github.com/PyO3/maturin/releases/download/v1.10.2/maturin-x86_64-unknown-linux-musl.tar.gz -o /tmp/maturin.tar.gz
        tar xzf /tmp/maturin.tar.gz -C /usr/local/bin maturin
        export PATH=/opt/python/cp311-cp311/bin:$PATH
        maturin build --release --manylinux 2_28 --out /io/dist
    '
