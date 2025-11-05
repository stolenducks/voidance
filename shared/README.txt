====================================
Voidance Shared Folder
====================================

This folder is shared between your Mac and the QEMU VM.

INSIDE THE VM:
--------------

1. Mount the shared folder:
   mkdir -p /mnt
   mount -t 9p -o trans=virtio shared /mnt

2. Access files:
   cd /mnt
   ls -la

3. Run the install script:
   bash /mnt/auto-install.sh

FILES AVAILABLE:
----------------
- auto-install.sh : The Voidance automated installer

====================================
