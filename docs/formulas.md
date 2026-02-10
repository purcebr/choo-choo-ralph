# Formula Reference and Customization

## Overview

Formulas are TOML templates that define multi-step workflows for Ralph to execute. They provide a declarative way to describe complex tasks as a series of dependent steps, each with its own assignee and instructions.

Formulas live in `.beads/formulas/` within your project directory. When you "pour" a formula, it creates a set of beads (tasks) based on the formula's step definitions, with dependencies automatically wired up.

Key concepts:

- **Formula**: A TOML template defining a workflow
- **Step**: An individual task within the workflow
- **Variables**: Placeholders substituted when pouring (e.g., `{{title}}`, `{{task}}`)
- **Dependencies**: Steps can depend on other steps via the `needs` array

## Built-in Formulas

Choo Choo Ralph ships with two built-in formulas for common development workflows.

### choo-choo-ralph

The standard feature implementation workflow. Use this for new features, enhancements, and general development tasks.

**Steps:**

1. **bearings** - Health check and codebase understanding

   - Run tests to verify starting state
   - Explore relevant code paths
   - Understand existing patterns and conventions
   - Document findings for subsequent steps

2. **implement** - Make the actual changes

   - Follow patterns discovered in bearings
   - Write clean, idiomatic code
   - Add appropriate comments and documentation
   - Depends on: `bearings`

3. **verify** - Validate the implementation

   - Run test suite and fix any failures
   - Check type errors (TypeScript, mypy, etc.)
   - Verify UI behavior if applicable
   - Ensure no regressions
   - Depends on: `implement`

4. **commit** - Create the commit
   - Stage relevant changes
   - Write descriptive commit message
   - Depends on: `verify`

**Conditional Steps:**

- **gap-review** - Reviews implementation for missing work (when `auto_discovery=true`)
- **learning-capture** - Captures learnings and gaps discovered (when `auto_learnings=true`)

### bug-fix

A streamlined workflow for diagnosing and fixing bugs.

**Steps:**

1. **diagnose** - Reproduce and understand the bug

   - Reproduce the issue
   - Find the root cause
   - Document the fix approach

2. **fix** - Make the minimal fix

   - Apply targeted changes
   - Avoid scope creep
   - Depends on: `diagnose`

3. **verify** - Confirm the fix works

   - Verify bug is resolved
   - Run tests to prevent regressions
   - Depends on: `fix`

4. **commit** - Create the commit
   - Stage changes
   - Write commit message referencing the bug
   - Depends on: `verify`

## Assignee Conventions

Assignees determine how Ralph handles each step. The prefix indicates execution mode:

| Prefix             | Meaning           | Example                    | Execution                      |
| ------------------ | ----------------- | -------------------------- | ------------------------------ |
| `ralph`            | Root molecule     | `ralph`                    | Picked up by Ralph loop        |
| `ralph-subagent-*` | Spawned sub-agent | `ralph-subagent-implement` | Ralph spawns a new agent       |
| `ralph-inline-*`   | Inline execution  | `ralph-inline-commit`      | Orchestrator executes directly |

**When to use each:**

- **`ralph`**: Top-level tasks that Ralph should pick up and orchestrate
- **`ralph-subagent-*`**: Complex steps requiring focused attention (implementation, diagnosis)
- **`ralph-inline-*`**: Simple, quick steps (commits, status updates)

The distinction between subagent and inline affects resource usage and context isolation:

- Subagents get fresh context and can work independently
- Inline steps share the orchestrator's context and are faster

## Creating Custom Formulas

### Basic Structure

Create a new `.toml` file in `.beads/formulas/`. Here's a complete example:

```toml
name = "code-review"
description = """
You are orchestrating a code review workflow.

Review the changes in the specified PR or branch, checking for:
- Code quality and adherence to project conventions
- Potential bugs or edge cases
- Test coverage
- Documentation completeness

Coordinate the review steps and compile final feedback.
"""
version = "1.0.0"

[vars]
branch = ""
focus_areas = "general"

[[steps]]
id = "analyze"
title = "Analyze changes in {{branch}}"
assignee = "ralph-subagent-analyze"
description = """
Analyze the code changes in branch {{branch}}.

Focus areas: {{focus_areas}}

1. List all modified files
2. Understand the purpose of changes
3. Note any concerning patterns
"""

[[steps]]
id = "review"
title = "Deep review of {{branch}}"
assignee = "ralph-subagent-review"
needs = ["analyze"]
description = """
Perform detailed code review based on analysis.

Check for:
- Logic errors
- Edge cases
- Performance issues
- Security concerns
"""

[[steps]]
id = "summarize"
title = "Compile review feedback"
assignee = "ralph-inline-summarize"
needs = ["review"]
description = """
Compile all findings into actionable feedback.
Add comments to the root bead with recommendations.
"""
```

### Formula Fields

| Field         | Required | Description                                 |
| ------------- | -------- | ------------------------------------------- |
| `name`        | Yes      | Unique identifier for the formula           |
| `description` | Yes      | Orchestrator prompt explaining the workflow |
| `version`     | No       | Semantic version for tracking changes       |
| `[vars]`      | No       | Default values for template variables       |
| `[[steps]]`   | Yes      | Array of step definitions                   |

### Step Fields

| Field         | Required | Description                                           |
| ------------- | -------- | ----------------------------------------------------- |
| `id`          | Yes      | Unique step identifier (used in `needs`)              |
| `title`       | Yes      | Human-readable title (supports variables)             |
| `assignee`    | Yes      | Who executes this step                                |
| `description` | Yes      | Detailed instructions (supports variables)            |
| `needs`       | No       | Array of step IDs that must complete first            |
| `condition`   | No       | Expression that must be truthy for bead to be created |

### Variables

Variables are placeholders that get substituted when pouring a formula. Define defaults in `[vars]` and use them with double braces:

```toml
[vars]
title = ""
task = ""
category = "feature"
priority = "medium"

[[steps]]
id = "implement"
title = "{{title}}"
description = """
Implement: {{task}}

Category: {{category}}
Priority: {{priority}}
"""
```

When pouring, pass values with `--var`:

```bash
bd mol pour my-formula \
  --var title="Add dark mode" \
  --var task="Implement theme toggle" \
  --var category="ui" \
  --assignee ralph
```

### Step Dependencies

Use the `needs` array to specify execution order. Steps only become ready when all dependencies are complete:

```toml
[[steps]]
id = "step-a"
title = "First step"
assignee = "ralph-subagent-a"
description = "This runs first"

[[steps]]
id = "step-b"
title = "Second step"
assignee = "ralph-subagent-b"
needs = ["step-a"]
description = "This waits for step-a"

[[steps]]
id = "step-c"
title = "Third step"
assignee = "ralph-subagent-c"
needs = ["step-a", "step-b"]
description = "This waits for both a and b"
```

### Conditional Steps

Conditions control whether a bead is **created** for a step when the formula is poured. If the condition is falsy, no bead is created for that step.

```toml
[vars]
auto_discovery = "false"
run_e2e = "false"

[[steps]]
id = "gap-review"
title = "Review for gaps"
assignee = "ralph-subagent-gaps"
condition = "{{auto_discovery}}"
needs = ["implement"]
description = "Check for missing work..."

[[steps]]
id = "e2e-tests"
title = "Run E2E tests"
assignee = "ralph-subagent-e2e"
condition = "{{run_e2e}}"
needs = ["verify"]
description = "Run end-to-end test suite..."
```

Conditions are evaluated at pour time as truthy/falsy:

- `"true"`, `"yes"`, `"1"` → bead created
- `"false"`, `"no"`, `"0"`, `""` → bead not created

## Testing Your Formula

After creating a formula, verify it works correctly:

```bash
# 1. Check the formula is registered
bd formula list

# 2. Pour a test instance
bd mol pour my-formula \
  --var title="Test task" \
  --var task="Verify formula works" \
  --assignee ralph

# 3. Verify tasks were created
bd ready --assignee ralph

# 4. Check dependencies are correct
bd list --assignee ralph-subagent-*
bd show <bead-id>  # Check 'needs' field
```

Common issues:

- **Formula not listed**: Check file is in `.beads/formulas/` with `.toml` extension
- **Variables not substituted**: Ensure variable names match exactly (case-sensitive)
- **Steps not created**: Check for TOML syntax errors

## Adding Learning Capture

To capture learnings and gaps during workflow execution, add instructions to your step descriptions:

```toml
[[steps]]
id = "implement"
title = "Implement {{title}}"
assignee = "ralph-subagent-implement"
needs = ["bearings"]
description = """
Implement the feature: {{task}}

Follow patterns established in the codebase.
Write clean, well-tested code.

## Capturing Learnings

If you discover something noteworthy about this codebase:
- A useful pattern or convention
- A gotcha that others should know
- A tool or technique that worked well

Add a comment to the root bead:
```

bd comments add {{root_bead_id}} "[LEARNING] <description>"

```

## Capturing Gaps

If you find work that should be done but is out of scope:
- Missing tests
- Technical debt to address
- Related features to consider

Add a comment to the root bead:
```

bd comments add {{root_bead_id}} "[GAP] <title> - <description>"

```
"""
```

Learnings and gaps can later be harvested using `/choo-choo-ralph:harvest`.

## Labels Used by Ralph

Ralph uses labels to categorize and track tasks:

| Label                 | Meaning                                    |
| --------------------- | ------------------------------------------ |
| `ralph-step`          | Task is part of a Ralph workflow           |
| `bearings`            | Health check / codebase understanding step |
| `implement`           | Implementation step                        |
| `verify`              | Verification / testing step                |
| `commit`              | Commit creation step                       |
| `diagnose`            | Bug diagnosis step                         |
| `fix`                 | Bug fix step                               |
| `learnings`           | Contains captured learnings                |
| `learnings-harvested` | Learnings have been processed              |
| `gaps`                | Contains identified gaps                   |
| `gaps-harvested`      | Gaps have been processed                   |

Query by label:

```bash
# Find all implementation tasks
bd list --label implement

# Find tasks with unharvested learnings
bd list --label learnings --no-label learnings-harvested
```

## Parallel Execution

Multiple Ralph instances can run safely in parallel, processing different tasks simultaneously.

### How It Works

- Tasks are claimed by setting `bd update <id> --status=in_progress`
- `bd ready` only shows open tasks, so claimed tasks won't appear to other Ralphs
- Other Ralphs will see different ready tasks
- No coordination needed between instances

### Running Multiple Ralphs

```bash
# Terminal 1
./ralph.sh

# Terminal 2
./ralph.sh

# Terminal 3 (optional)
./ralph.sh
```

### Scaling Guidelines

| Ralphs | Use Case                                   |
| ------ | ------------------------------------------ |
| 1      | Simple workflows, sequential tasks         |
| 2      | Standard development, moderate parallelism |
| 3-4    | Large features, many independent steps     |
| 5+     | Rarely needed, diminishing returns         |

### Best Practices

1. **Start small**: Begin with 2 Ralphs, scale up if stable
2. **Monitor progress**: Use `bd ready --assignee ralph` to check queue
3. **Watch for conflicts**: If Ralphs frequently compete for tasks, reduce count
4. **Consider dependencies**: Parallel execution helps most when steps are independent

### Monitoring

```bash
# Check what's ready for Ralph
bd ready --assignee ralph

# See all in-progress tasks
bd list --status in_progress

# View recent activity
bd list --limit 10
```

## Example: Custom Deployment Formula

Here's a complete example of a custom deployment workflow:

```toml
formula = "deploy"
description = """
# ORCHESTRATOR: Deploy {{environment}}

You coordinate child steps for this deployment.

## Execution Loop

1. **Find ready steps**: `bd ready --parent <your-id>`
2. **For each ready step**, route by assignee prefix:
   - `ralph-subagent-*`: Spawn a Task agent with the step's description
   - `ralph-inline-*`: Execute the step yourself
3. **Read what each step reports** and follow its instructions
4. **Close completed steps**: `bd close <step-id>`
5. **Repeat** until no more steps

## Completion

When all steps are done:
1. Add summary: `bd comments add <your-id> "[summary] Deployed to {{environment}}"`
2. Close yourself: `bd close <your-id>`
"""
version = 1
type = "workflow"

[vars]
environment = "staging"
skip_e2e = "false"

[[steps]]
id = "build"
title = "Build for {{environment}}"
assignee = "ralph-subagent-build"
description = """
Build the application for {{environment}} deployment.

1. Run production build
2. Verify build artifacts
3. Check bundle sizes
"""

[[steps]]
id = "test"
title = "Run test suite"
assignee = "ralph-subagent-test"
needs = ["build"]
description = """
Run the full test suite.

1. Unit tests
2. Integration tests
3. Report any failures
"""

[[steps]]
id = "e2e"
title = "Run E2E tests"
assignee = "ralph-subagent-e2e"
needs = ["test"]
condition = "{{skip_e2e}}"
description = """
Run end-to-end tests against staging.
"""

[[steps]]
id = "deploy"
title = "Deploy to {{environment}}"
assignee = "ralph-inline-deploy"
needs = ["test"]
description = """
Deploy to {{environment}}.

1. Push to deployment target
2. Verify deployment health
3. Report status
"""
```

Pour with:

```bash
bd mol pour deploy \
  --var environment="production" \
  --var skip_e2e="true" \
  --assignee ralph
```
