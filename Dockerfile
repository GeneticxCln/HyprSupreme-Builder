# HyprSupreme-Builder Docker Image
# Multi-stage build for optimized production image

# Build stage
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Install additional dependencies for web interface
RUN pip install --no-cache-dir \
    flask>=2.0.0 \
    flask-cors>=4.0.0 \
    gunicorn>=20.1.0 \
    redis>=4.0.0

# Production stage
FROM python:3.11-slim as production

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    HYPRSUPREME_CONFIG_DIR="/app/config" \
    HYPRSUPREME_DATA_DIR="/app/data" \
    FLASK_APP="community.web_interface:app" \
    FLASK_ENV="production"

# Install runtime system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    tar \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user
RUN groupadd -r hyprsupreme && useradd -r -g hyprsupreme hyprsupreme

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Create application directories
RUN mkdir -p /app/config /app/data /app/logs /app/backups && \
    chown -R hyprsupreme:hyprsupreme /app

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=hyprsupreme:hyprsupreme . .

# Create necessary directories and set permissions
RUN mkdir -p /app/community/static /app/community/templates && \
    chown -R hyprsupreme:hyprsupreme /app && \
    chmod +x /app/*.sh /app/tools/*.py

# Install the package in development mode
RUN pip install -e .

# Create entrypoint script
RUN cat > /app/docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Initialize configuration if not exists
if [ ! -f "$HYPRSUPREME_CONFIG_DIR/config.json" ]; then
    echo "Initializing HyprSupreme configuration..."
    mkdir -p "$HYPRSUPREME_CONFIG_DIR"
    cat > "$HYPRSUPREME_CONFIG_DIR/config.json" << EOL
{
    "version": "2.0.0",
    "web_port": 5000,
    "web_host": "0.0.0.0",
    "debug": false,
    "community_enabled": true,
    "backup_enabled": true
}
EOL
fi

# Initialize database if not exists
if [ ! -f "$HYPRSUPREME_DATA_DIR/community.db" ]; then
    echo "Initializing community database..."
    mkdir -p "$HYPRSUPREME_DATA_DIR"
    python -c "
from community.community_platform import CommunityPlatform
platform = CommunityPlatform(data_dir='$HYPRSUPREME_DATA_DIR')
platform.init_database()
print('Database initialized successfully')
"
fi

# Execute the command
exec "$@"
EOF

RUN chmod +x /app/docker-entrypoint.sh && \
    chown hyprsupreme:hyprsupreme /app/docker-entrypoint.sh

# Switch to non-root user
USER hyprsupreme

# Expose ports
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Default command - start web server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "--timeout", "120", "community.web_interface:app"]

# Metadata
LABEL maintainer="HyprSupreme Team <contact@hyprsupreme.dev>" \
      description="HyprSupreme-Builder - The ultimate Hyprland configuration suite" \
      version="2.0.0" \
      org.opencontainers.image.title="HyprSupreme-Builder" \
      org.opencontainers.image.description="The ultimate Hyprland configuration suite with advanced community features" \
      org.opencontainers.image.version="2.0.0" \
      org.opencontainers.image.vendor="HyprSupreme Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/GeneticxCln/HyprSupreme-Builder" \
      org.opencontainers.image.documentation="https://github.com/GeneticxCln/HyprSupreme-Builder/blob/main/README.md"

