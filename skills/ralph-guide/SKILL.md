---
name: Ralph Guide
description: Guidance for customizing Ralph workflows, formulas, learning capture, and troubleshooting. Use for questions about Ralph loop, formulas, harvesting learnings, or running multiple Ralphs.
---

# Ralph Guide

Quick reference for operating Choo Choo Ralph across all workflow phases.

## The Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   1. Plan   │ ──▶ │  2. Spec    │ ──▶ │  3. Pour    │ ──▶ │  4. Ralph   │ ──▶ │ 5. Harvest  │
│    (you)    │     │  (you + AI) │     │    (AI)     │     │    (AI)     │     │ (you + AI)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

1. **Plan** - Write what you want to build (this is on you)
2. **Spec** - AI transforms it into structured tasks; you review and refine
3. **Pour** - Tasks become beads (workflow or singular)
4. **Ralph** - The loop runs autonomously until done
5. **Harvest** - Extract learnings into skills, docs, or CLAUDE.md

See `${CLAUDE_PLUGIN_ROOT}/docs/workflow.md` for the complete guide.

## Prerequisites & Safety

**Required:**
- [Claude Code](https://claude.com/claude-code) - Anthropic's CLI
- [Beads](https://github.com/steveyegge/beads) - Git-backed issue tracker (`bd` command)
- [jq](https://jqlang.github.io/jq/) - JSON parsing

**Recommended:**
- [dev-browser](https://github.com/SawyerHood/dev-browser) - Browser automation for UI verification

**Safety:** Ralph runs with `--dangerously-skip-permissions`. Run in a Docker container or VM, especially for untrusted codebases.

## Install

```bash
/choo-choo-ralph:install
```

Creates local copies you can customize:

| File | Purpose |
|------|---------|
| `./ralph.sh` | Main loop script |
| `./ralph-once.sh` | Single iteration (for testing) |
| `./ralph-format.sh` | Output formatting |
| `.beads/formulas/choo-choo-ralph.formula.toml` | Standard workflow formula |
| `.beads/formulas/bug-fix.formula.toml` | Bug fix workflow formula |
| `.choo-choo-ralph/` | Spec file directory |

## Spec Phase

### Generate a Spec

```bash
/choo-choo-ralph:spec [source-file] [spec-name]
```

- From plan file: `/choo-choo-ralph:spec plans/my-feature.md`
- From conversation: `/choo-choo-ralph:spec` (uses context)
- With explicit name: `/choo-choo-ralph:spec plans/feature.md auth-system`

Specs are stored at `.choo-choo-ralph/{spec-name}.spec.md`

### Spec Format

Tasks use XML-like tags with a review workflow:

```xml
<task id="add-login-form" priority="1" category="functional">
  <title>Add Login Form Component</title>
  <description>Create a reusable login form...</description>
  <steps>
    1. Create LoginForm component
    2. Add validation
  </steps>
  <test_steps>
    1. Verify form renders
    2. Test validation
  </test_steps>
  <review></review>  <!-- Empty = ready to pour -->
</task>
```

### Review Process

1. **Add feedback** in `<review>` tags:
   ```xml
   <review>Split this into two tasks: validation and submission</review>
   ```
2. **Run `/choo-choo-ralph:spec` again** - AI processes feedback
3. **Repeat** until all `<review>` tags are empty

**Common review patterns:**
- Split: `<review>Split into: schema creation, indexes, migration</review>`
- Add detail: `<review>Add step for handling duplicate emails</review>`
- Remove: `<review>Remove - already exists in utils/</review>`
- Combine: `<review>Merge with task-xyz, too small separately</review>`

See `${CLAUDE_PLUGIN_ROOT}/docs/spec-format.md` for complete format reference.

## Pour Phase

### Convert Spec to Beads

```bash
/choo-choo-ralph:pour [target-tasks] [spec-file] [formula]
```

Examples:
- Auto-detect everything: `/choo-choo-ralph:pour`
- Target 80 tasks: `/choo-choo-ralph:pour 80`
- Specific spec and formula: `/choo-choo-ralph:pour 80 auth-system choo-choo-ralph`

### Modes

**Workflow Formula** (recommended) - Multi-step process per task:
```
bearings → implement → verify → commit
```

**Singular Tasks** - Direct execution without phases (for research, prototyping)

### What Happens

1. Tasks created as beads in `.beads/issues/`
2. Spec's `poured` array updated with bead IDs
3. Spec archived to `.choo-choo-ralph/archive/`
4. Tasks ready for Ralph

See `${CLAUDE_PLUGIN_ROOT}/docs/commands.md` for all options.

## Ralph Loop

### Running Ralph

```bash
./ralph.sh              # Default iterations
./ralph.sh 50           # Run up to 50 tasks
./ralph.sh --verbose    # Detailed output
./ralph.sh 20 -v        # 20 iterations, verbose
```

Test before a long run:
```bash
./ralph-once.sh         # Exactly one iteration
```

### How It Works

```bash
while [ $iteration -lt $MAX_ITERATIONS ]; do
    available=$(bd list --status=open --assignee=ralph --json | jq -r 'length')
    [ "$available" -eq 0 ] && exit 0

    claude --dangerously-skip-permissions --output-format stream-json -p "
      Run bd list --status=open --assignee=ralph to see available tasks.
      Pick one, claim with bd update <id> --status in_progress, then execute.
    " | ./ralph-format.sh
done
```

Key insights:
- Uses `--status=open` to filter out `in_progress` tasks
- Multiple Ralphs can run in parallel - each only sees unclaimed work
- Beads provide persistent memory per task

### Core Concepts

**Formula**: TOML template defining a workflow (steps, dependencies, prompts)
**Molecule**: Instance of a formula (actual beads with real tasks)

Default `choo-choo-ralph` formula has 4 steps:
1. **bearings** - Health check and codebase understanding
2. **implement** - Make changes
3. **verify** - Run tests/types
4. **commit** - Create git commit

**Orchestrator Pattern**: When Ralph picks up a molecule root:
1. Spawns sub-agents for each step
2. Steps execute in dependency order
3. Progress tracked via comments
4. Closes when all steps complete

### Viewing Progress

```bash
bd show <root-id>              # See molecule structure
bd ready --assignee ralph      # What's ready for work
bd blocked                     # What's waiting
bd comments <id>               # Read progress notes
bd list --status in_progress   # Currently active tasks
```

### Running Multiple Ralphs

Multiple instances run safely in parallel:

```bash
# Terminal 1
./ralph.sh

# Terminal 2
./ralph.sh
```

- Each claims work by setting `in_progress`
- Won't double-pick same task
- Need multiple ready molecules

Start with 2, scale to 3-4 if stable. Rarely need more than 4-5.

## Error Handling

Key principle: **steps report back to orchestrator, orchestrator makes state changes**.

### Verification Failures

When verify finds issues:

1. **Small fixes** → Verify fixes inline and re-verifies
2. **Significant issues** → Verify reports `STATUS: FAIL` to orchestrator
3. **Orchestrator handles rework** → Reopens implement with `[REWORK]` comment
4. **Attempt tracking** → `[attempt-N]` comments log each failure
5. **After 3 failures** → Molecule marked `[CRITICAL]` and blocked

### Health Check Failures

When bearings finds the app already broken:

1. Bearings reports `STATUS: HEALTH_CHECK_FAILED`
2. Orchestrator creates bug bead via `bug-fix` formula
3. Current molecule blocked on the bug bead
4. Once fixed, original molecule becomes ready again

### Blocked Beads

After 3 failed attempts:

1. Orchestrator blocks itself: `bd update <id> --status blocked`
2. Loop continues - blocked beads don't appear in `bd ready`
3. Other work continues unaffected

**Manual resolution:**
```bash
bd list --status=blocked       # Find blocked beads
bd comments <bead-id>          # Review what went wrong
bd update <bead-id> --status open   # Reopen for retry
# or
bd close <bead-id> --reason "Fixed manually"
```

See `${CLAUDE_PLUGIN_ROOT}/docs/troubleshooting.md` for recovery procedures.

## Harvest Phase

### Capturing Learnings

Agents capture insights as they work using comment tags:

- **[LEARNING]** - Useful discoveries (patterns, gotchas, conventions)
- **[GAP]** - Missing work or incomplete implementations

Example comments on a completed bead:
```
[bearings] This codebase uses barrel exports - import from index.ts
[implement] shadcn Button requires forwardRef when wrapping
[GAP] Missing input validation for user registration API
[summary] Completed: Add settings page. Recommendation: Consider skill for shadcn patterns.
```

### Running Harvest

```bash
/choo-choo-ralph:harvest
```

The harvest workflow:
1. Finds beads with `learnings` label (not yet `learnings-harvested`)
2. Analyzes comments for patterns and gaps
3. Creates a harvest plan for review
4. On approval, creates artifacts and marks beads `learnings-harvested`

**Artifact types:**
- **Skills** - Patterns that should auto-trigger
- **CLAUDE.md** - Critical project guidance
- **Reference docs** - Technology-specific documentation
- **Gap tasks** - New beads for approved gaps

### Labels

| Label | Meaning |
|-------|---------|
| `learnings` | Bead has recommendations worth harvesting |
| `learnings-harvested` | Learnings have been processed |
| `gaps` | Contains identified gaps |
| `gaps-harvested` | Gaps have been processed |

Query by label:
```bash
bd list --label learnings --no-label learnings-harvested
```

## Customization

All installed files are yours to modify.

### Shell Scripts

**ralph.sh customization points:**
- `MAX_ITERATIONS=100` - Default iteration limit
- The prompt passed to `claude -p` - Add project-specific guidance
- Task sorting: `--sort=priority` vs `--sort=created`

**ralph-format.sh:**
- Colors and output formatting
- What gets shown for each tool type

### Formulas

Edit `.beads/formulas/choo-choo-ralph.formula.toml`:

- Add/remove steps
- Modify step prompts
- Change assignee patterns
- Add conditional steps

**Creating custom formulas:**
```toml
formula = "quick-task"
description = """Instructions for the task..."""
version = 1

[vars]
title = ""
task = ""

[[steps]]
id = "implement"
title = "{{title}}"
assignee = "ralph-subagent-implement"
description = """Step instructions..."""
```

### Assignee Conventions

| Prefix | Execution |
|--------|-----------|
| `ralph` | Picked up by Ralph loop |
| `ralph-subagent-*` | Spawned as sub-agent |
| `ralph-inline-*` | Executed by orchestrator directly |

See `${CLAUDE_PLUGIN_ROOT}/docs/customization.md` for complete guide.
See `${CLAUDE_PLUGIN_ROOT}/docs/formulas.md` for formula reference.

## Troubleshooting

### Common Issues

**Tasks not being picked up:**
```bash
bd show <bead-id>                    # Check status and assignee
bd update <bead-id> --assignee ralph # Assign to Ralph
bd update <bead-id> --status open    # Set status
bd dep <bead-id>                     # Check for blockers
```

**Health check always failing:**
1. Stop Ralph
2. Run checks manually: `npm test`, `npm run build`, `npm run lint`
3. Fix all failures
4. Resume Ralph

**Infinite retry loop:**
```bash
bd update <bead-id> --status blocked  # Block manually
bd comments <bead-id>                 # Review all attempts
# Fix underlying issue, then:
bd update <bead-id> --status open     # Reopen when ready
```

### Recovery Procedures

**Re-pour a spec:**
1. Move spec from archive: `mv .choo-choo-ralph/archive/spec.md .choo-choo-ralph/`
2. Delete existing beads (IDs in spec's `poured` array)
3. Clear `poured: []` in frontmatter
4. Run `/choo-choo-ralph:pour`

**Session recovery (mid-task crash):**
```bash
bd list --status=in_progress --assignee=ralph  # Find in-progress task
bd comments <bead-id>                          # Review progress
bd update <bead-id> --status open              # Reopen to retry
```

### Debugging

```bash
./ralph-once.sh          # Test single iteration
./ralph.sh -v            # Verbose output
bd comments <bead-id>    # View task history
bd show <root-id>        # Inspect molecule structure
```

See `${CLAUDE_PLUGIN_ROOT}/docs/troubleshooting.md` for complete guide.

## Documentation

- **`${CLAUDE_PLUGIN_ROOT}/docs/workflow.md`** - Complete workflow guide
- **`${CLAUDE_PLUGIN_ROOT}/docs/spec-format.md`** - Spec file format reference
- **`${CLAUDE_PLUGIN_ROOT}/docs/commands.md`** - All commands with examples
- **`${CLAUDE_PLUGIN_ROOT}/docs/formulas.md`** - Formula reference and customization
- **`${CLAUDE_PLUGIN_ROOT}/docs/customization.md`** - Customizing Ralph for your project
- **`${CLAUDE_PLUGIN_ROOT}/docs/troubleshooting.md`** - Common issues and solutions

### Commands

| Command | Purpose |
|---------|---------|
| `/choo-choo-ralph:install` | Set up Ralph in project |
| `/choo-choo-ralph:spec` | Generate/refine spec from plan |
| `/choo-choo-ralph:pour` | Create beads from spec |
| `/choo-choo-ralph:harvest` | Extract learnings |
| `./ralph.sh` | Run Ralph loop |
| `./ralph-once.sh` | Run single task |
