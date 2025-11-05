#!/bin/bash
# Helper script to run Voidance in QEMU

ISO="${1:-void-base-live.iso}"
DISK="void-disk.qcow2"
SHARED_DIR="$(pwd)/shared"

# Create shared directory if it doesn't exist
mkdir -p "$SHARED_DIR"

echo "🖥️  Starting QEMU VM..."
echo "ISO: $ISO"

# Create virtual disk if it doesn't exist
if [ ! -f "$DISK" ]; then
    echo "📀 Creating 20GB virtual disk..."
    qemu-img create -f qcow2 "$DISK" 20G
fi

echo ""
echo "🎮 VM Controls:"
echo "  Release mouse: Ctrl + Alt + G"
echo "  Fullscreen:    Cmd + F"
echo "  Quit:          Close window or Ctrl+C here"
echo ""
echo "🔐 VM Login:"
echo "  Username: root"
echo "  Password: voidlinux"
echo ""
echo "📂 Shared Folder:"
echo "  Host: $SHARED_DIR"
echo "  VM: mount -t 9p -o trans=virtio shared /mnt"
echo ""

# Start QEMU with better networking and shared folder
qemu-system-x86_64 \
  -cdrom "$ISO" \
  -hda "$DISK" \
  -m 4096 \
  -smp 2 \
  -boot d \
  -display cocoa \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=net0 \
  -virtfs local,path="$SHARED_DIR",mount_tag=shared,security_model=passthrough,id=shared0 \
  -enable-kvm 2>/dev/null || qemu-system-x86_64 \
  -cdrom "$ISO" \
  -hda "$DISK" \
  -m 4096 \
  -smp 2 \
  -boot d \
  -display cocoa \
  -netdev user,id=net0 \
  -device e1000,netdev=net0 \
  -virtfs local,path="$SHARED_DIR",mount_tag=shared,security_model=passthrough,id=shared0
