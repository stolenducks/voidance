#!/bin/bash
# Simple test script to verify Voidance components
# Copy this into the VM manually to test without network

echo "========================================"
echo "Voidance Component Test"
echo "========================================"

# Test package manager
echo "[TEST] Checking xbps package manager..."
xbps-query --version

# Test disk access
echo "[TEST] Checking available disks..."
lsblk

# Test network
echo "[TEST] Checking network interfaces..."
ip a

# Try to install a package
echo "[TEST] Installing test package (git)..."
xbps-install -S
xbps-install -y git

echo ""
echo "========================================"
echo "✅ Basic tests complete!"
echo "========================================"
