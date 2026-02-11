#!/bin/bash
# Run the Pi Agent in one-shot mode (non-interactive)
# Usage:
#   ./scripts/run-oneshot.sh "list all TypeScript files"
#   echo "fix the tests" | ./scripts/run-oneshot.sh
set -e

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required but not installed."
    exit 1
fi

# Read provider from settings (default to anthropic if missing or file doesn't exist)
SETTINGS_FILE=".pi/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    PROVIDER=$(jq -r '.model.provider // "anthropic"' "$SETTINGS_FILE")
else
    PROVIDER="anthropic"
fi

# Determine required environment variable based on provider
case "$PROVIDER" in
    anthropic)
        API_KEY_VAR="ANTHROPIC_API_KEY"
        ;;
    openai)
        API_KEY_VAR="OPENAI_API_KEY"
        ;;
    google|gemini)
        API_KEY_VAR="GEMINI_API_KEY"
        ;;
    xai)
        API_KEY_VAR="XAI_API_KEY"
        ;;
    groq)
        API_KEY_VAR="GROQ_API_KEY"
        ;;
    *)
        echo "⚠️  Warning: Unknown provider '$PROVIDER'. Defaulting to ANTHROPIC_API_KEY."
        API_KEY_VAR="ANTHROPIC_API_KEY"
        ;;
esac

# Check if the required API key environment variable is set
if [ -z "${!API_KEY_VAR}" ]; then
    echo "❌ Error: $API_KEY_VAR is not set."
    echo "   export $API_KEY_VAR=sk-..."
    exit 1
fi

podman run --rm \
    --network host \
    -v "$(pwd)":/workspace:Z \
    -e "$API_KEY_VAR=${!API_KEY_VAR}" \
    pi-agent:latest -p "$@"
