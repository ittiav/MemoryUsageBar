#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
swiftc -module-cache-path "$PWD/build/module-cache" Sources/Memory.swift Sources/Placement.swift Tests/main.swift -o build/MemoryUsageBarTests
build/MemoryUsageBarTests
