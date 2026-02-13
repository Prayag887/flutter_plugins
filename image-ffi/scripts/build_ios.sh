#!/bin/bash

set -e

cd "$(dirname "$0")/../rust"

TARGETS=("aarch64-apple-ios" "x86_64-apple-ios" "aarch64-apple-ios-sim")

for target in "${TARGETS[@]}"; do
    echo "Building for $target..."
    cargo build --target $target --release
done

echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios/release/libimage_ffi.a \
    -library target/x86_64-apple-ios/release/libimage_ffi.a \
    -library target/aarch64-apple-ios-sim/release/libimage_ffi.a \
    -output ../ios/Rust.xcframework

echo "iOS build completed successfully"