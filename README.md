# Chamuka Pi Agent

A Docker-containerised coding agent powered by the [Pi SDK](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) and governed by the Constitution of minimal, shell-first AI.

> **Status:** Alpha  
> **Container:** `pi-agent:latest` (based on `node:20-slim`)  
> **Engine:** Podman (OCI-compatible)

## Quick Start

1. **Build the image:**
   ```bash
   ./scripts/build.sh
   ```

2. **Set your API key:**
   ```bash
   export ANTHROPIC_API_KEY=sk-ant-...
   ```

3. **Run in your project:**
   ```bash
   cd /path/to/my-project
   /path/to/pi-agent/scripts/run.sh
   ```

---

## What Can This Agent Do?

The agent runs inside a container with full access to your project via a bind mount. It uses `bash`, `git`, `ripgrep`, and Node.js tools to understand and modify your code.

### 1. 🛠️ DevOps & System Administration
Analyze logs, manage configurations, or write complex shell scripts.

**Log Analysis (One-shot):**
```bash
./scripts/run-oneshot.sh "Analyze the 'access.log' file. Identifying the top 5 IP addresses by request count, and summarising any 5xx errors found throughout the file. Output the results as a markdown table."
```

**Infrastructure as Code (Interactive):**
```bash
> ./scripts/run.sh
User: "Read the current AWS CloudFormation templates in 'infra/'. Refactor them to use AWS CDK (TypeScript), following best practices for modular constructs."
```

### 2. 📊 Data Analysis & Reporting
Process raw data files and generate insights.

**Data Processing (One-shot):**
```bash
./scripts/run-oneshot.sh "Read 'sales_data.csv'. Calculate the month-over-month growth rate for each product category. Generate a Python script to visualize this trend using matplotlib, and save the plot to 'growth_chart.png'."
```

### 3. ✍️ Content Creation & Technical Writing
Turn code and method signatures into human-readable content.

**Blog Post Generation (Interactive):**
```bash
> ./scripts/run.sh
User: "Read the git log and the 'CHANGELOG.md' for the last month. Write a technical blog post announcing the new features, including code snippets for the breaking changes. Tone: Excited and professional."
```

### 4. 🛡️ Security Auditing
Scan your project for vulnerabilities and configuration issues.

**Dependency Audit (One-shot):**
```bash
./scripts/run-oneshot.sh "Scan 'package.json' and 'package-lock.json'. Identify any dependencies with known high-severity vulnerabilities (check online databases if needed via curl). Recommend updated versions."
```

### 5. 🎓 Education & Onboarding
Use the agent as a tutor to learn a new codebase.

**Codebase Quiz (Interactive):**
```bash
> ./scripts/run.sh
User: "Create a 10-question multiple-choice quiz about the architecture of this project. Focus on the interaction between the 'AuthService' and the 'DatabaseAdapter'. Don't show me the answers yet, ask me one by one."
```

---

## Extending the Agent (The Right to Self-Modification)

The agent supports **runtime extension** to add new capabilities without rebuilding the container.

### 1. Extensions (`.ts`)
Place TypeScript files in `.pi/extensions/`. They are auto-loaded (no compilation needed).

**Example:** `.pi/extensions/hello.ts`
```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("hello", {
    description: "Say hello",
    handler: async (args, ctx) => {
      ctx.ui.notify(`Hello ${args || "World"}!`, "info");
    },
  });
}
```

### 2. Skills (`SKILL.md`)
Create a directory in `.pi/skills/<name>/` and add a `SKILL.md`. The agent will see this skill in its system prompt and can invoke it.

**Example:** `.pi/skills/deploy/SKILL.md`
```markdown
---
name: deploy
description: Deploy the application to production
---

# Deployment Instructions
1. Run `npm run build`
2. Run `./scripts/deploy.sh`
```

---

## Architecture

- **Constitution:** Governs the agent's behavior (e.g., "Bash is All You Need", "Read Before Write"). Embedded in the system prompt.
- **Isolation:** Runs in a rootless Podman container. No access to your host system outside the mounted project directory.
- **Persistence:** Only changes to `/workspace` (your project) are saved. Container filesystem is ephemeral.
- **Steering:** Supports `Ctrl+C` to abort and real-time steering if you type while it's working (thanks to Docker TTY passthrough).
- **Self-Extension:** The agent can create its own tools, skills, and prompt templates at runtime. See `.pi/skills/extend-self/SKILL.md`.

