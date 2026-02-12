---
description: Install Choo Choo Ralph into the current project
---

# Install Choo Choo Ralph

Set up the Ralph autonomous coding workflow in this project.

## Pre-requisites Check

1. **Check beads CLI**: Run `bd --version`
   - If not installed: "Please install beads first. See: https://github.com/steveyegge/beads"

2. **Check Claude CLI**: Run `claude --version`
   - If not installed: Warn user they'll need it to run Ralph

3. **Check jq**: Run `jq --version`
   - If not installed: "Please install jq for JSON parsing. See: https://jqlang.github.io/jq/"

4. **Initialize beads**: If `.beads/` doesn't exist, run `bd init`

## Check for Existing Files

Before installing, check which files already exist:
- `./ralph.sh`
- `./ralph-once.sh`
- `./ralph-format.sh`
- `./ralph-dashboard.sh`
- `./ralph-report.sh`
- `./ralph-schedule.sh`
- `.beads/formulas/choo-choo-ralph.formula.toml`
- `.beads/formulas/bug-fix.formula.toml`

**If ANY files exist**: Use AskUserQuestion to ask user for each existing file whether to:
- Skip (keep existing)
- Overwrite (replace with new version)

**If NO files exist**: Proceed directly to installation.

## Installation Steps

Use Bash `cp` commands for fast file copying (NOT Read/Write tools).

1. **Copy shell scripts** to project root (if not skipped):
   ```bash
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph.sh" ./ralph.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-once.sh" ./ralph-once.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-format.sh" ./ralph-format.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-dashboard.sh" ./ralph-dashboard.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-report.sh" ./ralph-report.sh
   cp "${CLAUDE_PLUGIN_ROOT}/templates/ralph-schedule.sh" ./ralph-schedule.sh
   chmod +x ralph.sh ralph-once.sh ralph-format.sh ralph-dashboard.sh ralph-report.sh ralph-schedule.sh
   ```

2. **Set up formulas directory**:
   ```bash
   mkdir -p .beads/formulas
   cp "${CLAUDE_PLUGIN_ROOT}/templates/choo-choo-ralph.formula.toml" .beads/formulas/
   cp "${CLAUDE_PLUGIN_ROOT}/templates/bug-fix.formula.toml" .beads/formulas/
   ```

3. **Create spec directory**:
   ```bash
   mkdir -p .choo-choo-ralph
   ```

4. **Verify installation**:
   - Confirm all files exist
   - Run `bd formula list` to verify both formulas are registered (choo-choo-ralph and bug-fix)

## Dashboard Init

After copying files, configure the Ralph Dashboard connection.

1. **Check dashboard**: Try `curl -sf http://localhost:3001/api/projects`
   - If it responds: Dashboard is running
   - If it fails: Tell the user the dashboard isn't running and skip this phase. Print:
     ```
     Dashboard not detected at http://localhost:3001.
     To enable dashboard monitoring later, start the dashboard and run:
       curl -X POST http://localhost:3001/api/projects \
         -H 'Content-Type: application/json' \
         -d '{"name": "<project>", "path": "<path-to-.beads/>"}'
     ```

2. **Register the project**: If the dashboard is reachable:
   - Get the project name: `basename $(pwd)`
   - Get the beads path: `$(pwd)/.beads/`
   - Check if already registered: `curl -sf http://localhost:3001/api/projects | jq -r '.[] | select(.path == "<beads-path>") | .id'`
   - If not registered, POST to register:
     ```bash
     curl -sf -X POST http://localhost:3001/api/projects \
       -H 'Content-Type: application/json' \
       -d "{\"name\": \"$(basename $(pwd))\", \"path\": \"$(pwd)/.beads/\"}"
     ```
   - Save the project ID from the response

3. **Report success**: Print the dashboard URL and project ID so the user knows where to view their project.

## Recommended Plugins

1. **Check dev-browser plugin**: Check your available skills for `dev-browser`
   - If not available, recommend installing it for browser-based smoke tests and UI verification
   - GitHub: https://github.com/SawyerHood/dev-browser
   - This plugin is used by the bearings step (smoke test) and verify step (UI verification)

## Output

Report what was installed (and what was skipped if applicable):

- Scripts: ralph.sh, ralph-once.sh, ralph-format.sh, ralph-dashboard.sh, ralph-report.sh, ralph-schedule.sh
- Formulas: .beads/formulas/choo-choo-ralph.formula.toml, .beads/formulas/bug-fix.formula.toml
- Spec directory: .choo-choo-ralph/
- Dashboard: registered (or skipped)

Explain next steps:

1. Use `/choo-choo-ralph:spec` to generate a spec from your plan
2. Review and approve features in the spec
3. Use `/choo-choo-ralph:pour` to create beads
4. Run `./ralph.sh` for standalone or `./ralph-dashboard.sh` for dashboard-monitored runs
5. Schedule overnight runs: `./ralph-schedule.sh "11pm" . 50`
