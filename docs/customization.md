# Customization Guide

When you run `/choo-choo-ralph:install`, you get local copies of shell scripts and formulas in your project. These aren't just configuration—they're yours to modify.

## Why Local Copies?

Different projects have different needs:

- A React app needs UI verification steps; a CLI tool doesn't
- One codebase might need more explicit prompts in the bearings phase
- A legacy project might require extra health checks before implementation
- Some teams want verbose commit messages; others prefer terse

The plugin provides working defaults, but you control the actual workflow. Think of install as an "eject" operation: you start with something that works, then adapt it to your project.

## What Gets Installed

See [Commands Reference](./commands.md#choo-choo-ralphinstall) for the complete list of files created. All of these are plain text files you can edit directly.

---

## Shell Scripts

### ralph.sh

The main loop that runs Ralph until tasks are done or a limit is reached.

**Key customization points:**

```bash
# Default iteration limit (line 9)
MAX_ITERATIONS=100

# The prompt Claude receives (line 44)
claude --dangerously-skip-permissions ... -p "
Run \`bd ready --assignee=ralph -n 100 --sort=priority\` to see available tasks.
..."
```

**Common customizations:**

| What | How |
|------|-----|
| Change default iterations | Edit `MAX_ITERATIONS=100` |
| Different task sorting | Change `--sort=priority` to `--sort=created` |
| Limit visible tasks | Change `-n 100` to `-n 10` |
| Add logging | Add `echo` statements or redirect output |
| Change the prompt | Edit the heredoc passed to `claude -p` |

**Example: Add pre-run health check**

```bash
# Add before the while loop (after line 25)
echo "Running pre-flight health check..."
npm test --silent || { echo "Tests failing, aborting"; exit 1; }
```

### ralph-once.sh

Runs exactly one iteration, useful for testing before a long run. Same structure as `ralph.sh` but without the loop.

**When to customize:**
- Add debugging output
- Run interactively (it doesn't use `--dangerously-skip-permissions`)
- Test prompt changes before putting them in `ralph.sh`

### ralph-format.sh

Parses Claude's JSON output stream and formats it for the terminal.

**Key customization points:**

```bash
# Colors (lines 8-18)
BLUE='\033[34m'
GREEN='\033[32m'
# ... etc

# What gets shown for each tool (lines 84-133)
case "$name" in
    Bash)
        # How Bash tool calls display
        ;;
    Read|Write|Edit)
        # How file operations display
        ;;
```

**Common customizations:**

| What | How |
|------|-----|
| Change colors | Edit the color definitions |
| Show more/less output | Adjust truncation limits |
| Hide certain tools | Add `continue` in the case statement |
| Add timestamps | Prepend `$(date +%H:%M:%S)` to output |

**Example: Always show full commands**

```bash
# In the Bash case (around line 86), remove the truncation:
Bash)
    cmd=$(echo "$item" | jq -r '.input.command // empty' 2>/dev/null)
    echo -e "${YELLOW}🔧 ${BOLD}${name}${RESET} ${GRAY}${desc}${RESET}"
    print_wrapped "${GRAY}   │ ${RESET}${DIM}" "$cmd"
    ;;
```

---

## Formulas

Formulas define the multi-step workflow Ralph follows. See [Formula Reference](./formulas.md) for complete documentation.

### Quick Overview

The default `choo-choo-ralph.formula.toml` defines:

```
bearings → implement → verify → commit
```

Each step has:
- **id** - Unique identifier
- **title** - Human-readable name (supports `{{variables}}`)
- **assignee** - Who executes (`ralph-subagent-*` or `ralph-inline-*`)
- **needs** - Dependencies on other steps
- **description** - The prompt/instructions for that step

### Common Formula Customizations

**Adjust the bearings health check:**

The bearings step includes smoke testing with dev-browser. If your project doesn't have a UI:

```toml
# In .beads/formulas/choo-choo-ralph.formula.toml
# Find the bearings step and edit the description:
description = """
# BEARINGS PHASE

## Goal
1. Verify the codebase is in a healthy state
2. Understand the relevant code for this task

## STEP 1: Health Check (MANDATORY)

1. **Run test suite** - Execute existing tests
2. **Run type checking** - If applicable

# Remove or comment out the dev-browser smoke test section
"""
```

**Add a code review step:**

```toml
[[steps]]
id = "review"
title = "Self-review {{title}}"
assignee = "ralph-subagent-review"
labels = ["ralph-step", "review"]
needs = ["implement"]
description = """
Review the implementation for:
- Code quality issues
- Missing edge cases
- Security concerns

Report findings to orchestrator.
"""

# Update verify to depend on review instead of implement
[[steps]]
id = "verify"
needs = ["review"]  # Changed from ["implement"]
```

**Skip commits for prototyping:**

Remove or comment out the commit step, or make it conditional:

```toml
[vars.skip_commit]
default = "false"

[[steps]]
id = "commit"
condition = "{{skip_commit}}"  # Only runs if skip_commit is truthy
```

For complete formula documentation, see [Formula Reference](./formulas.md).

---

## Spec Directory

The `.choo-choo-ralph/` directory holds your spec files and related artifacts:

```
.choo-choo-ralph/
├── my-feature.spec.md      # Active spec files
├── archive/                # Completed specs
│   └── old-feature.spec.md
├── screenshots/            # UI verification screenshots
└── pour-preview.md         # Preview before pouring
```

**What you can customize:**
- Spec format (within the XML-like structure)
- Archive organization
- Screenshot naming conventions

---

## Updating Your Local Files

When the plugin updates, your local copies don't change automatically. This is intentional—your customizations are preserved.

**To get new features:**

1. Check the plugin's changelog for what changed
2. Manually merge changes into your local files, or
3. Re-run `/choo-choo-ralph:install` and choose "Overwrite" for specific files

**To see differences:**

```bash
# Compare your ralph.sh with the plugin's template
diff ralph.sh ~/.claude/plugins/choo-choo-ralph/templates/ralph.sh
```

**Recommended approach:**
- Keep customizations minimal and well-commented
- Document why you changed things (for future merges)
- Consider keeping the original as `ralph.sh.original` for reference

---

## Examples

### Minimal: Increase Iteration Limit

```bash
# ralph.sh line 9
MAX_ITERATIONS=200
```

### Moderate: Customize the Prompt

The prompt in `ralph.sh` tells Claude how to pick and execute tasks. You might customize it to:

**Add project-specific guidance:**

```bash
# ralph.sh, edit the prompt (around line 44)
claude --dangerously-skip-permissions --output-format stream-json --verbose -p "
Run \`bd ready --assignee=ralph -n 100 --sort=priority\` to see available tasks.

Pick ONE task, claim it with \`bd update <id> --status in_progress\`, then execute it.

IMPORTANT: This is a Rails project. Always run \`bin/rails test\` not \`rake test\`.
Always check for N+1 queries when touching ActiveRecord code.

After the task is done, EXIT immediately.
" 2>&1 | ...
```

**Focus on specific labels:**

```bash
# Only work on tasks with a specific label
claude ... -p "
Run \`bd ready --assignee=ralph --label=frontend\` to see available tasks.
..."
```

**Change task selection behavior:**

```bash
# Work oldest tasks first instead of by priority
claude ... -p "
Run \`bd ready --assignee=ralph --sort=created\` to see available tasks.

Pick the OLDEST task (first in the list) to ensure nothing gets stuck.
..."
```

### Advanced: Custom Singular Formula

For simple tasks that don't need the full bearings → implement → verify → commit workflow, create a singular formula (no child steps).

Create `.beads/formulas/quick-task.formula.toml`:

```toml
formula = "quick-task"
description = """
# Quick Task: {{title}}

{{task}}

## Instructions

1. Make the change described above
2. Run basic verification (tests, types)
3. If verification passes, commit with message: `chore: {{title}}`
4. Close this bead: `bd close <your-id>`

Keep it minimal. No extensive exploration needed.
"""
version = 1

[vars.title]
required = true

[vars.task]
required = true
```

This creates a single bead with no children—Ralph executes it directly.

Once your formula is in `.beads/formulas/`, it appears as an option when you run `/choo-choo-ralph:pour`. The pour command handles mapping your spec tasks to the formula's variables automatically.

You can also pour manually for one-off tasks:
```bash
bd mol pour quick-task --var title="Fix typo in README" --var task="Change 'teh' to 'the' on line 42" --assignee ralph
```

For workflows with child steps (like the default choo-choo-ralph formula), see [Formula Reference](./formulas.md) for orchestrator patterns.

---

## Tips

1. **Start with defaults** - Run a few tasks before customizing
2. **Make small changes** - One modification at a time
3. **Test with ralph-once.sh** - Verify changes work before long runs
4. **Keep a changelog** - Note what you changed and why
5. **Check formulas.md** - Deep dive on formula customization
