FROM node:20-slim

# Install shell tools required by the Constitution (Art. I — Supremacy of the Shell)
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    jq \
    ripgrep \
    tmux \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install the Pi coding agent globally
RUN npm install -g @mariozechner/pi-coding-agent

# Copy project-level agent configuration
COPY .pi/system-prompt.md /opt/pi-agent/system-prompt.md
COPY .pi/AGENTS.md /opt/pi-agent/AGENTS.md
COPY .pi/settings.json /opt/pi-agent/settings.json

# Copy and set up entrypoint
COPY entrypoint.sh /opt/pi-agent/entrypoint.sh
RUN chmod +x /opt/pi-agent/entrypoint.sh

# Set the workspace as the working directory
WORKDIR /workspace

ENTRYPOINT ["/opt/pi-agent/entrypoint.sh"]
