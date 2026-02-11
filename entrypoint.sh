#!/bin/bash
set -e

# ============================================================
# Pi Agent Docker Entrypoint
# Ensures workspace is mounted, sets up .pi config, and
# launches the Pi agent with the Constitution-based prompt.
# ============================================================

CONFIG_DIR="/opt/pi-agent"

# --- Workspace Check ---
if [ ! -d "/workspace" ] || [ -z "$(ls -A /workspace 2>/dev/null)" ]; then
    echo "⚠️  Warning: /workspace is empty or not mounted."
    echo "   Mount your project: docker run -v \$(pwd):/workspace ..."
    echo ""
fi

# --- Set up .pi project config if not already present ---
if [ ! -d "/workspace/.pi" ]; then
    mkdir -p /workspace/.pi
fi

# Copy settings if not present
if [ ! -f "/workspace/.pi/settings.json" ]; then
    cp "$CONFIG_DIR/settings.json" /workspace/.pi/settings.json
fi

# Copy AGENTS.md to workspace root if not present
if [ ! -f "/workspace/AGENTS.md" ]; then
    cp "$CONFIG_DIR/AGENTS.md" /workspace/AGENTS.md
fi

# --- Set up system prompt via the global agent config ---
AGENT_DIR="${HOME}/.pi/agent"
mkdir -p "$AGENT_DIR"

# Copy the system prompt into the global agent config directory
cp /opt/pi-agent/system-prompt.md "$AGENT_DIR/system-prompt.md"

# --- Launch Pi ---
exec pi "$@"
