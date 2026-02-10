---
description: Create Ralph beads from ready tasks in a spec file or conversation context
argument-hint: [target-tasks] [spec-file] [formula] 
---

# Pour into Beads

## Arguments

<arguments>
  target_tasks = $1  <!-- Optional: target number of implementation tasks -->
  spec_file = $2     <!-- Optional: spec file name or path to pour from --> 
  formula = $3       <!-- Optional: formula name to use (default: auto-detect) -->
</arguments>

Create beads from ready tasks in a spec file, or directly from conversation context.

## Spec File Resolution

When `spec_name` is provided:

- If it's a path (contains `/` or ends in `.md`): use directly
- If it's just a name: look for `.choo-choo-ralph/{spec_name}.spec.md`

When `spec_name` is NOT provided:

1. **Check for existing specs** in `.choo-choo-ralph/*.spec.md`
2. **If exactly one spec exists**: Use that spec automatically
3. **If multiple specs exist**: Ask user which spec to pour using AskUserQuestion
4. **If no specs exist**: Fall back to conversation mode

## Modes

### From Spec File (Recommended)

If spec file is found:

- Parse ready tasks (empty `<review>` tag)
- Skip tasks that need refinement (have content in `<review>` tag)
- Create one molecule per ready task
- Archive spec after pouring all tasks

### From Conversation (Quick Start)

If no spec file provided or found:

1. Extract tasks from conversation context
2. **STOP and use AskUserQuestion** - Do NOT proceed without user confirmation:

   ```
   Question: "No spec file found. How would you like to proceed with these tasks?"
   [List extracted tasks]

   Options:
   - Pour directly - Create beads immediately from these tasks
   - Create spec first (Recommended) - Run /spec for reviewable task breakdown
   - Cancel - Stop without creating anything
   ```

3. **Wait for user response** before taking any action
4. If user chooses "Pour directly": create molecules from extracted tasks
5. If user chooses "Create spec first": run `/choo-choo-ralph:spec` command
6. If user chooses "Cancel": stop and report cancellation

## Workflow Mode Selection

After determining the source (spec file or conversation), ask the user how they want to pour the tasks using **AskUserQuestion**:

```
Question: "How would you like to pour these tasks?"
Header: "Workflow"

Options:
- Use workflow formula (Recommended) - Multi-step workflow with structured phases like health checks, implementation, verification, and commit. Best for production features.
- Create singular tasks - Simple beads executed directly. Good for exploratory work, research, prototyping, or one-off tasks.
```

**If "Use workflow formula"**: Proceed to Formula Selection below.

**If "Create singular tasks"**: Skip Formula Selection entirely and go straight to task breakdown. Tasks will be created with `bd create` instead of `bd mol pour`.

## Formula Selection

**Note:** This section only applies when "Use workflow formula" is chosen above.

1. If `formula` provided, use that formula
2. Otherwise, run `bd formula list`:
   - If only one formula exists, use it automatically
   - If multiple formulas exist, ask user to choose

## Task Granularity (CRITICAL)

**Spec tasks are NOT implementation tasks.** Each spec task must be broken down into multiple granular implementation tasks (molecules).

### The Breakdown Process

1. **Spec tasks** = High-level features/capabilities from the spec
2. **Implementation tasks** = Granular, atomic units of work (molecules)
3. **Formula steps** = Workflow phases within each task (bearings, implement, verify, commit) - these are NOT counted toward task granularity

**Example:**

- Spec has 10 high-level tasks
- Each spec task breaks down into 5-10 implementation tasks
- Target: 50-100 implementation tasks (molecules)
- Formula steps (6 per molecule) are internal workflow, NOT part of task count

### Target Implementation Tasks

If `target_tasks` is provided (e.g., 80):

- This is the target number of **implementation tasks (molecules)**, NOT spec tasks
- Break down spec tasks to reach this target
- A spec with 10 tasks targeting 80 molecules = ~8 implementation tasks per spec task

### Default Targets (Guidance)

If `target_tasks` is NOT provided, use these defaults:

| Project Type     | Target Molecules | Breakdown Ratio     |
| ---------------- | ---------------- | ------------------- |
| Single feature   | 15-30 tasks      | ~5-10 per spec task |
| Feature set      | 50-100 tasks     | ~5-8 per spec task  |
| Full application | 150-300 tasks    | ~5-10 per spec task |

### What Makes a Good Implementation Task

Each implementation task (molecule) should be a **coherent slice of work**:

- **Cohesive**: All changes belong together logically (e.g., frontend + backend for one feature slice is fine)
- **Testable together**: Can be verified as a unit - the changes make sense to test together
- **Complete slice**: Delivers a piece of functionality, not just a layer or file change
- **Reasonable scope**: Not so big it's hard to review, not so small it's wasteful

**TOO GRANULAR (bad):**

- "Install package X" then "Install package Y" then "Install package Z" as separate tasks
- "Update users.ts" then "Update users.test.ts" then "Update users.types.ts" as separate tasks
- Breaking apart changes that only make sense together

**TOO COARSE (bad):**

- "Build entire authentication system" (frontend + backend + infrastructure + tests all in one)
- Combining unrelated features into one task
- Tasks that would take hours to review

**JUST RIGHT:**

- "Add login form with validation" - includes component, styles, validation logic, tested together
- "Implement login API endpoint" - includes route, controller, validation, tests for that endpoint
- "Add password reset flow" - frontend + backend for this specific slice, can be tested end-to-end

**Key question:** Can this slice be implemented, committed, and tested as one coherent unit? If yes, it's the right size.

## Test Step Generation

When pouring spec tasks into beads, **generate granular test steps** for each bead:

- **Spec-level test steps** = Integration guidance (kept for reference)
- **Bead-level test steps** = Specific verification for this task (generated)

### Test Step Complexity (Important)

Use a **mix of test step complexity** based on the task:

| Task Type        | Test Steps | Examples                                         |
| ---------------- | ---------- | ------------------------------------------------ |
| Simple/focused   | 2-5 steps  | Button styling, color theme, simple validation   |
| Standard feature | 5-8 steps  | Form component, API endpoint, data display       |
| Complex workflow | 10+ steps  | Multi-step flows, auth flows, payment processing |

**Guideline**: At least 20% of tasks should have 10+ test steps (the complex ones need thorough verification).

For each bead created, include test steps that:

1. Are specific to what this bead implements
2. Can be verified independently
3. Include expected outcomes
4. Match complexity to task importance

**Example transformation:**

Spec task "User Authentication" with integration test steps might pour into:

- Bead: "Create login form component" → test steps for form rendering, input fields, button state
- Bead: "Add form validation" → test steps for email format, password requirements, error messages
- Bead: "Implement auth API endpoint" → test steps for successful login, invalid credentials, session creation

## Process

1. **Determine source**: Spec file or conversation
2. **Select workflow mode**: Ask user (see "Workflow Mode Selection" above):
   - If "Use workflow formula": proceed to step 3
   - If "Create singular tasks": skip to step 4 (no formula needed)
3. **Select formula** (workflow formula mode only): Use provided, auto-select, or prompt (see "Formula Selection" above)
4. **Parse spec tasks**: Extract high-level tasks from source
5. **Break down into implementation tasks** (CRITICAL):
   - Each spec task → multiple granular implementation tasks
   - Target 5-10 implementation tasks per spec task
   - Each implementation task = one molecule (or singular task)
   - See "Task Granularity" section above for guidance
6. **Read spec frontmatter variables** (workflow formula mode only): Extract optional fields for formula variables:
   - `auto_discovery` (default: `false`) - Enable auto task creation from gaps
   - `auto_learnings` (default: `false`) - Enable auto skill creation from learnings
7. **Generate test steps**: Create granular test steps for each implementation task (see Test Step Complexity above)
8. **Confirm with user** (AskUserQuestion):

   Present a summary and let user choose. The summary differs based on workflow mode:

   **For workflow formula mode:**
   ```
   "Ready to pour tasks from spec."

   Spec tasks: 27
   Implementation tasks: ~135 (after breakdown)
   Formula: choo-choo-ralph (6 workflow steps each)

   Options:
   - Pour all tasks (Recommended) - Proceed with pouring
   - Show task overview first - Review all tasks before pouring
   - Cancel - Stop without pouring
   ```

   **For singular task mode:**
   ```
   "Ready to pour singular tasks from spec."

   Spec tasks: 27
   Implementation tasks: ~135 (after breakdown)
   Mode: Singular tasks (direct execution, no workflow steps)

   Options:
   - Pour all tasks (Recommended) - Proceed with pouring
   - Show task overview first - Review all tasks before pouring
   - Cancel - Stop without pouring
   ```

   **If "Show task overview first":**

   - Save full breakdown to `.choo-choo-ralph/pour-preview.md`
   - Include: task title, description snippet, category, priority, test step count
   - Tell user: "Overview saved to .choo-choo-ralph/pour-preview.md - review and run /pour again when ready"
   - Exit without pouring

   **If "Cancel":** Exit without pouring

   **If "Pour all tasks":** Continue to step 9

9. **Pour tasks using sub-agents** (for context preservation and speed):

   - Group implementation tasks into batches of 10-15 tasks
   - Launch 5-10 sub-agents in parallel, each handling one batch
   - Each sub-agent runs the pour commands for its batch
   - This keeps context lean and speeds up the pour process

   > **⚠️ CRITICAL: Assignee Requirement**
   >
   > ALL poured tasks MUST include `--assignee ralph`. When instructing sub-agents, you MUST:
   > 1. Include the **exact command** with `--assignee ralph` in the sub-agent prompt
   > 2. Do NOT paraphrase or summarize the command - copy it exactly
   > 3. The sub-agent does NOT have access to this file - it only knows what you tell it
   >
   > If tasks are created without `--assignee ralph`, they won't be picked up by the Ralph loop.

   **For workflow formula mode**, each sub-agent runs:

   ```bash
   bd --no-daemon mol pour <FORMULA_NAME> \
     --var title="<TASK_TITLE>" \
     --var task="<TASK_DESCRIPTION>" \
     --var category="<TASK_CATEGORY>" \
     --var auto_discovery="<SPEC_AUTO_DISCOVERY>" \
     --var auto_learnings="<SPEC_AUTO_LEARNINGS>" \
     --assignee ralph
   ```

   **Placeholder notation:** `<PLACEHOLDER>` values are filled in by YOU (the agent) before running the command. These are NOT processed by beads - you must substitute them with actual values. In contrast, `{{variable}}` in formula files IS processed by beads templating.

   Notes for formula mode:

   - Use `bd mol pour` (not `bd formula pour`)
   - Use `--var` for variables (not `--set`)
   - `<TASK_DESCRIPTION>` should include the generated test steps appended to the description
   - `<TASK_CATEGORY>` comes from the spec task's category attribute
   - `<SPEC_AUTO_DISCOVERY>` and `<SPEC_AUTO_LEARNINGS>` come from spec frontmatter (default to `false`)
   - **Capture the root bead ID** from each `bd mol pour` output for the poured array

   **For singular task mode**, each sub-agent runs:

   ```bash
   bd --no-daemon create "<TASK_TITLE>" \
     --description "<TASK_DESCRIPTION_WITH_TEMPLATE>" \
     --assignee ralph \
     --labels "<TASK_CATEGORY>"
   ```

   **Important:** `bd create` does NOT perform any template substitution. The `<PLACEHOLDER>` values must be filled in by YOU before running the command. Whatever string you pass to `--description` is stored exactly as-is.

   **How to construct `<TASK_DESCRIPTION_WITH_TEMPLATE>`:**
   1. Copy the **Singular Task Description Template** structure below
   2. Replace `<TASK_DESCRIPTION>` with the actual task description
   3. Replace `<TASK_TEST_STEPS>` with the generated test steps for this task
   4. Pass the entire constructed string to `--description`

   Notes for singular task mode:

   - Use `bd create` (not `bd mol pour`)
   - **Capture the bead ID** from output for the poured array

   ### Singular Task Description Template

   For singular tasks, wrap the task description with execution instructions. Fill in `<TASK_DESCRIPTION>` and `<TASK_TEST_STEPS>` with actual content before creating:

   ```markdown
   ## Task
   <TASK_DESCRIPTION>

   ## Test Steps
   <TASK_TEST_STEPS>

   ## Execution
   Execute this task directly. When complete:
   1. Add a summary comment: `bd comments add <your-id> "[summary] <what was done>"`
   2. Close the bead: `bd close <your-id>`

   ## Capturing Gaps
   If you discover missing work that's clearly needed:
   ```bash
   bd comments add <your-id> "[GAP] <title> - <description>"
   ```

   ## Capturing Learnings
   If you encounter something noteworthy:
   ```bash
   bd comments add <your-id> "[LEARNING] <description>"
   ```
   ```

10. **Set priority on each root bead**:
    - After pouring, update each bead with its priority from the spec task
    - Run: `bd update <bead-id> --priority <TASK_PRIORITY>`
    - Priority values: 0-4 (0=critical, 1=high, 2=medium, 3=low, 4=backlog)
11. **Verify assignees** (REQUIRED):
    - After all sub-agents complete, verify that the poured tasks have the correct assignee
    - For each bead ID captured in step 9, run: `bd show <bead-id>` and check the Assignee field
    - If any poured tasks are missing the assignee, fix them immediately:
      ```bash
      bd update <bead-id> --assignee ralph
      ```
    - Report verification results to user: "Verified N tasks assigned to ralph (fixed M)"
12. **Update spec frontmatter**: After all tasks are poured successfully, update the spec's YAML frontmatter `poured` array with the created bead IDs (see below)
13. **Archive spec**: Move spec to archive folder after all tasks poured (see below)

## Error Recovery

If `bd mol pour` or `bd create` fails mid-way through multiple tasks:

1. **Identify failed task**: Note which task failed and the error message
2. **Rollback partial state**: Delete any orphaned beads created for the failed task: `bd delete <partial-bead-id>`
3. **Report to user**:
   - List successfully poured tasks
   - Identify the failed task and error
   - Suggest fix or ask user for guidance
4. **Resume option**: User fixes the issue, then runs pour again (will re-pour all tasks since spec wasn't archived)

## Updating Spec Frontmatter

After all tasks are poured successfully, update the spec's YAML frontmatter with the bead IDs:

1. **Collect bead IDs** from each `bd mol pour` or `bd create` command output
2. **Update the `poured` array** in the frontmatter with all collected IDs

**Example before pour:**

```yaml
---
title: "User Authentication"
created: 2026-01-11
poured: []
---
```

**Example after pour:**

```yaml
---
title: "User Authentication"
created: 2026-01-11
poured:
  - proj-abc
  - proj-def
  - proj-ghi
---
```

This provides traceability from spec to beads, and allows querying which specs have been poured.

## Spec Archiving

After successfully pouring **all ready tasks** from a spec:

1. **Create archive directory** if it doesn't exist: `.choo-choo-ralph/archive/`
2. **Move the spec file** to archive:
   - From: `.choo-choo-ralph/my-feature.spec.md`
   - To: `.choo-choo-ralph/archive/my-feature.spec.md`
3. **Report**: "Spec archived to .choo-choo-ralph/archive/my-feature.spec.md"

**When NOT to archive:**

- If pour failed mid-way (spec stays in place for retry)
- If some tasks still need refinement (have content in `<review>` tags)
- If pouring from conversation (no spec file to archive)

The archived spec serves as a record of what was planned and poured, with bead IDs for traceability.

## Handling Review Comments

If any tasks have content in `<review>` tags, use **AskUserQuestion** to let the user decide:

```
"Some tasks have review comments that haven't been processed."

Options:
- Run /spec first (Recommended) - Process review feedback before pouring
- Ignore and pour all - Pour tasks as-is, ignoring review comments
- Cancel - Stop and let me review the spec manually
```

**If user chooses "Run /spec first":**

- Run the spec command to process review feedback
- After spec completes, continue with pour

**If user chooses "Ignore and pour all":**

- Clear all review tags (treat as empty)
- Pour all tasks
- Archive spec

**If user chooses "Cancel":**

- Report spec location for manual review
- Exit without pouring

## Output

Summary differs based on workflow mode:

**For workflow formula mode:**

- N tasks poured using <FORMULA_NAME> formula
- Root bead IDs for each
- Total beads created (tasks × formula steps)
- Command to start: `./ralph.sh`

**For singular task mode:**

- N singular tasks created
- Bead IDs for each
- Command to start: `./ralph.sh`
