#!/bin/bash
# Voidance Automated Installer
# Installs Void Linux + Voidance in one command
# Usage: bash auto-install.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ASCII Art
cat << 'EOF'
██╗   ██╗ ██████╗ ██╗██████╗  █████╗ ███╗   ██╗ ██████╗███████╗
██║   ██║██╔═══██╗██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝
██║   ██║██║   ██║██║██║  ██║███████║██╔██╗ ██║██║     █████╗  
╚██╗ ██╔╝██║   ██║██║██║  ██║██╔══██║██║╚██╗██║██║     ██╔══╝  
 ╚████╔╝ ╚██████╔╝██║██████╔╝██║  ██║██║ ╚████║╚██████╗███████╗
  ╚═══╝   ╚═════╝ ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
                                                                 
         Automated Installer - Zero Configuration Required
EOF

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Welcome to Voidance Automated Installer${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root: sudo bash auto-install.sh"
fi

# Check if running from live ISO
if [ ! -f /etc/voidlinux-live ]; then
    warning "Not detected as Void Linux live environment"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo ""
info "This script will:"
echo "  1. Auto-partition your disk"
echo "  2. Install Void Linux base system"
echo "  3. Transform it into Voidance"
echo "  4. Configure Hyprland auto-start"
echo ""
warning "⚠️  ALL DATA ON THE TARGET DISK WILL BE ERASED!"
echo ""

# Detect available disks
info "Detecting disks..."
lsblk -d -n -o NAME,SIZE,TYPE | grep disk

echo ""
read -p "Enter target disk (e.g., sda, nvme0n1, vda): " DISK

if [ -z "$DISK" ]; then
    error "No disk specified"
fi

DISK_PATH="/dev/$DISK"

if [ ! -b "$DISK_PATH" ]; then
    error "Disk $DISK_PATH not found"
fi

echo ""
warning "You selected: $DISK_PATH"
lsblk "$DISK_PATH"
echo ""
read -p "This will ERASE ALL DATA on $DISK_PATH. Continue? (type 'YES'): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    info "Installation cancelled"
    exit 0
fi

# Get user details
echo ""
info "User Configuration"
read -p "Username: " USERNAME
if [ -z "$USERNAME" ]; then
    error "Username cannot be empty"
fi

read -sp "Password: " PASSWORD
echo
read -sp "Confirm password: " PASSWORD2
echo

if [ "$PASSWORD" != "$PASSWORD2" ]; then
    error "Passwords do not match"
fi

read -p "Hostname (default: voidance): " HOSTNAME
HOSTNAME=${HOSTNAME:-voidance}

# Timezone
read -p "Timezone (default: America/New_York): " TIMEZONE
TIMEZONE=${TIMEZONE:-America/New_York}

# Locale
read -p "Locale (default: en_US.UTF-8): " LOCALE
LOCALE=${LOCALE:-en_US.UTF-8}

echo ""
info "Installation Summary:"
echo "  Disk: $DISK_PATH"
echo "  Username: $USERNAME"
echo "  Hostname: $HOSTNAME"
echo "  Timezone: $TIMEZONE"
echo "  Locale: $LOCALE"
echo ""
read -p "Proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

echo ""
info "Starting installation..."

# ============================================
# STEP 1: Partition Disk
# ============================================
info "Partitioning disk..."

# Wipe disk
wipefs -af "$DISK_PATH" || true
sgdisk -Z "$DISK_PATH" || true

# Create GPT partition table
sgdisk -o "$DISK_PATH"

# Create EFI partition (512MB)
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "$DISK_PATH"

# Create root partition (rest of disk)
sgdisk -n 2:0:0 -t 2:8300 -c 2:"ROOT" "$DISK_PATH"

# Reload partition table
partprobe "$DISK_PATH" || sleep 2

# Determine partition names
if [[ "$DISK" == nvme* ]]; then
    PART1="${DISK_PATH}p1"
    PART2="${DISK_PATH}p2"
else
    PART1="${DISK_PATH}1"
    PART2="${DISK_PATH}2"
fi

success "Disk partitioned"

# ============================================
# STEP 2: Format Partitions
# ============================================
info "Formatting partitions..."

mkfs.vfat -F32 "$PART1"
mkfs.ext4 -F "$PART2"

success "Partitions formatted"

# ============================================
# STEP 3: Mount Partitions
# ============================================
info "Mounting partitions..."

mount "$PART2" /mnt
mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi

success "Partitions mounted"

# ============================================
# STEP 4: Install Base System
# ============================================
info "Installing Void Linux base system..."
info "This may take 5-10 minutes..."

XBPS_ARCH=x86_64 xbps-install -Sy -R https://repo-fastly.voidlinux.org/current -r /mnt \
    base-system \
    grub-x86_64-efi \
    efibootmgr \
    linux \
    linux-firmware \
    intel-ucode \
    amd-ucode \
    NetworkManager \
    dhcpcd \
    curl \
    wget \
    git \
    sudo

success "Base system installed"

# ============================================
# STEP 5: Configure System
# ============================================
info "Configuring system..."

# Set hostname
echo "$HOSTNAME" > /mnt/etc/hostname

# Set timezone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime

# Set locale
echo "$LOCALE UTF-8" > /mnt/etc/default/libc-locales
chroot /mnt xbps-reconfigure -f glibc-locales

# Configure fstab
cat > /mnt/etc/fstab << EOF
# <device>    <mount>        <type>  <options>  <dump> <pass>
$PART2        /              ext4    defaults   0      1
$PART1        /boot/efi      vfat    defaults   0      2
EOF

# Create user
chroot /mnt useradd -m -G wheel,audio,video,input "$USERNAME"
echo "$USERNAME:$PASSWORD" | chroot /mnt chpasswd

# Enable sudo for wheel group
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers

# Enable services
chroot /mnt ln -sf /etc/sv/NetworkManager /var/service/
chroot /mnt ln -sf /etc/sv/dhcpcd /var/service/

success "System configured"

# ============================================
# STEP 6: Install Bootloader
# ============================================
info "Installing GRUB bootloader..."

chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=void --recheck
chroot /mnt xbps-reconfigure -f linux

success "Bootloader installed"

# ============================================
# STEP 7: Install Voidance Packages
# ============================================
info "Installing Voidance packages..."
warning "This will take 10-20 minutes..."

# Copy package list to system
curl -L -o /mnt/tmp/voidance-packages.txt \
    https://raw.githubusercontent.com/dolandstutts/voidance/main/packages/packages.txt || \
    error "Failed to download package list"

# Install packages
chroot /mnt /bin/bash -c '
    grep -v "^#" /tmp/voidance-packages.txt | grep -v "^$" | \
    xargs xbps-install -Sy
' || warning "Some packages may have failed to install"

success "Voidance packages installed"

# ============================================
# STEP 8: Configure Voidance
# ============================================
info "Configuring Voidance..."

# Download and run transform script as user
chroot /mnt su - "$USERNAME" -c "
    curl -L -o /tmp/transform.sh \
        https://raw.githubusercontent.com/dolandstutts/voidance/main/scripts/transform.sh
    chmod +x /tmp/transform.sh
    /tmp/transform.sh --headless
" || warning "Transform script had issues"

success "Voidance configured"

# ============================================
# STEP 9: Finalize
# ============================================
info "Finalizing installation..."

umount -R /mnt

success "Installation complete!"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Voidance has been installed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
info "Next steps:"
echo "  1. Reboot your system"
echo "  2. Remove installation media"
echo "  3. Login with your credentials"
echo "  4. Hyprland will start automatically"
echo ""
info "Keyboard shortcuts:"
echo "  Super + Return → Terminal"
echo "  Super + D → App launcher"
echo "  Super + Q → Close window"
echo ""
read -p "Reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi
