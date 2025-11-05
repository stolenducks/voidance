#!/bin/bash
# Quick test with a minimal Void Linux ISO
# This downloads the official ISO to test your setup

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ISO="$PROJECT_ROOT/void-test.iso"

# Download official Void Linux ISO for testing
if [[ ! -f "$TEST_ISO" ]] || [[ $(stat -f%z "$TEST_ISO" 2>/dev/null || echo 0) -lt 100000 ]]; then
    info "Downloading official Void Linux ISO for testing (~450MB)..."
    rm -f "$TEST_ISO"
    curl -L -o "$TEST_ISO" \
        "https://mirrors.servercentral.com/voidlinux/live/current/void-live-x86_64-20240314-base.iso" || \
    curl -L -o "$TEST_ISO" \
        "https://repo-default.voidlinux.org/live/current/void-live-x86_64-20240314-base.iso"
    info "Downloaded test ISO"
else
    info "Test ISO already exists"
fi

info "Testing with QEMU (this will open a window)..."
qemu-system-x86_64 \
    -boot d \
    -cdrom "$TEST_ISO" \
    -m 2048 \
    -smp 2 \
    -display cocoa

info "Test complete!"
