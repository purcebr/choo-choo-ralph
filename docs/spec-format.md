# Spec File Format Reference

## Overview

Specs are markdown files with XML-like tags that define tasks for the Choo Choo Ralph workflow. They are stored at `.choo-choo-ralph/{name}.spec.md` and serve as the source of truth for task generation.

### Why XML-like Tags?

1. **Clear boundaries** - Task boundaries are explicit, no details leak across tasks
2. **AI-friendly** - Claude understands hierarchical structure naturally
3. **Human-readable** - Easy to edit in any text editor
4. **Git-friendly** - Diffs are clear and meaningful

**IMPORTANT:** These are markdown files, NOT true XML. No XML declaration (`<?xml?>`) is ever used. The XML-like tags provide structure while keeping the file editable as plain markdown.

## File Structure

### YAML Frontmatter

Every spec file starts with YAML frontmatter containing metadata:

```yaml
---
title: User Authentication System
created: 2025-01-15
poured: []
iteration: 1
auto_discovery: true
auto_learnings: true
---
```

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `title` | Yes | - | Human-readable name for the spec |
| `created` | No | Current date | When the spec was created |
| `poured` | No | `[]` | Array of task IDs that have been poured to beads |
| `iteration` | No | `1` | Increments each time `/spec` processes feedback |
| `auto_discovery` | No | `true` | Whether to scan codebase for patterns |
| `auto_learnings` | No | `true` | Whether to incorporate learnings from previous tasks |

### XML Structure

The body uses a hierarchical XML-like structure:

```xml
<project_specification>
  <project_name>Feature Name</project_name>

  <overview>
    Brief description of what this spec accomplishes.
  </overview>

  <context>
    Background information, constraints, and requirements.
  </context>

  <tasks>
    <task id="task-one" priority="1">
      <!-- task content -->
    </task>
    <task id="task-two" priority="2">
      <!-- task content -->
    </task>
  </tasks>
</project_specification>
```

## Tasks

### Task Element

Each task is a self-contained unit of work:

```xml
<task id="add-login-form" priority="1" category="functional">
  <title>Add Login Form Component</title>

  <description>
    Create a reusable login form component with email and password fields.
    Include client-side validation and error display.
  </description>

  <steps>
    1. Create LoginForm component in src/components/auth/
    2. Add email input with validation pattern
    3. Add password input with show/hide toggle
    4. Implement form submission handler
    5. Add loading state during submission
  </steps>

  <test_steps>
    1. Verify form renders with all fields
    2. Test email validation rejects invalid formats
    3. Test password visibility toggle works
    4. Verify loading spinner appears on submit
  </test_steps>

  <review></review>
</task>
```

### Task Attributes

| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `id` | Yes | kebab-case string | Unique identifier, becomes bead ID |
| `priority` | No | `0-4` | 0=critical, 1=high, 2=medium (default), 3=low, 4=backlog |
| `category` | No | See below | Task classification for organization |

**Category values:**
- `functional` - Core feature implementation
- `style` - UI/UX and styling work
- `infrastructure` - Build, deploy, tooling
- `documentation` - Docs, comments, READMEs

### The Review Tag

The `<review>` tag controls whether a task is ready to be poured:

| State | Indicator | Meaning |
|-------|-----------|---------|
| Needs refinement | `<review>feedback here</review>` | Will be processed on next `/spec` run |
| Ready to pour | `<review></review>` | Task can be poured to a bead |

An empty `<review></review>` tag signals the task has been reviewed and approved.

## Review Process

### Adding Feedback

Edit the spec file directly and add comments inside review tags:

```xml
<task id="setup-database" priority="1">
  <title>Set Up Database Schema</title>

  <description>
    Create the initial database schema for user accounts.
  </description>

  <steps>
    1. Create users table with basic fields
    2. Add indexes for common queries
  </steps>

  <review>
    Split this into two tasks: one for schema creation and one for
    indexes. Also add a step for creating the sessions table.
  </review>
</task>
```

### Processing Feedback

Run `/choo-choo-ralph:spec` again. The AI will:

1. Parse all feedback in review tags
2. Modify tasks according to the feedback
3. Clear review tags (set them to empty)
4. Increment the `iteration` counter in frontmatter

### Review Tips

Use natural language in review tags. Common patterns:

**Split tasks:**
```xml
<review>Split into: schema creation, index optimization, and migration script</review>
```

**Add detail:**
```xml
<review>Add step for handling the edge case when user email already exists</review>
```

**Remove tasks:**
```xml
<review>Remove this task, already handled by existing code</review>
```

Or simply delete the entire `<task>` element from the spec.

**Combine tasks:**
```xml
<review>Merge this with task add-validation, they're too small separately</review>
```

**Reorder or add dependencies:**
```xml
<review>This should come after setup-database, needs the schema first</review>
```

**Request clarification:**
```xml
<review>Which API endpoint should this use? REST or GraphQL?</review>
```

## Optional Sections

### Context Section

Provide background information to guide task generation:

```xml
<context>
  <existing_patterns>
    - Components use React hooks, no class components
    - API calls go through src/lib/api.ts
    - Forms use react-hook-form with zod validation
  </existing_patterns>

  <integration_points>
    - Auth state managed by AuthContext
    - Toast notifications via useToast hook
    - Routes defined in src/app/routes.tsx
  </integration_points>

  <conventions>
    - File names use kebab-case
    - Components use PascalCase
    - Tests colocated with source files
  </conventions>
</context>
```

### Technology Stack

Document the technical environment:

```xml
<technology_stack>
  <frontend>React 18, TypeScript, Tailwind CSS</frontend>
  <backend>Node.js, Express, PostgreSQL</backend>
  <testing>Vitest, React Testing Library</testing>
  <deployment>Vercel, GitHub Actions</deployment>
</technology_stack>
```

### Database Schema

Include schema details when relevant:

```xml
<database_schema>
  <table name="users">
    - id: uuid primary key
    - email: varchar(255) unique not null
    - password_hash: varchar(255) not null
    - created_at: timestamp default now()
  </table>

  <table name="sessions">
    - id: uuid primary key
    - user_id: uuid references users(id)
    - expires_at: timestamp not null
  </table>
</database_schema>
```

## Archive

After tasks are poured into beads, the spec behavior changes:

1. The `poured` array in frontmatter tracks which task IDs have been converted to beads
2. Once all tasks are poured, the spec is moved to `.choo-choo-ralph/archive/`
3. Archived specs serve as historical records and can be referenced for learnings

Example of a partially poured spec:

```yaml
---
title: User Authentication System
created: 2025-01-15
poured:
  - add-login-form
  - setup-database
iteration: 3
---
```

Tasks in the `poured` array will be skipped on subsequent `/pour` runs, allowing incremental task creation while preserving the complete spec for reference.
