# Troubleshooting

This guide covers error handling, debugging techniques, and recovery procedures for Choo Choo Ralph workflows.

## Automatic Error Handling

Ralph handles most failures automatically through built-in retry and recovery mechanisms.

### Verification Failures

When the verify step fails after implementation:

1. **Implement step reopened** with `[REWORK]` guidance explaining what failed
2. **`[attempt-N]` comment** tracks the retry count for the task
3. **After 3 failures** → task automatically marked as blocked

Example verification failure flow:
```
Iteration 1: Implement → Verify fails → Reopen with [REWORK]
Iteration 2: Re-implement → Verify fails → [attempt-2] comment added
Iteration 3: Re-implement → Verify fails → [attempt-3] → Task BLOCKED
```

The `[REWORK]` comment includes:
- What specifically failed verification
- Error messages or test output
- Suggestions for fixing the issue

### Health Check Failures

When bearings detects a broken codebase state:

1. **Bug-fix bead created automatically** describing the detected issue
2. **Current task blocked** on the new bug-fix bead
3. **Bug must be fixed first** before Ralph continues

This prevents Ralph from building on a broken foundation. Common health check failures:
- Tests failing that were passing before
- Build errors introduced
- Linting violations
- Type errors

## Blocked Tasks

### Viewing Blocked Tasks

List all blocked tasks:
```bash
bd list --status=blocked
```

Or use the dedicated command:
```bash
bd blocked
```

### Understanding What Went Wrong

Review the task's comment history:
```bash
bd comments <bead-id>
```

Look for:
- `[attempt-3]` comments indicating max retries reached
- `[CRITICAL]` markers for severe issues
- Error messages and stack traces
- `[REWORK]` guidance from previous attempts

### Unblocking Tasks

To unblock a task and let Ralph retry:

1. **Fix the underlying issue manually** (update code, fix tests, etc.)
2. **Reopen the task**:
   ```bash
   bd update <bead-id> --status open
   ```
3. **Ralph will pick it up** on the next iteration

If the task has dependencies that are also blocked, fix those first.

## Common Issues

### Tasks Not Being Picked Up

**Symptom:** Ralph says "no ready tasks" but tasks exist in the system

**Possible causes:**
- Task not assigned to Ralph
- Task status is not "open"
- Task has unresolved blockers (dependencies)
- Task is part of a different molecule

**Fixes:**
```bash
# Check task details
bd show <bead-id>

# Assign to Ralph
bd update <bead-id> --assignee ralph

# Set status to open
bd update <bead-id> --status open

# Check for blockers
bd dep <bead-id>
```

### Infinite Retry Loop

**Symptom:** Task keeps failing verification but never gets blocked (or reaches blocked state repeatedly)

**Cause:** Fundamental issue that the agent cannot fix within its capabilities

**Fix:**
1. Block the task manually:
   ```bash
   bd update <bead-id> --status blocked
   ```
2. Review all comments for patterns:
   ```bash
   bd comments <bead-id>
   ```
3. Fix the underlying issue yourself
4. Reopen when ready:
   ```bash
   bd update <bead-id> --status open
   ```

### Health Check Always Failing

**Symptom:** Every task iteration creates a bug-fix bead

**Possible causes:**
- Test suite is fundamentally broken
- Dev server not running (if required)
- Environment configuration issues
- Missing dependencies
- Database not seeded

**Fix:**
1. Stop Ralph immediately
2. Run health checks manually:
   ```bash
   npm test        # or your test command
   npm run build   # or your build command
   npm run lint    # or your lint command
   ```
3. Fix all failing checks
4. Verify everything passes
5. Resume Ralph

### Pour Creates Duplicate Tasks

**Symptom:** Running pour multiple times creates duplicate beads

**Cause:** The `poured` array in spec frontmatter wasn't updated, or spec was modified after pour

**Fix:**
- Check the spec's frontmatter for the `poured` array
- Delete duplicates manually
- Ensure spec is archived after successful pour

### Wrong Task Order

**Symptom:** Tasks are being worked in unexpected order

**Cause:** Dependencies not set correctly during pour, or manual dependency changes

**Fix:**
```bash
# View dependency graph
bd dep <molecule-id>

# Add missing dependency
bd dep add <dependent-id> <dependency-id>

# Remove incorrect dependency
bd dep remove <dependent-id> <dependency-id>
```

## Debugging Tips

### Run Single Iteration

Test Ralph behavior without committing to a full loop:
```bash
./ralph-once.sh
```

This runs exactly one iteration and stops, letting you inspect results.

### Use Verbose Mode

Get detailed output about what Ralph is doing:
```bash
./ralph.sh -v
```

Or set in your environment:
```bash
export RALPH_VERBOSE=1
./ralph.sh
```

### Check Task History

View all comments and state changes:
```bash
bd comments <bead-id>
```

### Inspect Molecule Structure

See the full dependency tree:
```bash
bd show <root-id>
```

Or visualize dependencies:
```bash
bd dep <molecule-id>
```

### Check Spec Status

View archived specs and their pour status:
```bash
ls -la .choo-choo-ralph/archive/
```

Read a spec's frontmatter to see poured beads:
```bash
head -50 .choo-choo-ralph/archive/my-feature.spec.md
```

## Recovery Procedures

### Partially Completed Pour

If pour fails mid-way through creating beads:

**State after failure:**
- Spec is NOT archived (still in `.choo-choo-ralph/`)
- Some beads may have been created
- Dependency links may be incomplete

**Recovery:**
1. Check which beads were created:
   ```bash
   bd list --assignee=ralph
   ```
2. Fix the issue that caused pour to fail
3. Run pour again:
   ```bash
   /choo-choo-ralph:pour
   ```

Pour is idempotent - it tracks created beads in the `poured` array and won't duplicate them.

### Corrupted State

If beads are in an inconsistent state:

1. List all Ralph-assigned beads:
   ```bash
   bd list --assignee=ralph
   ```

2. Delete problematic beads:
   ```bash
   bd delete <bead-id>
   ```

3. Re-pour from the spec:
   ```bash
   /choo-choo-ralph:pour
   ```

### Starting Over (Re-pouring a Spec)

To completely redo a feature from its spec:

**Step 1: Unarchive the spec**
```bash
mv .choo-choo-ralph/archive/my-feature.spec.md .choo-choo-ralph/
```

**Step 2: Delete existing beads**

The spec's frontmatter contains a `poured` array listing all created bead IDs. Ask a coding agent to read the spec and delete these beads:
```bash
bd delete <bead-id-1>
bd delete <bead-id-2>
# ... for each bead in the poured array
```

**Step 3: Clear the poured array**

Edit the spec's frontmatter to reset the `poured` array:
```yaml
---
poured: []
---
```

**Step 4: Re-pour**
```bash
/choo-choo-ralph:pour
```

**Note:** If the original plan no longer exists, the archived spec still contains all task definitions and can be re-poured.

### Recovering from Git Issues

If Ralph's commits cause problems:

1. Stop Ralph
2. Use git to revert or reset as needed:
   ```bash
   git log --oneline -20  # Find the bad commits
   git revert <commit>    # Revert specific commits
   ```
3. Update task status to match current state
4. Resume Ralph

### Session Recovery

If a Claude Code session ends unexpectedly mid-task:

1. Check what task was in progress:
   ```bash
   bd list --status=in_progress --assignee=ralph
   ```
2. Review the task's last comments:
   ```bash
   bd comments <bead-id>
   ```
3. Either:
   - Mark complete if work was finished
   - Reopen if work needs to continue
   - Block if the interruption caused issues

## Getting Help

If you encounter issues not covered here:

1. Check the task comments for specific error messages
2. Review the spec file for task definitions
3. Inspect the molecule structure for dependency issues
4. Run in verbose mode to see detailed execution flow
