# Commands Reference

Complete reference for all Choo Choo Ralph commands with options and examples.

## /choo-choo-ralph:install

Set up Choo Choo Ralph in your project by copying local, customizable files. These files are yours to modify—see [Customization Guide](./customization.md) for details.

### Usage

```
/choo-choo-ralph:install
```

### What It Does

1. **Checks prerequisites** - Verifies bd (beads), claude, and jq are installed
2. **Initializes beads** - Runs `bd init` if .beads directory doesn't exist
3. **Copies shell scripts** - ralph.sh, ralph-once.sh, ralph-format.sh to project root
4. **Copies formulas** - choo-choo-ralph and bug-fix formula templates to `.beads/formulas/`
5. **Creates spec directory** - .choo-choo-ralph/ for spec files

### Files Created

| File | Purpose |
|------|---------|
| `./ralph.sh` | Main loop script - runs tasks until done or limit reached |
| `./ralph-once.sh` | Single task script - test one iteration before a long run |
| `./ralph-format.sh` | Output formatting - controls how Ralph's progress displays |
| `.beads/formulas/choo-choo-ralph.formula.toml` | Standard workflow formula (bearings → implement → verify → commit) |
| `.beads/formulas/bug-fix.formula.toml` | Bug fix workflow formula (diagnose → fix → verify → commit) |
| `.choo-choo-ralph/` | Directory for spec files |

All these files are yours to modify. See [Customization Guide](./customization.md) for details on what you can change.

---

## /choo-choo-ralph:spec

Generate or refine a spec file from a plan or conversation context.

### Usage

```
/choo-choo-ralph:spec [source-file] [spec-name]
```

### Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `source-file` | No | Conversation context | Path to plan file (markdown, text) |
| `spec-name` | No | Auto-detected from content | Name for the spec file |

### Modes

The command operates in three modes based on current state:

1. **No spec exists** - Generate new spec from plan file or conversation
2. **Spec has review comments** - Refine spec based on your feedback
3. **Spec exists, no comments** - Prompts: regenerate or continue to pour?

### Examples

**Generate from plan file:**
```
/choo-choo-ralph:spec docs/feature-plan.md auth-system
```

**Auto-detect spec name from conversation:**
```
/choo-choo-ralph:spec
```
After discussing a feature, the spec name is inferred from context.

**Work with existing spec:**
```
/choo-choo-ralph:spec
```
If `.choo-choo-ralph/auth-system.spec.md` exists, offers to refine or regenerate.

**Refine after review:**
```
# Add feedback in <review> tags, then:
/choo-choo-ralph:spec
```
Tasks with content in `<review>` tags trigger refinement mode.

---

## /choo-choo-ralph:pour

Convert spec tasks into beads (issues) for Ralph to work on.

### Usage

```
/choo-choo-ralph:pour [target-tasks] [spec-file] [formula]
```

### Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `target-tasks` | No | Project-size based | Number of tasks to create |
| `spec-file` | No | Most recent spec | Path to spec file |
| `formula` | No | Interactive prompt | Formula to use (choo-choo-ralph, bug-fix) |

### Interactive Prompts

1. **Mode Selection** - Create all tasks or incremental batch
2. **Formula Selection** - Choose workflow formula (if not specified)
3. **Confirmation** - One of:
   - "Pour all tasks" - Create beads immediately
   - "Show task overview first" - Write preview to `.choo-choo-ralph/pour-preview.md` for review
   - "Cancel" - Exit without creating beads

The preview option is useful for reviewing how spec tasks will be granularized before committing. If the breakdown doesn't look right, refine your spec and try again.

### Default Task Targets

| Project Type | Target Tasks | Breakdown Ratio |
|--------------|--------------|-----------------|
| Small feature | 3-5 tasks | 1 spec item → 1 task |
| Medium feature | 5-10 tasks | 1 spec item → 1-2 tasks |
| Large feature | 10-15 tasks | 1 spec item → 2-3 tasks |

### Examples

**Pour all tasks from current spec:**
```
/choo-choo-ralph:pour
```

**Pour specific number of tasks:**
```
/choo-choo-ralph:pour 5
```

**Pour from specific spec with formula:**
```
/choo-choo-ralph:pour 8 .choo-choo-ralph/auth-system.spec.md choo-choo-ralph
```

**Pour using bug-fix formula:**
```
/choo-choo-ralph:pour 3 .choo-choo-ralph/fixes.spec.md bug-fix
```

---

## /choo-choo-ralph:harvest

Extract learnings from completed tasks into documentation, skills, or CLAUDE.md.

### Usage

```
/choo-choo-ralph:harvest
```

### Modes

1. **No harvest plan exists** - Analyzes completed tasks and creates harvest plan
2. **Plan has review comments** - Refines plan based on your feedback
3. **Plan exists, no comments** - Prompts: execute harvest or regenerate?

### What It Creates

| Output Type | Description |
|-------------|-------------|
| **Skills** | New skill files for reusable patterns discovered |
| **CLAUDE.md updates** | Project-specific guidance additions |
| **Reference docs** | Documentation for complex implementations |
| **Gap tasks** | New beads for approved documentation gaps |

### Harvest Workflow

1. Run `/choo-choo-ralph:harvest`
2. Review generated harvest plan
3. Add comments for refinement (optional)
4. Run again to refine or execute
5. Approve outputs to apply changes

---

## BD Commands Reference

Useful beads (bd) commands for working with Ralph workflows.

### View Tasks

**List ready tasks assigned to Ralph:**
```bash
bd ready --assignee ralph
```

**Show detailed task information:**
```bash
bd show <bead-id>
```

**View task comments and history:**
```bash
bd comments <bead-id>
```

**List all open Ralph tasks:**
```bash
bd list --status=open --assignee=ralph
```

**List blocked tasks:**
```bash
bd list --status=blocked
```

**List tasks by priority:**
```bash
bd list --status=open --sort=priority
```

### Manual Intervention

**Reopen a task:**
```bash
bd update <bead-id> --status open
```

**Mark task as blocked:**
```bash
bd update <bead-id> --status blocked
```

**Close a task manually:**
```bash
bd close <bead-id> --reason "Completed manually"
```

**Reassign a task:**
```bash
bd update <bead-id> --assignee someone-else
```

**Update task priority:**
```bash
bd update <bead-id> --priority high
```

### Formulas

**List available formulas:**
```bash
bd formula list
```

**Create task manually with formula:**
```bash
bd mol pour choo-choo-ralph \
  --var title="Implement user auth" \
  --var task="Add JWT authentication to API endpoints" \
  --assignee ralph
```

**Create bug fix task:**
```bash
bd mol pour bug-fix \
  --var title="Fix login redirect" \
  --var task="Users not redirected after login" \
  --var context="Happens on mobile browsers" \
  --assignee ralph
```

### Dependencies

**Add dependency between tasks:**
```bash
bd dep add <bead-id> --blocks <other-bead-id>
```

**Remove dependency:**
```bash
bd dep remove <bead-id> --blocks <other-bead-id>
```

**View task dependencies:**
```bash
bd show <bead-id> --deps
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/choo-choo-ralph:install` | Set up Ralph in project |
| `/choo-choo-ralph:spec` | Generate/refine spec file |
| `/choo-choo-ralph:pour` | Create beads from spec |
| `/choo-choo-ralph:harvest` | Extract learnings |
| `./ralph.sh` | Run Ralph loop |
| `./ralph-once.sh` | Run single task |
| `bd ready --assignee ralph` | See queued tasks |
| `bd show <id>` | View task details |
