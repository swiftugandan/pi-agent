#!/bin/bash
# Build the Pi Agent container image
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔨 Building pi-agent:latest..."
podman build -t pi-agent:latest "$PROJECT_DIR"
echo "✅ Build complete: pi-agent:latest"
