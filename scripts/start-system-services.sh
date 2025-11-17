#!/bin/bash

# start-system-services.sh
# Master startup script for Voidance Linux system services
# Handles service dependencies and startup order

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[STARTUP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Service definitions with dependencies
declare -A SERVICES
declare -A SERVICE_DEPS
declare -A SERVICE_DESCRIPTIONS

# Core system services (Phase 1)
SERVICES[elogind]="elogind"
SERVICE_DEPS[elogind]=""
SERVICE_DESCRIPTIONS[elogind]="Session management and login"

SERVICES[dbus]="dbus"
SERVICE_DEPS[dbus]="elogind"
SERVICE_DESCRIPTIONS[dbus]="System message bus"

# Display manager (Phase 2)
SERVICES[sddm]="sddm"
SERVICE_DEPS[sddm]="elogind dbus"
SERVICE_DESCRIPTIONS[sddm]="Graphical display manager"

# Network services (Phase 3)
SERVICES[NetworkManager]="NetworkManager"
SERVICE_DEPS[NetworkManager]="dbus"
SERVICE_DESCRIPTIONS[NetworkManager]="Network connection management"

# Audio services (Phase 4)
SERVICES[pipewire]="pipewire"
SERVICE_DEPS[pipewire]="dbus"
SERVICE_DESCRIPTIONS[pipewire]="Audio server"

SERVICES[pipewire-pulse]="pipewire-pulse"
SERVICE_DEPS[pipewire-pulse]="pipewire"
SERVICE_DESCRIPTIONS[pipewire-pulse]="PulseAudio compatibility"

SERVICES[wireplumber]="wireplumber"
SERVICE_DEPS[wireplumber]="pipewire"
SERVICE_DESCRIPTIONS[wireplumber]="Audio session manager"

# Function to check if service exists
service_exists() {
    local service="$1"
    test -x "/etc/sv/$service/run"
}

# Function to check if service is enabled
service_enabled() {
    local service="$1"
    test -L "/var/service/$service"
}

# Function to check if service is running
service_running() {
    local service="$1"
    sv status "$service" 2>/dev/null | grep -q "run:"
}

# Function to enable service
enable_service() {
    local service="$1"
    
    if ! service_enabled "$service"; then
        log "Enabling $service service..."
        ln -sf "/etc/sv/$service" "/var/service/"
        success "$service enabled"
    else
        success "$service already enabled"
    fi
}

# Function to start service
start_service() {
    local service="$1"
    
    if ! service_running "$service"; then
        log "Starting $service service..."
        if sv up "$service" >/dev/null 2>&1; then
            success "$service started"
        else
            error "$service failed to start"
            return 1
        fi
    else
        success "$service already running"
    fi
}

# Function to check service dependencies
check_dependencies() {
    local service="$1"
    local deps="${SERVICE_DEPS[$service]}"
    
    if [ -n "$deps" ]; then
        for dep in $deps; do
            if ! service_running "$dep"; then
                error "Dependency $dep not running for $service"
                return 1
            fi
        done
    fi
    return 0
}

# Function to start service with dependencies
start_service_with_deps() {
    local service="$1"
    local description="${SERVICE_DESCRIPTIONS[$service]}"
    
    log "Processing $service ($description)..."
    
    # Check if service exists
    if ! service_exists "$service"; then
        warning "$service script not found, skipping"
        return 0
    fi
    
    # Check dependencies
    if ! check_dependencies "$service"; then
        error "Dependencies not met for $service"
        return 1
    fi
    
    # Enable service
    enable_service "$service"
    
    # Start service
    start_service "$service"
}

# Function to start all services in dependency order
start_all_services() {
    local services_order=(
        "elogind"
        "dbus"
        "NetworkManager"
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
        "sddm"
    )
    
    log "Starting Voidance Linux system services..."
    echo
    
    local failed_services=()
    
    for service in "${services_order[@]}"; do
        if ! start_service_with_deps "$service"; then
            failed_services+=("$service")
        fi
        echo
    done
    
    # Summary
    if [ ${#failed_services[@]} -eq 0 ]; then
        success "All system services started successfully!"
    else
        error "Failed to start services: ${failed_services[*]}"
        return 1
    fi
}

# Function to stop all services
stop_all_services() {
    local services_order=(
        "sddm"
        "wireplumber"
        "pipewire-pulse"
        "pipewire"
        "NetworkManager"
        "dbus"
        "elogind"
    )
    
    log "Stopping Voidance Linux system services..."
    echo
    
    for service in "${services_order[@]}"; do
        if service_running "$service"; then
            log "Stopping $service..."
            if sv down "$service" >/dev/null 2>&1; then
                success "$service stopped"
            else
                warning "$service failed to stop"
            fi
        fi
    done
}

# Function to show service status
show_status() {
    local services_order=(
        "elogind"
        "dbus"
        "NetworkManager"
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
        "sddm"
    )
    
    log "Voidance Linux system services status:"
    echo "======================================"
    printf "%-15s %-10s %-10s %s\n" "SERVICE" "ENABLED" "RUNNING" "DESCRIPTION"
    printf "%-15s %-10s %-10s %s\n" "-------" "-------" "-------" "-----------"
    
    for service in "${services_order[@]}"; do
        local enabled="No"
        local running="No"
        local description="${SERVICE_DESCRIPTIONS[$service]}"
        
        if service_enabled "$service"; then
            enabled="Yes"
        fi
        
        if service_running "$service"; then
            running="Yes"
        fi
        
        printf "%-15s %-10s %-10s %s\n" "$service" "$enabled" "$running" "$description"
    done
}

# Function to validate system
validate_system() {
    log "Validating system for service startup..."
    echo
    
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
        return 1
    fi
    
    # Check if runit is available
    if ! command -v sv >/dev/null 2>&1; then
        error "runit (sv command) not found"
        return 1
    fi
    
    # Check if service directory exists
    if [ ! -d "/etc/sv" ]; then
        error "Service directory /etc/sv not found"
        return 1
    fi
    
    # Check if runit service directory exists
    if [ ! -d "/var/service" ]; then
        error "runit service directory /var/service not found"
        return 1
    fi
    
    success "System validation passed"
    return 0
}

# Main execution
case "${1:-start}" in
    "start")
        validate_system
        start_all_services
        ;;
    "stop")
        validate_system
        stop_all_services
        ;;
    "restart")
        validate_system
        stop_all_services
        echo
        start_all_services
        ;;
    "status")
        show_status
        ;;
    "enable")
        if [ -z "${2:-}" ]; then
            error "Usage: $0 enable <service>"
            exit 1
        fi
        validate_system
        enable_service "$2"
        ;;
    "disable")
        if [ -z "${2:-}" ]; then
            error "Usage: $0 disable <service>"
            exit 1
        fi
        validate_system
        if service_enabled "$2"; then
            log "Disabling $2..."
            rm -f "/var/service/$2"
            success "$2 disabled"
        else
            success "$2 already disabled"
        fi
        ;;
    "start-service")
        if [ -z "${2:-}" ]; then
            error "Usage: $0 start-service <service>"
            exit 1
        fi
        validate_system
        start_service_with_deps "$2"
        ;;
    "stop-service")
        if [ -z "${2:-}" ]; then
            error "Usage: $0 stop-service <service>"
            exit 1
        fi
        validate_system
        if service_running "$2"; then
            log "Stopping $2..."
            sv down "$2"
            success "$2 stopped"
        else
            success "$2 already stopped"
        fi
        ;;
    *)
        echo "Voidance Linux System Services Manager"
        echo "Usage: $0 {start|stop|restart|status|enable|disable|start-service|stop-service} [service]"
        echo
        echo "Commands:"
        echo "  start           Start all system services"
        echo "  stop            Stop all system services"
        echo "  restart         Restart all system services"
        echo "  status          Show service status"
        echo "  enable <svc>    Enable a service"
        echo "  disable <svc>   Disable a service"
        echo "  start-service <svc>  Start a specific service with dependencies"
        echo "  stop-service <svc>   Stop a specific service"
        echo
        echo "Available services: elogind, dbus, NetworkManager, pipewire, pipewire-pulse, wireplumber, sddm"
        exit 1
        ;;
esac