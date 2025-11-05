#!/bin/bash
# fetch-ai-assets.sh - Download AI model and Void Linux docs for ISO
# This script runs during ISO build to embed offline assets

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[fetch-ai-assets]${NC} $*"; }
error() { echo -e "${RED}[fetch-ai-assets]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[fetch-ai-assets]${NC} $*"; }

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$PROJECT_ROOT/iso-builder/ai-assets"
MODELS_DIR="$ASSETS_DIR/models"
DOCS_DIR="$ASSETS_DIR/void-docs"

# Model configuration (pinned for reproducibility)
MODEL_NAME="qwen2.5-coder-3b-instruct.Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
MODEL_SHA256="PLACEHOLDER_SHA256"  # TODO: Update with actual SHA256 after first download

info "Fetching AI assets for ISO build..."

# Create directories
mkdir -p "$MODELS_DIR"
mkdir -p "$DOCS_DIR"

# Download AI model
info "Downloading Qwen 2.5 Coder 3B model (~1.2-2GB)..."
info "This may take several minutes depending on your connection..."

if [ -f "$MODELS_DIR/$MODEL_NAME" ]; then
    warn "Model already exists, skipping download"
else
    if command -v wget &>/dev/null; then
        wget -O "$MODELS_DIR/$MODEL_NAME" "$MODEL_URL" || {
            error "Failed to download model"
            exit 1
        }
    elif command -v curl &>/dev/null; then
        curl -L -o "$MODELS_DIR/$MODEL_NAME" "$MODEL_URL" || {
            error "Failed to download model"
            exit 1
        }
    else
        error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    info "Model downloaded: $MODEL_NAME"
fi

# Verify checksum (if not placeholder)
if [ "$MODEL_SHA256" != "PLACEHOLDER_SHA256" ]; then
    info "Verifying model checksum..."
    if command -v sha256sum &>/dev/null; then
        echo "$MODEL_SHA256  $MODELS_DIR/$MODEL_NAME" | sha256sum -c - || {
            error "Checksum verification failed!"
            error "Expected: $MODEL_SHA256"
            error "This could indicate a corrupted download or security issue."
            exit 1
        }
        info "Checksum verified!"
    else
        warn "sha256sum not found, skipping verification"
    fi
else
    warn "SHA256 checksum not set (using placeholder)"
    info "To add verification, run:"
    info "  sha256sum $MODELS_DIR/$MODEL_NAME"
    info "Then update MODEL_SHA256 in this script"
fi

# Download Void Linux documentation
info "Downloading Void Linux documentation..."

if [ -d "$DOCS_DIR" ] && [ "$(ls -A "$DOCS_DIR" 2>/dev/null)" ]; then
    warn "Documentation already exists, skipping download"
else
    info "Mirroring docs.voidlinux.org (HTML only, ~10-20MB)..."
    
    # Use wget to mirror, stripping images/CSS/JS to save space
    wget --recursive \
         --no-parent \
         --no-host-directories \
         --reject "*.jpg,*.jpeg,*.png,*.gif,*.svg,*.css,*.js,*.woff,*.woff2,*.ttf,*.eot" \
         --accept "*.html,*.txt,*.md" \
         --level=5 \
         --cut-dirs=0 \
         --directory-prefix="$DOCS_DIR" \
         --no-clobber \
         --timeout=30 \
         --tries=3 \
         https://docs.voidlinux.org/ 2>&1 | grep -E "(saved|URL:)" || true
    
    info "Documentation downloaded"
fi

# Show sizes
info "Asset sizes:"
if [ -f "$MODELS_DIR/$MODEL_NAME" ]; then
    model_size=$(du -h "$MODELS_DIR/$MODEL_NAME" | cut -f1)
    info "  Model: $model_size"
fi

if [ -d "$DOCS_DIR" ]; then
    docs_size=$(du -sh "$DOCS_DIR" | cut -f1)
    info "  Docs: $docs_size"
fi

total_size=$(du -sh "$ASSETS_DIR" | cut -f1)
info "  Total: $total_size"

info "AI assets ready for ISO build!"
info "Assets location: $ASSETS_DIR"

# Create marker file
echo "Assets fetched: $(date)" > "$ASSETS_DIR/.fetched"

exit 0
