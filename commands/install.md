---
description: Install Choo Choo Ralph into the current project
---

# Install Choo Choo Ralph

Set up the Ralph autonomous coding workflow in this project. This is a complete init — after running this, the project is ready for spec → pour → run.

## Phase 1: Pre-requisites

1. **Check beads CLI**: Run `bd --version`
   - If not installed: "Please install beads first. See: https://github.com/steveyegge/beads"

2. **Check Claude CLI**: Run `claude --version`
   - If not installed: Warn user they'll need it to run Ralph

3. **Check jq**: Run `jq --version`
   - If not installed: "Please install jq for JSON parsing. See: https://jqlang.github.io/jq/"

## Phase 2: Initialize Project Structure

1. **Git init**: If not a git repo, run `git init`

2. **Beads init**: If `.beads/` doesn't exist, run `bd init`

3. **Check for existing files** before overwriting:
   - `./ralph.sh`, `./ralph-once.sh`, `./ralph-format.sh`
   - `./ralph-dashboard.sh`, `./ralph-report.sh`, `./ralph-schedule.sh`
   - `.beads/formulas/choo-choo-ralph.formula.toml`, `.beads/formulas/bug-fix.formula.toml`
   - `CLAUDE.md`

   **If ANY exist**: Use AskUserQuestion to ask for each existing file whether to skip or overwrite.

4. **Copy shell scripts** (use Bash `cp`, NOT Read/Write tools):
   ```bash
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph.sh" ./ralph.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-once.sh" ./ralph-once.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-format.sh" ./ralph-format.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-dashboard.sh" ./ralph-dashboard.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-report.sh" ./ralph-report.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-schedule.sh" ./ralph-schedule.sh
   chmod +x ralph.sh ralph-once.sh ralph-format.sh ralph-dashboard.sh ralph-report.sh ralph-schedule.sh
   ```

5. **Set up formulas**:
   ```bash
   mkdir -p .beads/formulas
   cp "${CLAUDE_PLUGIN_ROOT}/templates/choo-choo-ralph.formula.toml" .beads/formulas/
   cp "${CLAUDE_PLUGIN_ROOT}/templates/bug-fix.formula.toml" .beads/formulas/
   ```

6. **Create spec directory**:
   ```bash
   mkdir -p .choo-choo-ralph
   ```

7. **Verify**: Confirm files exist and `bd formula list` shows both formulas.

## Phase 3: Dashboard Registration

1. **Check dashboard**: Try `curl -sf http://localhost:3001/api/projects`
   - If it fails: Skip this phase. Print:
     ```
     Dashboard not detected at http://localhost:3001.
     To enable monitoring later, start the dashboard and re-run install.
     ```

2. **Register the project** (if dashboard is reachable):
   - Project name: `basename $(pwd)`
   - Beads path: `$(pwd)/.beads/`
   - Check if already registered: `curl -sf http://localhost:3001/api/projects | jq -r --arg p "$(pwd)/.beads/" '.[] | select(.path == $p) | .id'`
   - If not registered:
     ```bash
     curl -sf -X POST http://localhost:3001/api/projects \
       -H 'Content-Type: application/json' \
       -d "{\"name\": \"$(basename $(pwd))\", \"path\": \"$(pwd)/.beads/\"}"
     ```
   - Save the returned project ID for the CLAUDE.md template.

## Phase 4: Generate CLAUDE.md

This is the project context file. Ralph and every Claude session reads this to understand the project.

1. **Detect project info** by inspecting the repo:

   | Field | How to detect | Fallback |
   |-------|--------------|----------|
   | PROJECT_NAME | `basename $(pwd)` | — |
   | BUILD_CMD | Look for: `package.json` scripts.build, `Makefile`, `Cargo.toml`, `go.mod` | `# No build command detected — add one here` |
   | TEST_CMD | Look for: `package.json` scripts.test, `pytest.ini`, `Cargo.toml` test | `# No test command detected — add one here` |
   | LINT_CMD | Look for: `package.json` scripts.lint/typecheck, `.eslintrc`, `ruff.toml` | `# No lint command detected — add one here` |
   | DASHBOARD_PROJECT_ID | From Phase 3 registration response | `# Not registered — run /choo-choo-ralph:install` |
   | CONVENTIONS | Detect from existing code: language, framework, directory patterns | `# Add project conventions here` |

2. **Read the template** from `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.md.template`

3. **Replace placeholders** (`{{PROJECT_NAME}}`, `{{BUILD_CMD}}`, etc.) with detected values.

4. **If CLAUDE.md already exists**: Read it first. Append a `## Choo Choo Ralph` section at the end instead of overwriting. Only add sections that don't already exist (check for "## Beads", "## Ralph", etc.).

5. **Write the result** to `./CLAUDE.md`.

## Phase 5: .gitignore

Ensure these entries exist in `.gitignore` (append if missing, don't duplicate):
```
.choo-choo-ralph/screenshots/
*.log
```

## Recommended Plugins

1. **Check dev-browser plugin**: Check your available skills for `dev-browser`
   - If not available, recommend installing it for browser-based smoke tests and UI verification
   - GitHub: https://github.com/SawyerHood/dev-browser

## Output Summary

Print a checklist of what was set up:

```
Choo Choo Ralph installed!

  [x] Git repo
  [x] Beads initialized
  [x] Scripts: ralph.sh, ralph-once.sh, ralph-format.sh, ralph-dashboard.sh, ralph-report.sh, ralph-schedule.sh
  [x] Formulas: choo-choo-ralph, bug-fix
  [x] Spec directory: .choo-choo-ralph/
  [x] Dashboard: registered as project #N at http://localhost:3001
  [x] CLAUDE.md: generated with project context
  [x] .gitignore: updated

Next steps:
  1. Review CLAUDE.md and fill in any placeholders
  2. /choo-choo-ralph:spec to generate a spec from your plan
  3. /choo-choo-ralph:pour to create beads from the spec
  4. ./ralph-dashboard.sh 10 to run Ralph with dashboard monitoring
```
