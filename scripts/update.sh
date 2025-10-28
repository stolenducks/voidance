#!/bin/bash
# Voidance System Update Script
# Updates system packages, configs, and performs maintenance

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

info "Starting Voidance system update..."

# Sync repositories
info "Syncing package repositories..."
xbps-install -S

# Update all packages
info "Updating installed packages..."
xbps-install -u

# Remove orphaned packages
info "Removing orphaned packages..."
xbps-remove -o -y || true

# Clean package cache
info "Cleaning package cache..."
xbps-remove -O || true

# Update kernel if needed
info "Checking kernel updates..."
xbps-install -u linux

# Reconfigure any broken packages
info "Reconfiguring packages..."
xbps-reconfigure -fa

info "✓ System update complete!"
info "You may need to reboot if the kernel was updated."

