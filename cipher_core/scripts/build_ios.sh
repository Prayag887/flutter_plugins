#!/bin/bash

set -e

cd "$(dirname "$0")/../rust"

# iOS targets
TARGETS=("aarch64-apple-ios" "x86_64-apple-ios" "aarch64-apple-ios-sim")

# Build for each target
for target in "${TARGETS[@]}"; do
    echo "--------------------------------------------"
    echo "Building for $target with hardware acceleration..."
    echo "--------------------------------------------"

    # Reset RUSTFLAGS each loop
    unset RUSTFLAGS

    if [ "$target" == "aarch64-apple-ios" ]; then
        # ARM64 iOS (device)
        # Enable ARMv8 crypto + NEON via LLVM
        export RUSTFLAGS="-C target-cpu=generic+crypto+neon"
    elif [ "$target" == "x86_64-apple-ios" ]; then
        # x86_64 (simulator)
        # Enable Intel SHA and vectorization
        export RUSTFLAGS="-C target-feature=+sse2,+sha,+aes"
    elif [ "$target" == "aarch64-apple-ios-sim" ]; then
        # ARM64 simulator (M1/M2)
        export RUSTFLAGS="-C target-cpu=apple-m1"
    fi

    # Build with release profile
    cargo build --target $target --release
done

echo "--------------------------------------------"
echo "Creating XCFramework..."
echo "--------------------------------------------"

# Remove old XCFramework if exists
rm -rf ../ios/Rust.xcframework

xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios/release/libimage_ffi.a \
    -library target/x86_64-apple-ios/release/libimage_ffi.a \
    -library target/aarch64-apple-ios-sim/release/libimage_ffi.a \
    -output ../ios/Rust.xcframework

echo "============================================"
echo "iOS build completed successfully!"
echo "============================================"