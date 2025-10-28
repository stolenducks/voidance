#!/bin/sh
# Voidance One-Line Installer
# curl -L https://raw.githubusercontent.com/dolandstutts/voidance/main/install.sh | sh

set -e

echo "🚀 Voidance Installer"
echo "====================="
echo ""

# Check if we're on Void Linux
if [ ! -f /etc/os-release ] || ! grep -q "ID=void" /etc/os-release; then
    echo "❌ Error: This script only works on Void Linux!"
    echo "Please install Void Linux first: https://voidlinux.org"
    exit 1
fi

echo "✅ Void Linux detected"
echo ""

# Check for required tools
if ! command -v curl >/dev/null 2>&1; then
    echo "Installing curl..."
    sudo xbps-install -Sy curl
fi

# Download and run transform script
echo "📥 Downloading Voidance transformation script..."
curl -L -o /tmp/voidance-transform.sh \
    https://raw.githubusercontent.com/dolandstutts/voidance/main/scripts/transform.sh

chmod +x /tmp/voidance-transform.sh

echo ""
echo "🎨 Starting Voidance transformation..."
echo ""

exec /tmp/voidance-transform.sh "$@"
