#!/bin/bash
# GPU compatibility validation script for Sway
# Tests Intel, AMD, and NVIDIA GPU compatibility

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
log_success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓ $1${NC}"; }
log_warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}"; }
log_error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗ $1${NC}"; }

test_gpu_compatibility() {
    log "Testing GPU compatibility..."
    
    if lspci | grep -qi "Intel.*HD Graphics\|Intel.*Iris\|Intel.*UHD"; then
        log_success "Intel GPU detected - Excellent Sway compatibility"
        lsmod | grep -q "i915" && log_success "Intel driver loaded" || log_warning "Intel driver may not be loaded"
    fi
    
    if lspci | grep -qi "AMD.*Radeon\|AMD.*Ryzen"; then
        log_success "AMD GPU detected - Good Sway compatibility"
        lsmod | grep -q "amdgpu" && log_success "AMD driver loaded" || log_warning "AMD driver may not be loaded"
    fi
    
    if lspci | grep -qi "NVIDIA"; then
        log_warning "NVIDIA GPU detected - May require proprietary drivers"
        lsmod | grep -q "nvidia" && log_success "NVIDIA driver loaded" || log_warning "NVIDIA driver may not be loaded"
    fi
    
    return 0
}

main() {
    log "Starting GPU compatibility validation..."
    test_gpu_compatibility
    log_success "GPU compatibility validation completed"
}

main "$@"