#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/build/module-cache"
mkdir -p build/module-cache
APP="$PWD/build/MemoryUsageBar.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swift -module-cache-path "$CLANG_MODULE_CACHE_PATH" scripts/GenerateIcon.swift build/AppIcon.iconset
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
for ARCH in arm64 x86_64; do
    swiftc -swift-version 5 -O -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
        -target "$ARCH-apple-macosx13.0" -framework AppKit -framework ServiceManagement \
        Sources/Memory.swift Sources/Placement.swift Sources/main.swift -o "build/MemoryUsageBar-$ARCH"
done
lipo -create build/MemoryUsageBar-arm64 build/MemoryUsageBar-x86_64 -output "$APP/Contents/MacOS/MemoryUsageBar"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
lipo -archs "$APP/Contents/MacOS/MemoryUsageBar"
echo "Built $APP"
