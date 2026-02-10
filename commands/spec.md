---
description: Generate or refine a spec file for Choo Choo Ralph from your plan
argument-hint: [source-file] [spec-name]
---

# Generate or Refine Spec

## Arguments

<arguments>
source_file = $1  <!-- Optional: path to plan file or conversation context -->
spec_name = $2    <!-- Optional: name of the spec (e.g., "user-auth") -->
</arguments>

This command has smart behavior based on the current state:

## Spec File Naming

Specs are stored as `.choo-choo-ralph/<name>.spec.md`. Each project can have multiple specs.

### When `spec_name` is provided:

- Use that name directly: `.choo-choo-ralph/{spec_name}.spec.md`
- If file exists, enter refinement mode (Mode 2 or 3)
- If file doesn't exist, create new spec (Mode 1)

### When `spec_name` is NOT provided:

1. **Check for existing specs** in `.choo-choo-ralph/*.spec.md`
2. **If exactly one spec exists**: Use that spec (refinement mode)
3. **If multiple specs exist**: Ask user which spec to work with
4. **If no specs exist**: Generate a suggested name based on:
   - The plan content or conversation context
   - Use kebab-case, descriptive, short (e.g., `user-auth`, `dark-mode`, `api-refactor`)
   - Use **AskUserQuestion** to confirm or let user provide alternative:
     ```
     "I'll create a new spec. Suggested name: 'user-authentication'"
     Options:
     - Use suggested name
     - [Other - user provides custom name]
     ```

## Mode Detection

1. **No spec exists (or new name)** → Generate new spec from plan/conversation
2. **Spec exists with review comments** → Refine spec based on comments
3. **Spec exists, no comments** → Ask: regenerate from scratch or continue with existing?

## Mode 1: Generate New Spec

When the target spec file doesn't exist:

### Step 1: Gather Context (Parallel Sub-Agents)

Launch sub-agents in parallel to gather context before generating the spec. This keeps main context lean and speeds up research.

**Sub-Agent 1: Codebase Exploration**
- Explore existing project structure and architecture
- Identify patterns, conventions, and coding standards
- Find relevant existing code the new feature will integrate with
- Note file organization, naming conventions, test patterns
- Identify existing utilities, components, or services to reuse

**Sub-Agent 2: Technology Research** (if plan mentions unfamiliar tech)
- Research documentation for technologies not already in the codebase
- Fetch best practices, common patterns, gotchas
- Look for integration examples with existing stack
- Note any setup/configuration requirements

Both sub-agents should return concise summaries (not full docs) that inform spec generation.

### Step 2: Generate Spec

With context gathered:

- Accept plan from conversation context or file path (`source_file`)
- Invoke the `/choo-choo-ralph:spec-generation` skill for format guidance (includes `<context>` section format)
- **Get current date** by running `date +%Y-%m-%d` bash command for the frontmatter `created` field
- **Include research findings** in the spec's `<context>` section
- Generate at `.choo-choo-ralph/{spec_name}.spec.md`

The spec-generation skill defines the full format including the `<context>` section structure for existing_patterns, integration_points, new_technologies, and conventions.

## Mode 2: Refine Based on Comments (Review Loop)

When spec exists and has non-empty `<review>` tags:

1. **Parse existing spec** with all review comments
2. **Process comments** - understand requested changes:
   - "Split this into smaller tasks"
   - "Add more detail about X"
   - "Combine with task Y"
   - "Remove this, not needed"
   - Comments from other AI agents
3. **Regenerate affected tasks** based on feedback
4. **Clear review tags** after processing (empty tags remain for future comments)

This enables the review loop:

```
spec → user reviews → adds comments → spec → reviews → ... → pour
```

## Mode 3: Spec Exists, No Comments

When spec exists but all `<review>` tags are empty:

- Ask user: "Existing spec found. Would you like to:"
  - A) Start fresh (regenerate from plan)
  - B) Continue reviewing (open spec for editing)
  - C) Proceed to pour (tasks are ready)

## Review Comment Format

Users (or other AI agents) can add comments in review tags:

```xml
<task id="auth" priority="1" category="functional">
  <title>User Authentication</title>
  <description>...</description>
  <steps>...</steps>
  <review>
    Split this into separate login and registration tasks.
    Also add password reset as a third task.
  </review>
</task>
```

After refinement, review tags are **cleared** (not marked processed):

```xml
<review></review>
```

## Iteration Tracking

The spec tracks how many times it's been refined via the frontmatter:

```yaml
---
title: "My Feature"
created: 2026-01-11
poured: []
iteration: 3
---
<project_specification>
  <project_name>...</project_name>
  ...
</project_specification>
```

- `iteration: 1` - Initial generation
- `iteration: 2` - First refinement
- `iteration: 3` - Second refinement
- etc.

This provides useful context about how much the spec has evolved and is queryable.

## Output

**For new spec:**

- Location of generated spec file
- Number of tasks extracted
- Instructions for reviewing
- Next step: review, add comments, run spec again or pour

**For refined spec:**

- Summary of changes made
- Number of tasks added/modified/removed
- Next step: review changes, add more comments or pour
