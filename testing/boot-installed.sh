#!/bin/bash
# Boot from installed Voidance system (not ISO)

DISK="void-disk.qcow2"

echo "🖥️  Booting Voidance from disk..."
echo ""
echo "🎮 VM Controls:"
echo "  Release mouse: Ctrl + Alt + G"
echo "  Fullscreen:    Cmd + F"
echo "  Quit:          Close window or Ctrl+C here"
echo ""

# Boot from hard disk (no ISO) with UEFI
qemu-system-x86_64 \
  -bios /opt/homebrew/share/qemu/edk2-x86_64-code.fd \
  -hda "$DISK" \
  -m 4096 \
  -smp 2 \
  -boot c \
  -display cocoa \
  -netdev user,id=net0 \
  -device e1000,netdev=net0 \
  -enable-kvm 2>/dev/null || qemu-system-x86_64 \
  -hda "$DISK" \
  -m 4096 \
  -smp 2 \
  -boot c \
  -display cocoa \
  -netdev user,id=net0 \
  -device e1000,netdev=net0
