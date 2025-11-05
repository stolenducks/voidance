#FROM ghcr.io/void-linux/void-glibc:latest
FROM voidlinux/voidlinux:latest

# Don't sync repos - they're broken. Clone void-mklive from source instead
RUN cd /tmp && \
    git clone --depth=1 https://github.com/void-linux/void-mklive.git 2>/dev/null || true && \
    if [ -d /tmp/void-mklive ]; then \
        cp /tmp/void-mklive/mklive.sh.in /usr/local/bin/mklive.sh || true; \
        chmod +x /usr/local/bin/mklive.sh || true; \
    fi

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . /workspace/

# Make scripts executable  
RUN chmod +x /workspace/scripts/*.sh

# Default command
CMD ["/bin/bash"]
