#!/bin/bash

# system-status-monitor.sh
# System status monitoring script for Voidance Linux
# Monitors all system services and provides health information

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[MONITOR]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Service definitions
declare -A SERVICE_DESCRIPTIONS
SERVICE_DESCRIPTIONS[elogind]="Session management"
SERVICE_DESCRIPTIONS[dbus]="System message bus"
SERVICE_DESCRIPTIONS[sddm]="Display manager"
SERVICE_DESCRIPTIONS[NetworkManager]="Network management"
SERVICE_DESCRIPTIONS[pipewire]="Audio server"
SERVICE_DESCRIPTIONS[pipewire-pulse]="PulseAudio compatibility"
SERVICE_DESCRIPTIONS[wireplumber]="Audio session manager"

# Function to check if service exists
service_exists() {
    test -x "/etc/sv/$1/run"
}

# Function to check if service is enabled
service_enabled() {
    test -L "/var/service/$1"
}

# Function to check if service is running
service_running() {
    sv status "$1" 2>/dev/null | grep -q "run:"
}

# Function to get service uptime
service_uptime() {
    local service="$1"
    if service_running "$service"; then
        # Get service PID
        local pid=$(sv status "$service" 2>/dev/null | grep "run:" | sed 's/.*pid //')
        if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
            # Get process start time
            local start_time=$(stat -c %Y "/proc/$pid" 2>/dev/null || echo "0")
            local current_time=$(date +%s)
            local uptime=$((current_time - start_time))
            
            # Format uptime
            if [ $uptime -lt 60 ]; then
                echo "${uptime}s"
            elif [ $uptime -lt 3600 ]; then
                echo "$((uptime / 60))m"
            elif [ $uptime -lt 86400 ]; then
                echo "$((uptime / 3600))h"
            else
                echo "$((uptime / 86400))d"
            fi
        else
            echo "unknown"
        fi
    else
        echo "stopped"
    fi
}

# Function to get service memory usage
service_memory() {
    local service="$1"
    if service_running "$service"; then
        local pid=$(sv status "$service" 2>/dev/null | grep "run:" | sed 's/.*pid //')
        if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
            local memory=$(awk '/VmRSS/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo "0")
            if [ "$memory" -gt 0 ]; then
                echo "$((memory / 1024))MB"
            else
                echo "0MB"
            fi
        else
            echo "unknown"
        fi
    else
        echo "0MB"
    fi
}

# Function to check system resources
check_system_resources() {
    log "System Resources:"
    echo "================"
    
    # CPU usage
    if command -v top >/dev/null 2>&1; then
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' 2>/dev/null || echo "unknown")
        info "CPU Usage: ${cpu_usage}%"
    fi
    
    # Memory usage
    if [ -f /proc/meminfo ]; then
        local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        local mem_used=$((mem_total - mem_available))
        local mem_percent=$((mem_used * 100 / mem_total))
        
        if [ $mem_percent -lt 50 ]; then
            success "Memory: ${mem_percent}% (${mem_used}KB/${mem_total}KB)"
        elif [ $mem_percent -lt 80 ]; then
            warning "Memory: ${mem_percent}% (${mem_used}KB/${mem_total}KB)"
        else
            error "Memory: ${mem_percent}% (${mem_used}KB/${mem_total}KB)"
        fi
    fi
    
    # Disk usage
    if command -v df >/dev/null 2>&1; then
        local disk_usage=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "unknown")
        if [ -n "$disk_usage" ] && [ "$disk_usage" != "unknown" ]; then
            if [ "$disk_usage" -lt 80 ]; then
                success "Disk Usage: ${disk_usage}%"
            elif [ "$disk_usage" -lt 90 ]; then
                warning "Disk Usage: ${disk_usage}%"
            else
                error "Disk Usage: ${disk_usage}%"
            fi
        fi
    fi
    
    # Load average
    if [ -f /proc/loadavg ]; then
        local load_avg=$(awk '{print $1}' /proc/loadavg)
        info "Load Average: $load_avg"
    fi
    
    echo
}

# Function to check service health
check_service_health() {
    local services=("elogind" "dbus" "NetworkManager" "pipewire" "pipewire-pulse" "wireplumber" "sddm")
    
    log "Service Health:"
    echo "=============="
    printf "%-15s %-10s %-10s %-10s %-10s %s\n" "SERVICE" "ENABLED" "RUNNING" "UPTIME" "MEMORY" "DESCRIPTION"
    printf "%-15s %-10s %-10s %-10s %-10s %s\n" "-------" "-------" "-------" "-------" "-------" "-----------"
    
    local total_services=0
    local running_services=0
    local enabled_services=0
    
    for service in "${services[@]}"; do
        local enabled="No"
        local running="No"
        local uptime="N/A"
        local memory="N/A"
        local description="${SERVICE_DESCRIPTIONS[$service]}"
        
        ((total_services++))
        
        if service_enabled "$service"; then
            enabled="Yes"
            ((enabled_services++))
        fi
        
        if service_running "$service"; then
            running="Yes"
            ((running_services++))
            uptime=$(service_uptime "$service")
            memory=$(service_memory "$service")
        fi
        
        printf "%-15s %-10s %-10s %-10s %-10s %s\n" "$service" "$enabled" "$running" "$uptime" "$memory" "$description"
    done
    
    echo
    info "Service Summary: $running_services/$total_services running, $enabled_services/$total_services enabled"
    
    # Overall health assessment
    if [ $running_services -eq $total_services ]; then
        success "All services are running! ✓"
    elif [ $running_services -gt $((total_services / 2)) ]; then
        warning "Most services are running"
    else
        error "Many services are not running"
    fi
    
    echo
}

# Function to check network status
check_network_status() {
    log "Network Status:"
    echo "=============="
    
    if service_running NetworkManager; then
        success "NetworkManager is running"
        
        # Get network devices
        if command -v nmcli >/dev/null 2>&1; then
            echo "Network Devices:"
            nmcli device status 2>/dev/null | head -10 || echo "  Unable to get device status"
            
            # Get connection status
            echo
            echo "Active Connections:"
            nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | head -5 || echo "  Unable to get connection status"
        fi
        
        # Test internet connectivity
        if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
            success "Internet connectivity: OK"
        else
            warning "Internet connectivity: Failed"
        fi
    else
        error "NetworkManager is not running"
    fi
    
    echo
}

# Function to check audio status
check_audio_status() {
    log "Audio Status:"
    echo "============"
    
    if service_running pipewire && service_running wireplumber; then
        success "Audio services are running"
        
        # Get audio devices
        if command -v wpctl >/dev/null 2>&1; then
            echo "Audio Sinks:"
            wpctl sinks 2>/dev/null | head -5 || echo "  Unable to get sink list"
            
            echo
            echo "Audio Sources:"
            wpctl sources 2>/dev/null | head -5 || echo "  Unable to get source list"
        fi
    else
        error "Audio services are not running"
        if ! service_running pipewire; then
            error "  pipewire is not running"
        fi
        if ! service_running wireplumber; then
            error "  wireplumber is not running"
        fi
    fi
    
    echo
}

# Function to check display manager status
check_display_status() {
    log "Display Status:"
    echo "=============="
    
    if service_running sddm; then
        success "SDDM is running"
        
        # Check if display is active
        if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
            success "Display session is active"
            if [ -n "${WAYLAND_DISPLAY:-}" ]; then
                info "Wayland display: $WAYLAND_DISPLAY"
            else
                info "X11 display: $DISPLAY"
            fi
        else
            warning "No active display session found"
        fi
    else
        error "SDDM is not running"
    fi
    
    echo
}

# Function to check session management
check_session_status() {
    log "Session Status:"
    echo "=============="
    
    if service_running elogind; then
        success "elogind is running"
        
        # Check session info
        if command -v loginctl >/dev/null 2>&1; then
            echo "Active Sessions:"
            loginctl list-sessions 2>/dev/null | head -5 || echo "  Unable to get session list"
        fi
        
        # Check XDG runtime directory
        if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
            success "XDG runtime directory: $XDG_RUNTIME_DIR"
        else
            warning "XDG runtime directory not set or missing"
        fi
    else
        error "elogind is not running"
    fi
    
    echo
}

# Function to show recent logs
show_recent_logs() {
    log "Recent Service Logs:"
    echo "===================="
    
    local services=("elogind" "dbus" "NetworkManager" "pipewire" "wireplumber" "sddm")
    
    for service in "${services[@]}"; do
        if service_running "$service"; then
            echo "=== $service ==="
            # Show last few lines of service log if available
            if [ -f "/var/log/$service.log" ]; then
                tail -3 "/var/log/$service.log" 2>/dev/null || echo "  No logs available"
            elif [ -f "/var/log/sv/$service/current" ]; then
                tail -3 "/var/log/sv/$service/current" 2>/dev/null || echo "  No logs available"
            else
                echo "  No log file found"
            fi
            echo
        fi
    done
}

# Function to generate health report
generate_health_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="/tmp/voidance-health-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log "Generating health report: $report_file"
    
    {
        echo "Voidance Linux System Health Report"
        echo "Generated: $timestamp"
        echo "===================================="
        echo
        
        check_system_resources
        check_service_health
        check_network_status
        check_audio_status
        check_display_status
        check_session_status
        
    } > "$report_file"
    
    success "Health report saved to: $report_file"
}

# Main execution
case "${1:-status}" in
    "status")
        echo "Voidance Linux System Status Monitor"
        echo "===================================="
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        
        check_system_resources
        check_service_health
        check_network_status
        check_audio_status
        check_display_status
        check_session_status
        ;;
    "services")
        check_service_health
        ;;
    "resources")
        check_system_resources
        ;;
    "network")
        check_network_status
        ;;
    "audio")
        check_audio_status
        ;;
    "display")
        check_display_status
        ;;
    "session")
        check_session_status
        ;;
    "logs")
        show_recent_logs
        ;;
    "report")
        generate_health_report
        ;;
    "watch")
        log "Watching system status (Ctrl+C to stop)..."
        while true; do
            clear
            echo "Voidance Linux System Status Monitor - $(date '+%Y-%m-%d %H:%M:%S')"
            echo "=========================================================="
            echo
            check_system_resources
            check_service_health
            sleep 5
        done
        ;;
    *)
        echo "Voidance Linux System Status Monitor"
        echo "Usage: $0 {status|services|resources|network|audio|display|session|logs|report|watch}"
        echo
        echo "Commands:"
        echo "  status    - Show complete system status (default)"
        echo "  services  - Show service health only"
        echo "  resources - Show system resources only"
        echo "  network   - Show network status only"
        echo "  audio     - Show audio status only"
        echo "  display   - Show display status only"
        echo "  session   - Show session status only"
        echo "  logs      - Show recent service logs"
        echo "  report    - Generate health report file"
        echo "  watch     - Continuously monitor system status"
        exit 1
        ;;
esac