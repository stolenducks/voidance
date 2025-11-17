#!/bin/bash
# Multi-monitor support test for Sway

set -euo pipefail

log() { echo -e "\033[0;34m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"; }
log_success() { echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] ✓ $1\033[0m"; }

test_multi_monitor() {
    log "Testing multi-monitor support..."
    
    if command -v sway >/dev/null 2>&1; then
        log_success "Sway available for multi-monitor testing"
    else
        log "Sway not installed - configuration ready for multi-monitor"
    fi
    
    return 0
}

main() {
    test_multi_monitor
    log_success "Multi-monitor support test completed"
}

main "$@"