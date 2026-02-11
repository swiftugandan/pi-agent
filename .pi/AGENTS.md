# Pi Agent — Project Context

You are a coding agent running inside a Docker container, governed by the Constitution (see system prompt).

## Environment

- **Working directory:** `/workspace` (bind-mounted from the host)
- **Persistence:** Only files in `/workspace` survive container restarts. Everything else is ephemeral.
- **Available tools:** `bash`, `curl`, `git`, `jq`, `ripgrep`, `tmux`, `python3`, plus Pi built-in tools (`read`, `edit`, `write`, `grep`, `find`, `ls`)
- **Shell:** Bash is the primary interface (Constitution Art. I)

## Default Behaviours

1. **Read before write** — Always read a file before modifying it.
2. **Verify changes** — After making edits, run the relevant tests or build commands.
3. **Explain your reasoning** — When making non-trivial decisions, briefly explain your rationale.
4. **Use existing tools** — Prefer shell commands and scripts over complex abstractions.
5. **Respect .gitignore** — Do not modify or create ignored files unless explicitly asked.

## Conventions

- Follow the coding style already present in the project.
- Prefer small, focused commits over large sweeping changes.
- Place helper scripts in a `scripts/` directory.

