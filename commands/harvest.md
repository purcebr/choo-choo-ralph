---
description: Harvest learnings and gaps from completed Choo Choo Ralph tasks into docs, skills, or CLAUDE.md
---

# Harvest Learnings and Gaps

Extract valuable learnings from completed Ralph tasks and propose documentation artifacts. Also review identified gaps and create tasks for approved ones.

## Overview

Agents accumulate learnings as they work (gotchas, patterns, recommendations). They also identify gaps - missing functionality, incomplete implementations, or areas needing improvement. This command:

1. Gathers learnings and gaps from completed beads
2. Enriches them with git context
3. Proposes documentation artifacts for learnings
4. Proposes tasks for approved gaps
5. Creates a plan for user review
6. On approval, creates the artifacts, pours gap tasks, and archives the plan

## Mode Detection

1. **No harvest plan exists** - Gather learnings and create new plan
2. **Plan exists with review comments** - Refine plan based on comments
3. **Plan exists, no comments** - Ask: regenerate or proceed to create artifacts?

**Important**: Only ONE `harvest-plan.md` can exist at a time. Previous plans are archived after approval.

## Mode 1: Gather Learnings and Gaps

### Step 1: Query Beads with Learnings and Gaps

Find beads that have learning recommendations but haven't been harvested:

```bash
bd list --label learnings --json | jq '[.[] | select(.labels | index("learnings-harvested") | not)]'
```

Find beads that have identified gaps but haven't been processed:

```bash
bd list --label gaps --json | jq '[.[] | select(.labels | index("gaps-harvested") | not)]'
```

If no beads found in either query, report "No unharvested learnings or gaps found" and exit.

### Step 2: Enrich with Git Context

For each learning or gap bead, spawn a sub-agent (using Task tool) to:

1. **Get the bead's commit references** - Check comments for commit hashes or search git log:
   ```bash
   git log --grep="<bead-id>" --oneline
   ```
2. **Analyze modified files** - What files were touched? What patterns emerged?
3. **Read the comments** - Parse `[bearings]`, `[implement]`, `[verify]`, `[summary]` comments for learnings and gaps
4. **Form enriched summary** - Combine learning/gap with file context

The sub-agent should return a structured summary:

```json
{
  "bead_id": "choo-xxx",
  "title": "Original task title",
  "learnings": [
    {
      "source": "implement",
      "raw": "shadcn Button requires forwardRef when wrapping",
      "files_affected": ["src/components/ui/button.tsx"],
      "enriched": "When wrapping shadcn Button component, always use forwardRef to preserve ref forwarding. Without this, parent components cannot access the underlying button element."
    }
  ],
  "gaps": [
    {
      "source": "verify",
      "raw": "Missing input validation for user API",
      "files_affected": ["src/api/users.ts"],
      "context": "Line 45 accepts user input without validation",
      "severity": "medium"
    }
  ],
  "recommendation": "Consider creating skill for shadcn component patterns"
}
```

### Step 3: Check Existing Documentation

Before proposing new artifacts, scan for existing documentation:

1. **CLAUDE.md files** - Root and folder-specific:

   ```bash
   find . -name "CLAUDE.md" -o -name ".claude.md" 2>/dev/null
   ```

   Read each and note what's already documented.

2. **Skills** - Check for existing skills in `.claude/skills/`:

   ```bash
   ls -la .claude/skills/ 2>/dev/null || echo "No skills directory"
   ```

   Read skill files to understand what's covered.

3. **Docs folder** - Check for reference documentation:
   ```bash
   ls -la docs/ 2>/dev/null || echo "No docs directory"
   ```

**Prefer modifying existing skills over creating fragmented new ones.** Skills should be specific to a pattern or technology.

### Step 4: Deduplicate and Categorize

#### Learnings

Group similar learnings and determine the best artifact type:

| Learning Type                                  | Artifact         | Location                       |
| ---------------------------------------------- | ---------------- | ------------------------------ |
| Technology pattern (e.g., "how to use shadcn") | Reference doc    | `docs/<tech>.md`               |
| Repeated workflow (e.g., "always do X when Y") | Skill            | `.claude/skills/<pattern>.md`  |
| Critical project guidance                      | Root CLAUDE.md   | `CLAUDE.md`                    |
| Folder-specific pattern                        | Folder CLAUDE.md | `<folder>/CLAUDE.md`           |

Skip learnings that are:

- Already documented in existing files
- Too specific to be useful for future work
- Actually bugs/fixes (should be beads, not docs)

#### Gaps

For each gap, check if there's already an existing task that covers it:

```bash
bd search "<gap description keywords>"
```

Skip gaps that:

- Already have an existing open bead covering the issue
- Are too minor to warrant a task
- Were already fixed in subsequent work

### Step 5: Get Current Date

Use bash to get an accurate timestamp (never hallucinate dates):

```bash
date +%Y-%m-%d
```

### Step 6: Generate Harvest Plan

Create `.choo-choo-ralph/harvest-plan.md` with YAML frontmatter and markdown content:

```markdown
---
source_beads:
  - id: choo-abc
    title: "Add user settings"
    has_learnings: true
    has_gaps: false
  - id: choo-def
    title: "Fix button styling"
    has_learnings: true
    has_gaps: true
  - id: choo-xyz
    title: "Add API tests"
    has_learnings: false
    has_gaps: true
gaps_to_review:
  - bead_id: choo-def
    gap: "Missing input validation for user API"
    context: "See src/api/users.ts:45"
    action: pending  # pending | approved | rejected
  - bead_id: choo-xyz
    gap: "No error handling for network failures"
    context: "See src/api/client.ts:12"
    action: pending
skills_to_create:
  - name: shadcn-components
    location: .claude/skills/shadcn-components.md
skills_to_modify:
  - name: database-patterns
    location: .claude/skills/database-patterns.md
    additions:
      - "connection pooling section"
      - "query optimization tips"
artifacts_to_update:
  - CLAUDE.md
  - tests/CLAUDE.md
created: 2026-01-11
---

# Harvest Plan

Found N learnings from M completed tasks and G gaps to review. Proposing X new artifacts after deduplication.

## Existing Documentation

What was found during scan:

- **CLAUDE.md** - Project setup, testing commands, core patterns
- **docs/api.md** - API conventions
- **.claude/skills/component-patterns.md** - React component guidelines

## Gaps to Review

Gaps identified during task execution that may need follow-up work.

### 1. Missing input validation for user API

**Source bead**: choo-def
**Context**: src/api/users.ts:45 - no validation on user input
**Severity**: medium

#### Proposed Task

**Title**: Add input validation for user API
**Category**: infrastructure

#### Existing Coverage Check

<!-- List any existing beads that may cover this, or "None found" -->

#### Review Notes

<!--
Set action to: approved | rejected
Add your review comments here
-->

---

### 2. No error handling for network failures

**Source bead**: choo-xyz
**Context**: src/api/client.ts:12 - network calls have no try/catch
**Severity**: high

#### Proposed Task

**Title**: Add error handling for network failures in API client
**Category**: infrastructure

#### Existing Coverage Check

<!-- List any existing beads that may cover this, or "None found" -->

#### Review Notes

<!--
Set action to: approved | rejected
Add your review comments here
-->

---

## Proposed Artifacts

### 1. Skill: shadcn-components

**Location**: `.claude/skills/shadcn-components.md`
**Trigger**: When working with shadcn UI components
**Source beads**: choo-abc, choo-def

#### Content Preview

## shadcn Component Patterns

### forwardRef Requirement
Always wrap shadcn components with forwardRef...

### Import Convention
Import from the component barrel...

#### Review Notes

<!-- Add your review comments here -->

---

### 2. CLAUDE.md Update: API Testing Requirements

**Location**: `tests/CLAUDE.md`
**Source beads**: choo-xyz

#### Content Preview

# Test Directory Guidelines

## Environment Variables
Tests require VITE_API_URL to be set...

#### Review Notes

<!-- Add your review comments here -->

---

### 3. Reference Doc: Database Patterns

**Location**: `docs/database.md`
**Source beads**: choo-123, choo-456

#### Content Preview

# Database Patterns

## Query Conventions
...

#### Review Notes

<!-- Add your review comments here -->

---

## Skipped Learnings

Learnings that were deduplicated or deemed not worth documenting:

| Bead | Learning | Reason |
|------|----------|--------|
| choo-zzz | Import from index.ts | Already covered in CLAUDE.md |

## Skipped Gaps

Gaps that were skipped due to existing coverage or other reasons:

| Bead | Gap | Reason |
|------|-----|--------|
| choo-yyy | Missing tests for edge case | Already covered by choo-999 |

## Next Steps

1. Review each proposed artifact above
2. Review each gap and set action to `approved` or `rejected` in frontmatter
3. Add comments in the "Review Notes" sections for changes
4. Run `/harvest` again to refine or approve
```

## Mode 2: Refine Plan Based on Comments

When plan exists and has non-empty "Review Notes" sections:

1. **Parse review comments** - Understand requested changes:
   - "Don't create this skill, add to CLAUDE.md instead"
   - "Combine these two artifacts"
   - "More detail needed on X"
   - "Skip this one"
2. **Parse gap actions** - Check `gaps_to_review` in frontmatter:
   - `approved` - Gap will be poured as a new task
   - `rejected` - Gap will be skipped
   - `pending` - Still needs review
3. **Regenerate affected artifacts** based on feedback
4. **Clear review sections** after processing
5. **Update the plan** with revised content

## Mode 3: Plan Exists, No Comments

Ask user via AskUserQuestion:

- A) Regenerate plan (re-scan for new learnings and gaps)
- B) Proceed to create artifacts and pour approved gaps (approve current plan)
- C) Cancel

## Creating Artifacts and Processing Gaps

When user indicates approval (Mode 3 option B, or explicit request):

### For Each Approved Artifact

1. **Skills** (in `.claude/skills/`):

   - Create `.claude/skills/` directory if needed
   - Write `.claude/skills/<name>.md` with proper frontmatter:

     ```markdown
     ---
     name: <Name>
     description: <trigger description for when skill should activate>
     version: 1.0.0
     ---

     <content>
     ```

2. **CLAUDE.md** updates:

   - If root: Append to or create `CLAUDE.md`
   - If folder: Create `<folder>/CLAUDE.md`
   - Use clear section headers

3. **Reference Docs**:
   - Create `docs/` directory if needed
   - Write `docs/<name>.md`

### For Each Approved Gap

1. **Check for existing coverage** - Search for existing tasks that may cover the gap:

   ```bash
   bd search "<gap keywords>"
   ```

   If an existing task covers the gap, skip creating a new one.

2. **Pour new task** - Use the choo-choo-ralph formula to create a task:

   ```bash
   bd mol pour choo-choo-ralph --title "<gap title>" --description "<gap description with context>"
   ```

3. **Link to source bead** - Add a comment to the new task referencing the source:

   ```bash
   bd comments add <new-bead-id> "Gap identified from <source-bead-id>"
   ```

### After Creating Artifacts and Processing Gaps

1. **Mark beads with learnings as learnings-harvested**:

   ```bash
   bd label add <bead-id> learnings-harvested
   ```

   Do this for all beads in `source_beads` that have `has_learnings: true`.

2. **Mark beads with gaps as gaps-harvested**:

   ```bash
   bd label add <bead-id> gaps-harvested
   ```

   Do this for all beads in `source_beads` that have `has_gaps: true`.

3. **Archive the harvest plan**:

   Get the current date and archive:

   ```bash
   ARCHIVE_DATE=$(date +%Y-%m-%d)
   mkdir -p .choo-choo-ralph/archive
   mv .choo-choo-ralph/harvest-plan.md ".choo-choo-ralph/archive/harvest-plan-${ARCHIVE_DATE}.md"
   ```

   If a file with that date already exists, append a counter (e.g., `harvest-plan-2026-01-11-2.md`).

4. **Report summary**:
   - Artifacts created and their locations
   - Tasks created for approved gaps
   - Beads marked as learnings-harvested
   - Beads marked as gaps-harvested
   - Location of archived plan
   - Suggestion to commit the new documentation

## Output

**For new plan:**

- Location of harvest plan file
- Number of learnings gathered
- Number of gaps identified
- Number of artifacts proposed
- Instructions for reviewing

**For refined plan:**

- Summary of changes made
- Number of artifacts modified
- Number of gaps with updated status
- Next step: review more or approve

**For artifact creation and gap processing:**

- List of created documentation files
- List of created tasks for approved gaps
- Beads marked as learnings-harvested
- Beads marked as gaps-harvested
- Archived plan location
- Reminder to commit and push
