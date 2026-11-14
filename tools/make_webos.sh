#!/usr/bin/env bash
# Build and package Super Mario All-Stars for LG webOS (ARMv7)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "=== Super Mario All-Stars webOS Build ==="

# Check for ROM
if [ ! -f "rom/smas.sfc" ]; then
    echo "Error: ROM file not found at rom/smas.sfc"
    echo "Please copy your legally obtained Super Mario All-Stars (USA) .sfc file to rom/smas.sfc"
    exit 1
fi

# Regenerate recompiler C sources if needed
if [ ! -d "src/gen" ] || [ -z "$(ls -A src/gen 2>/dev/null)" ]; then
    echo "Generating recompiled C code from ROM..."
    bash tools/regen.sh
fi

BUILD_DIR="build_webos"
STAGE_DIR="$BUILD_DIR/stage"
OUT_DIR="out"

mkdir -p "$BUILD_DIR" "$STAGE_DIR" "$OUT_DIR"

echo "Configuring CMake for webOS target..."
cmake -S . -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="cmake/webos_toolchain.cmake" \
    -DCMAKE_BUILD_TYPE=Release

echo "Building executable with ThinLTO..."
ninja -C "$BUILD_DIR" SuperMarioAllStarsRecomp

echo "Staging webOS package..."
rm -rf "$STAGE_DIR"/*
cp "$BUILD_DIR/SuperMarioAllStarsRecomp" "$STAGE_DIR/SuperMarioAllStars"
cp webos/appinfo.json "$STAGE_DIR/"
cp webos/package.properties "$STAGE_DIR/"
cp webos/config.ini "$STAGE_DIR/"
cp webos/icon.png "$STAGE_DIR/"
cp webos/largeIcon.png "$STAGE_DIR/"
cp rom/smas.sfc "$STAGE_DIR/smas.sfc"
mkdir -p "$STAGE_DIR/saves"

echo "Packaging webOS IPK..."
ares-package -o "$OUT_DIR" "$STAGE_DIR"

echo "Normalizing IPK permissions..."
python3 tools/normalize_ipk.py

echo "=== Build Complete! Package ready in $OUT_DIR/ ==="
