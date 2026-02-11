---
name: extend-self
description: Create new skills, extensions, or prompt templates for this agent. Use when you need to add a reusable capability, register a custom tool, or create a workflow template. Contains the full API reference.
---

# Extend Self

This skill is your complete reference for creating new capabilities. Choose the right mechanism based on what you need.

## Decision Tree

```
Need a new capability?
│
├─ Quick, one-off task?
│  └─ Write a Shell Script in scripts/ or /tmp
│     Execute with bash, read the output
│
├─ Reusable workflow with instructions?
│  └─ Create a Skill (.pi/skills/<name>/SKILL.md)
│     Auto-discovered, invoked via /skill:<name>
│
└─ Programmatic hooks, custom tools, event handling?
   └─ Write a TypeScript Extension (.pi/extensions/<name>.ts)
      Auto-loaded by ResourceLoader
```

---

## Extensions Reference

Extensions are TypeScript files that hook into the Pi agent's event system. They can register tools, commands, shortcuts, and flags.

### Locations

| Location | Scope |
|----------|-------|
| `.pi/extensions/*.ts` | Project-local |
| `.pi/extensions/*/index.ts` | Project-local (subdirectory) |
| `~/.pi/agent/extensions/*.ts` | Global (ephemeral in Docker) |

**Inside Docker:** prefer `.pi/extensions/` (persisted via bind mount).

### Minimal Extension

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Subscribe to events
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension loaded!", "info");
  });

  // Register a command (invoked with /my-command)
  pi.registerCommand("my-command", {
    description: "What this command does",
    handler: async (args, ctx) => {
      ctx.ui.notify(`Args: ${args}`, "info");
    },
  });
}
```

### Registering a Custom Tool

Custom tools are callable by the LLM. They appear in the system prompt.

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "my_tool",
    label: "My Tool",
    description: "What this tool does (shown to LLM)",
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      // Stream progress
      onUpdate?.({ content: [{ type: "text", text: "Working..." }] });

      // Do the work
      const result = await pi.exec("my-command", [], { signal });

      return {
        content: [{ type: "text", text: "Done" }],  // Sent to LLM
        details: { data: result },                   // For rendering & state
      };
    },
  });
}
```

### Available Imports

| Package | Purpose |
|---------|---------|
| `@mariozechner/pi-coding-agent` | Extension types (`ExtensionAPI`, `ExtensionContext`, events) |
| `@sinclair/typebox` | Schema definitions for tool parameters |
| `@mariozechner/pi-ai` | AI utilities (`StringEnum` for Google-compatible enums) |
| `@mariozechner/pi-tui` | TUI components for custom rendering |

Node.js built-ins (`node:fs`, `node:path`, etc.) are also available. TypeScript works without compilation (loaded via jiti).

### Key ExtensionAPI Methods

| Method | Purpose |
|--------|---------|
| `pi.on(event, handler)` | Subscribe to events (session_start, tool_call, agent_end, etc.) |
| `pi.registerTool(def)` | Register a custom tool callable by the LLM |
| `pi.registerCommand(name, opts)` | Register a slash command (`/name`) |
| `pi.registerShortcut(key, opts)` | Register a keyboard shortcut |
| `pi.registerFlag(name, opts)` | Register a toggle flag |
| `pi.sendMessage(msg, opts)` | Inject a message into the session |
| `pi.sendUserMessage(content, opts)` | Send a user message as if typed |
| `pi.appendEntry(type, data)` | Persist extension state (not sent to LLM) |
| `pi.exec(cmd, args, opts)` | Execute a command |
| `pi.getActiveTools()` | List active tools |
| `pi.setModel(model)` | Switch model |

### Events

| Event | Fires When |
|-------|------------|
| `session_start` | Session begins or is loaded |
| `session_end` | Session ends |
| `agent_start` | Agent turn begins |
| `agent_end` | Agent turn completes |
| `tool_call` | Before a tool executes (can block with `{ block: true }`) |
| `tool_result` | After a tool returns |
| `model_request` | Before LLM API call |
| `model_response` | After LLM API response |
| `user_bash` | User types a `!` prefixed bash command |
| `input_submitted` | User submits input |

### Extension Styles

- **Single file:** `.pi/extensions/my-ext.ts`
- **Directory:** `.pi/extensions/my-ext/index.ts` (with helpers)
- **Package:** `.pi/extensions/my-ext/` with `package.json` + `node_modules/`

---

## Skills Reference

Skills are markdown-based instructions the agent reads on demand. They provide progressive disclosure — only the description is in the system prompt; full instructions are loaded when needed.

### Locations

| Location | Scope |
|----------|-------|
| `.pi/skills/<name>/SKILL.md` | Project-local |
| `.pi/skills/<name>.md` | Project-local (single-file) |
| `~/.pi/agent/skills/` | Global (ephemeral in Docker) |

### SKILL.md Format

```markdown
---
name: my-skill
description: What this skill does and when to use it. Be specific so the agent knows when to load it.
---

# My Skill

## Steps

1. Do X
2. Run `./scripts/process.sh`
3. Read the output and act on it
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase a-z, 0-9, hyphens only. Max 64 chars. Must match parent directory name. |
| `description` | Yes | Max 1024 chars. Be specific about *what* and *when*. |
| `license` | No | License name |
| `compatibility` | No | Environment requirements |
| `disable-model-invocation` | No | If `true`, hidden from system prompt (user must invoke manually) |

### Naming Rules

- 1–64 characters
- Lowercase letters, numbers, hyphens only
- No leading/trailing/consecutive hyphens
- Must match parent directory name

### Skill Structure

```
my-skill/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Helper scripts the agent can run
│   └── process.sh
├── references/           # Detailed docs loaded on-demand
│   └── api-reference.md
└── assets/               # Templates, configs, etc.
```

### Invoking Skills

```
/skill:my-skill              # Load and follow the instructions
/skill:my-skill some args    # Load with arguments
```

### Creating a New Skill — Step by Step

1. Choose a name (lowercase, hyphens, 1-64 chars): e.g., `pdf-extract`
2. Create the directory and SKILL.md:

```bash
mkdir -p /workspace/.pi/skills/pdf-extract
```

3. Write `SKILL.md` with required frontmatter:

```markdown
---
name: pdf-extract
description: Extract text and tables from PDF files. Use when working with PDF documents.
---

# PDF Extract

## Steps
1. Install dependencies: `pip3 install pdfplumber`
2. Run the extraction script: `python3 scripts/extract.py <file>`
3. Read and process the output
```

4. Add helper scripts if needed:

```bash
mkdir -p /workspace/.pi/skills/pdf-extract/scripts
# Write the script
```

5. The skill is auto-discovered on the next turn. Invoke with `/skill:pdf-extract`.

---

## Prompt Templates Reference

Prompt templates are markdown snippets that expand into full prompts.

### Locations

| Location | Scope |
|----------|-------|
| `.pi/prompts/*.md` | Project-local |
| `~/.pi/agent/prompts/*.md` | Global (ephemeral in Docker) |

### Format

```markdown
---
description: What this template does
---
The prompt content. Use $1, $2 for positional args, $@ for all args.
```

The filename becomes the command: `review.md` → `/review`.

### Arguments

| Syntax | Meaning |
|--------|---------|
| `$1`, `$2`, ... | Positional arguments |
| `$@` or `$ARGUMENTS` | All arguments joined |
| `${@:N}` | Arguments from Nth position |
| `${@:N:L}` | L arguments starting at N |

### Creating a Prompt Template

```bash
mkdir -p /workspace/.pi/prompts
cat > /workspace/.pi/prompts/review.md << 'EOF'
---
description: Review staged git changes
---
Review the staged changes (`git diff --cached`). Focus on:
- Bugs and logic errors
- Security issues
- Error handling gaps
EOF
```

Invoke with `/review` in the editor.

---

## Settings Reference

Project settings live in `.pi/settings.json`:

```json
{
  "model": { "provider": "anthropic", "id": "claude-sonnet-4-20250514" },
  "thinkingLevel": "medium",
  "compaction": { "enabled": true },
  "retry": { "enabled": true, "maxRetries": 3 },
  "enableSkillCommands": true
}
```

Key settings: `model`, `thinkingLevel` (none/low/medium/high), `compaction`, `retry`, `enableSkillCommands`, `packages`, `extensions`, `skills`, `prompts`.

---

## Creating a New Extension — Step by Step

1. Create the file in `.pi/extensions/`:

```bash
cat > /workspace/.pi/extensions/my-tool.ts << 'EOF'
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "my_tool",
    label: "My Tool",
    description: "What this tool does",
    parameters: Type.Object({
      input: Type.String({ description: "Input parameter" }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return {
        content: [{ type: "text", text: `Result for: ${params.input}` }],
        details: {},
      };
    },
  });
}
EOF
```

2. The extension is auto-loaded by the ResourceLoader. A restart may be needed for complex extensions.

## Checklist

After creating any new capability:
- [ ] Verify the file exists and is well-formed
- [ ] Test it (run the skill, invoke the command, expand the template)
- [ ] Commit to version control if it should persist across sessions
