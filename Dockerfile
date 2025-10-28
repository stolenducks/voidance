FROM voidlinux/voidlinux:latest

# Install build dependencies
# Skip repo sync, use what's in the base image
RUN xbps-install -y \
    void-mklive \
    git \
    xz \
    wget \
    curl \
    bash \
    || true

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . /workspace/

# Make scripts executable
RUN chmod +x /workspace/scripts/*.sh

# Default command
CMD ["/bin/bash"]
