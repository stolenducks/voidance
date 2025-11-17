#!/bin/bash
# Voidance Package Manifest Validation
# Comprehensive validation of the complete package manifest

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[PKG-VALIDATE]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
PACKAGE_MANIFEST="/opt/voidance-iso/config/iso/packages.txt"
REPO_CONF="/opt/voidance-iso/config/iso/repositories.conf"
VALIDATION_LOG="/opt/voidance-iso/output/logs/package-validation.log"

# Validation counters
TOTAL_PACKAGES=0
VALID_PACKAGES=0
MISSING_PACKAGES=0
CONFLICTING_PACKAGES=0
VERSION_ISSUES=0
DEPENDENCY_ISSUES=0

# Function to initialize validation
init_validation() {
    log "Initializing package manifest validation..."
    
    # Create output directory
    mkdir -p "$(dirname "$VALIDATION_LOG")"
    
    # Initialize log file
    cat > "$VALIDATION_LOG" << EOF
Voidance Package Manifest Validation Report
============================================
Date: $(date)
Package Manifest: $PACKAGE_MANIFEST
Repository Config: $REPO_CONF

EOF
    
    # Check if required files exist
    if [[ ! -f "$PACKAGE_MANIFEST" ]]; then
        error "Package manifest not found: $PACKAGE_MANIFEST"
    fi
    
    if [[ ! -f "$REPO_CONF" ]]; then
        error "Repository configuration not found: $REPO_CONF"
    fi
    
    success "Validation initialized"
}

# Function to validate package availability
validate_package_availability() {
    local package="$1"
    local package_name="${package%%[<>=!]*}"
    
    if xbps-query -R "$REPO_CONF" "$package_name" &>/dev/null; then
        ((VALID_PACKAGES++))
        log "  ✓ Available: $package_name"
        return 0
    else
        ((MISSING_PACKAGES++))
        log "  ✗ Missing: $package_name"
        echo "MISSING: $package_name" >> "$VALIDATION_LOG"
        return 1
    fi
}

# Function to validate package version constraints
validate_package_version() {
    local package="$1"
    local package_name="${package%%[<>=!]*}"
    local version_constraint="${package#$package_name}"
    
    if [[ -z "$version_constraint" ]]; then
        return 0  # No version constraint
    fi
    
    local installed_version
    installed_version=$(xbps-query -R "$REPO_CONF" "$package_name" 2>/dev/null | awk '/version/ {print $2}' || echo "")
    
    if [[ -z "$installed_version" ]]; then
        return 0  # Package not installed, will be installed
    fi
    
    # Extract required version (remove operator)
    local required_version="${version_constraint#*[<>=!]}"
    local operator="${version_constraint%$required_version}"
    
    case "$operator" in
        ">=")
            if xbps-uhelper cmpver "$installed_version" "$required_version"; then
                log "  ✓ Version OK: $package_name ($installed_version >= $required_version)"
                return 0
            else
                ((VERSION_ISSUES++))
                log "  ✗ Version issue: $package_name ($installed_version < $required_version)"
                echo "VERSION_ISSUE: $package_name (installed: $installed_version, required: $required_version)" >> "$VALIDATION_LOG"
                return 1
            fi
            ;;
        "==")
            if [[ "$installed_version" == "$required_version" ]]; then
                log "  ✓ Version OK: $package_name ($installed_version == $required_version)"
                return 0
            else
                ((VERSION_ISSUES++))
                log "  ✗ Version issue: $package_name ($installed_version != $required_version)"
                echo "VERSION_ISSUE: $package_name (installed: $installed_version, required: $required_version)" >> "$VALIDATION_LOG"
                return 1
            fi
            ;;
        *)
            warning "  Unknown version operator: $operator for $package_name"
            return 0
            ;;
    esac
}

# Function to validate package dependencies
validate_package_dependencies() {
    local package="$1"
    local package_name="${package%%[<>=!]*}"
    
    # Get package dependencies from xbps
    local deps
    deps=$(xbps-query -R "$REPO_CONF" -R "$package_name" 2>/dev/null | awk '/run_depends/ {print $2}' || echo "")
    
    if [[ -z "$deps" ]]; then
        return 0  # No dependencies
    fi
    
    local missing_deps=()
    for dep in $deps; do
        if ! xbps-query -R "$REPO_CONF" "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        ((DEPENDENCY_ISSUES++))
        log "  ✗ Missing dependencies for $package_name: ${missing_deps[*]}"
        echo "DEPENDENCY_ISSUE: $package_name (missing: ${missing_deps[*]})" >> "$VALIDATION_LOG"
        return 1
    else
        return 0
    fi
}

# Function to validate package conflicts
validate_package_conflicts() {
    local package="$1"
    local package_name="${package%%[<>=!]*}"
    
    # Get package conflicts from xbps
    local conflicts
    conflicts=$(xbps-query -R "$REPO_CONF" -R "$package_name" 2>/dev/null | awk '/conflicts/ {print $2}' || echo "")
    
    if [[ -z "$conflicts" ]]; then
        return 0  # No conflicts
    fi
    
    local conflicting_packages=()
    for conflict in $conflicts; do
        if xbps-query -R "$REPO_CONF" "$conflict" &>/dev/null; then
            conflicting_packages+=("$conflict")
        fi
    done
    
    if [[ ${#conflicting_packages[@]} -gt 0 ]]; then
        ((CONFLICTING_PACKAGES++))
        log "  ✗ Conflicts for $package_name: ${conflicting_packages[*]}"
        echo "CONFLICT: $package_name (conflicts with: ${conflicting_packages[*]})" >> "$VALIDATION_LOG"
        return 1
    else
        return 0
    fi
}

# Function to validate manifest completeness
validate_manifest_completeness() {
    log "Validating manifest completeness..."
    
    # Check for required system components
    local required_components=(
        "base-system"
        "linux"
        "linux-firmware"
        "dracut"
        "e2fsprogs"
        "NetworkManager"
        "pipewire"
        "sddm"
        "niri"
        "sway"
        "firefox"
        "ghostty"
        "thunar"
        "waybar"
        "wofi"
        "mako"
    )
    
    local missing_components=()
    for component in "${required_components[@]}"; do
        if ! grep -q "^$component" "$PACKAGE_MANIFEST"; then
            missing_components+=("$component")
        fi
    done
    
    if [[ ${#missing_components[@]} -gt 0 ]]; then
        warning "Missing required components: ${missing_components[*]}"
        echo "MISSING_COMPONENTS: ${missing_components[*]}" >> "$VALIDATION_LOG"
    else
        success "All required components present"
    fi
    
    # Check for duplicate packages
    local duplicates
    duplicates=$(sort "$PACKAGE_MANIFEST" | uniq -d | grep -v '^#' | grep -v '^$' || true)
    
    if [[ -n "$duplicates" ]]; then
        warning "Duplicate packages found:"
        echo "$duplicates" | while read -r dup; do
            log "  Duplicate: $dup"
            echo "DUPLICATE: $dup" >> "$VALIDATION_LOG"
        done
    else
        success "No duplicate packages found"
    fi
    
    # Check package count
    local package_count
    package_count=$(grep -v '^#' "$PACKAGE_MANIFEST" | grep -v '^$' | wc -l)
    log "Total packages in manifest: $package_count"
    echo "PACKAGE_COUNT: $package_count" >> "$VALIDATION_LOG"
}

# Function to validate repository connectivity
validate_repository_connectivity() {
    log "Validating repository connectivity..."
    
    while IFS= read -r repo; do
        # Skip comments and empty lines
        [[ "$repo" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$repo" ]] && continue
        
        # Test repository connectivity
        if curl -s --connect-timeout 10 "$repo" >/dev/null 2>&1; then
            log "  ✓ Repository accessible: $repo"
        else
            warning "  ✗ Repository inaccessible: $repo"
            echo "REPO_ISSUE: $repo" >> "$VALIDATION_LOG"
        fi
    done < "$REPO_CONF"
}

# Function to validate package groups coverage
validate_package_groups_coverage() {
    log "Validating package groups coverage..."
    
    # Source package groups configuration
    if [[ -f "/opt/voidance-iso/config/iso/package-groups.sh" ]]; then
        source /opt/voidance-iso/config/iso/package-groups.sh
        
        # Check if all groups are represented in the manifest
        local groups_not_covered=()
        for group in "${!PACKAGE_GROUPS[@]}"; do
            local group_packages="${PACKAGE_GROUPS[$group]}"
            local covered=true
            
            for package in $group_packages; do
                if ! grep -q "^$package" "$PACKAGE_MANIFEST"; then
                    covered=false
                    break
                fi
            done
            
            if [[ "$covered" == false ]]; then
                groups_not_covered+=("$group")
            fi
        done
        
        if [[ ${#groups_not_covered[@]} -gt 0 ]]; then
            warning "Package groups not fully covered: ${groups_not_covered[*]}"
            echo "GROUPS_NOT_COVERED: ${groups_not_covered[*]}" >> "$VALIDATION_LOG"
        else
            success "All package groups covered"
        fi
    else
        warning "Package groups configuration not found"
    fi
}

# Function to generate validation summary
generate_validation_summary() {
    log "Generating validation summary..."
    
    cat >> "$VALIDATION_LOG" << EOF

Validation Summary
=================
Total Packages: $TOTAL_PACKAGES
Valid Packages: $VALID_PACKAGES
Missing Packages: $MISSING_PACKAGES
Conflicting Packages: $CONFLICTING_PACKAGES
Version Issues: $VERSION_ISSUES
Dependency Issues: $DEPENDENCY_ISSUES

Validation Status: $([ $MISSING_PACKAGES -eq 0 ] && [ $CONFLICTING_PACKAGES -eq 0 ] && echo "PASSED" || echo "FAILED")

EOF
    
    # Print summary
    log "Validation Summary:"
    log "  Total Packages: $TOTAL_PACKAGES"
    log "  Valid Packages: $VALID_PACKAGES"
    log "  Missing Packages: $MISSING_PACKAGES"
    log "  Conflicting Packages: $CONFLICTING_PACKAGES"
    log "  Version Issues: $VERSION_ISSUES"
    log "  Dependency Issues: $DEPENDENCY_ISSUES"
    
    if [[ $MISSING_PACKAGES -eq 0 ]] && [[ $CONFLICTING_PACKAGES -eq 0 ]]; then
        success "Package manifest validation PASSED"
        return 0
    else
        error "Package manifest validation FAILED"
        return 1
    fi
}

# Function to validate all packages
validate_all_packages() {
    log "Validating all packages in manifest..."
    
    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$package" ]] && continue
        
        ((TOTAL_PACKAGES++))
        
        log "Validating package $TOTAL_PACKAGES: $package"
        
        # Validate package availability
        validate_package_availability "$package"
        
        # Validate version constraints
        validate_package_version "$package"
        
        # Validate dependencies
        validate_package_dependencies "$package"
        
        # Validate conflicts
        validate_package_conflicts "$package"
        
    done < "$PACKAGE_MANIFEST"
}

# Main validation function
main_validation() {
    init_validation
    
    log "Starting comprehensive package manifest validation..."
    
    # Validate repository connectivity
    validate_repository_connectivity
    
    # Validate manifest completeness
    validate_manifest_completeness
    
    # Validate package groups coverage
    validate_package_groups_coverage
    
    # Validate all packages
    validate_all_packages
    
    # Generate summary
    generate_validation_summary
}

# Function to fix common issues
fix_common_issues() {
    log "Attempting to fix common issues..."
    
    # Remove duplicate packages
    log "Removing duplicate packages..."
    sort "$PACKAGE_MANIFEST" | uniq > "${PACKAGE_MANIFEST}.tmp"
    mv "${PACKAGE_MANIFEST}.tmp" "$PACKAGE_MANIFEST"
    
    # Remove comments and empty lines for validation
    log "Cleaning manifest..."
    grep -v '^#' "$PACKAGE_MANIFEST" | grep -v '^$' > "${PACKAGE_MANIFEST}.clean"
    
    success "Common issues fixed"
}

# Function to generate fixed manifest
generate_fixed_manifest() {
    local output_file="$1"
    
    log "Generating fixed package manifest..."
    
    > "$output_file"
    
    # Add header
    cat >> "$output_file" << EOF
# Voidance Fixed Package Manifest
# Generated on: $(date)
# Original manifest: $PACKAGE_MANIFEST

EOF
    
    # Add valid packages only
    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$package" ]] && continue
        
        local package_name="${package%%[<>=!]*}"
        
        if xbps-query -R "$REPO_CONF" "$package_name" &>/dev/null; then
            echo "$package" >> "$output_file"
        fi
    done < "$PACKAGE_MANIFEST"
    
    success "Fixed manifest generated: $output_file"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-validate}" in
        "validate")
            main_validation
            ;;
        "fix")
            fix_common_issues
            ;;
        "generate-fixed")
            if [[ -n "${2:-}" ]]; then
                generate_fixed_manifest "$2"
            else
                error "Output file required"
            fi
            ;;
        "quick")
            init_validation
            validate_all_packages
            generate_validation_summary
            ;;
        *)
            echo "Usage: $0 {validate|fix|generate-fixed|quick} [args...]"
            echo ""
            echo "Commands:"
            echo "  validate         - Full validation of package manifest"
            echo "  fix              - Fix common issues in manifest"
            echo "  generate-fixed   - Generate fixed manifest"
            echo "  quick            - Quick validation without connectivity checks"
            exit 1
            ;;
    esac
fi