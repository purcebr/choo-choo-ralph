# Complete Workflow Guide

This guide walks you through a complete Choo Choo Ralph session from start to finish. By the end, you will understand how to transform a rough plan into working, tested code while capturing learnings for future sessions.

## Overview

Choo Choo Ralph follows a five-phase workflow:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CHOO CHOO RALPH WORKFLOW                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│   │   PLAN   │───▶│   SPEC   │───▶│   POUR   │───▶│  RALPH   │───▶│ HARVEST  │
│   │          │    │          │    │          │    │          │    │          │
│   │   You    │    │ You + AI │    │    AI    │    │    AI    │    │ You + AI │
│   └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
│        │               │               │               │               │
│        ▼               ▼               ▼               ▼               ▼
│   Rough ideas    Structured     Beads tasks     Working code    Captured
│   & goals        task list      ready to run    & commits       learnings
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Planning (Your Work)

**This step is entirely on you.** Choo Choo Ralph does not do planning - it executes plans. The quality of your plan directly determines the quality of the output.

### What Planning Looks Like

Planning can take many forms:

- **Bullet points** - Quick notes about what you want to build
- **PRDs (Product Requirements Documents)** - Formal specifications
- **Design documents** - Technical architecture decisions
- **Conversations with Claude** - Interactive brainstorming sessions
- **Sketches and mockups** - Visual representations of the goal
- **Existing issues or tickets** - From your project management tool

The key is having a clear understanding of **what** you want to achieve, not necessarily **how** to achieve it.

### Planning Tips

1. **Be clear about WHAT, not HOW**

   - Good: "Users should be able to reset their password via email"
   - Bad: "Create a resetPassword() function that calls sendEmail()"

2. **Include acceptance criteria**

   - How will you know when this is done?
   - What should work? What edge cases matter?

3. **Note constraints and requirements**

   - Must integrate with existing auth system
   - Must support both email and SMS
   - Must complete in under 3 seconds

4. **Identify dependencies**

   - What existing code does this build on?
   - What needs to exist before this can work?

5. **Think about scope**
   - Is this a single session's work or multiple?
   - Can it be broken into independent pieces?

### Example Plan: User Authentication

Here is an example plan that would work well with Choo Choo Ralph:

```markdown
# User Authentication Feature

## Goal

Add user authentication to the application so users can create accounts,
log in, and access protected resources.

## Requirements

### User Registration

- Email and password registration
- Email validation (proper format)
- Password requirements: 8+ chars, 1 number, 1 special char
- Duplicate email prevention
- Welcome email after registration

### User Login

- Email/password login
- Rate limiting (5 attempts per 15 minutes)
- "Remember me" option (30-day token)
- Session management

### Password Reset

- "Forgot password" flow via email
- Secure reset tokens (expire in 1 hour)
- Password change confirmation email

## Constraints

- Use existing PostgreSQL database
- Must work with current Express.js backend
- JWT for session tokens
- bcrypt for password hashing

## Out of Scope

- OAuth/social login (future phase)
- Two-factor authentication (future phase)
- Admin user management
```

This plan is clear about what needs to be built, includes acceptance criteria, notes technical constraints, and explicitly states what is out of scope.

---

## Step 2: Generate and Review the Spec

### Why Specs?

A spec transforms your rough plan into a structured, reviewable list of tasks. Specs serve multiple purposes:

1. **Clarity** - Forces you to think through the work before starting
2. **Review** - Gives you a chance to catch issues before code is written
3. **Parallelization** - Well-defined tasks can run independently
4. **Progress tracking** - Each task is a measurable unit of work
5. **AI-friendliness** - Structured format that agents understand

### Generating a Spec

#### Spec Arguments

Spec accepts two optional positional arguments:

```bash
/choo-choo-ralph:spec [source-file] [spec-name]
```

| Argument | Description |
|----------|-------------|
| `source-file` | Path to plan file (uses conversation context if omitted) |
| `spec-name` | Name for the spec, e.g., `user-auth` (auto-suggested if omitted) |

**Examples:**
```bash
/choo-choo-ralph:spec plans/user-auth.md         # Generate from plan file
/choo-choo-ralph:spec plans/feature.md my-feature # With explicit spec name
/choo-choo-ralph:spec                            # Generate from conversation context
```

Specs are stored at `.choo-choo-ralph/{spec-name}.spec.md`.

#### Interactive Prompts

Depending on the current state, you may be prompted:

**Multiple specs exist** (and no spec-name provided):
- Prompt asks which existing spec to work with

**Spec exists with empty review tags**:
- "Start fresh" - Regenerate from plan
- "Continue reviewing" - Open spec for editing
- "Proceed to pour" - Tasks are ready

**Refining a spec with review comments**:
- No prompt - automatically processes the review feedback and updates the spec

### The Spec Format

Specs use a markdown format with XML-like tags for clear boundaries:

```markdown
# Feature: User Authentication

<context>
This spec implements user authentication for the application.
The system uses Express.js with PostgreSQL and JWT tokens.
</context>

<task id="create-user-schema" priority="1" category="infrastructure">
<title>Create user database schema</title>
<description>
Create the users table with fields for email, password hash,
created_at, and updated_at. Include proper indexes.
</description>
<steps>
1. Create users table migration
2. Add email, password_hash, created_at, updated_at fields
3. Add unique constraint on email
4. Add indexes on email and created_at
</steps>
<test_steps>
1. Verify users table exists with all required fields
2. Verify email field has unique constraint
3. Verify indexes exist on email and created_at
</test_steps>
<review></review>
</task>

<task id="implement-password-hashing" priority="1" category="functional">
<title>Implement password hashing utilities</title>
<description>
Create utility functions for hashing passwords with bcrypt
and verifying password attempts.
</description>
<steps>
1. Create hashPassword() function using bcrypt
2. Create verifyPassword() function
3. Set bcrypt cost factor to 12
4. Add unit tests
</steps>
<test_steps>
1. hashPassword() returns valid bcrypt hash
2. verifyPassword() correctly validates passwords
3. verifyPassword() rejects incorrect passwords
4. Cost factor is set to 12
</test_steps>
<review></review>
</task>
```

For complete format specification, see [spec-format.md](./spec-format.md).

### The Review Process (Critical!)

**This is the most important part of the workflow.** A poorly reviewed spec leads to wasted time and incorrect implementations.

#### How Review Works

1. **Read through each task** - Does it make sense? Is it complete?

2. **Add feedback in `<review>` tags** - Place your comments directly in the spec:

```markdown
<task id="user-registration-endpoint" priority="1" category="functional">
<title>User registration endpoint</title>
<description>
Create POST /api/register endpoint for user registration.
</description>
<steps>
1. Create POST /api/register route
2. Validate email format
3. Validate password requirements
4. Create user in database
5. Return user object on success
</steps>
<test_steps>
1. Validates email format
2. Validates password requirements
3. Returns user object on success
</test_steps>
<review>
This task is too big. Split into:
1. Input validation
2. User creation
3. Welcome email sending
Also add: should return JWT token, not just user object
</review>
</task>
```

3. **Run `/choo-choo-ralph:spec` again** - Claude reads your review tags and updates the spec

4. **Repeat until all review tags are empty** - The spec is ready when you have no more feedback

#### Review Tips

**Split tasks that are too large:**

```markdown
<review>
This task combines database work, API work, and email sending.
Split into three separate tasks.
</review>
```

**Add missing detail:**

```markdown
<review>
Need to specify: What HTTP status codes? What error format?
What happens if email already exists?
</review>
```

**Remove unnecessary tasks:**

```markdown
<review>
Delete this task - we already have this functionality in utils/validation.js
</review>
```

**Combine tasks that are too small:**

```markdown
<review>
Tasks 7 and 8 are trivial and related. Combine into single task.
</review>
```

**Reorder for better dependencies:**

```markdown
<review>
This task should come after task 5 - it depends on the auth middleware.
Update dependencies to reflect this.
</review>
```

**Add missing acceptance criteria:**

```markdown
<review>
Acceptance criteria incomplete. Add:
- Rate limiting works correctly
- Handles concurrent requests
- Logs failed attempts
</review>
```

---

## Step 3: Pour the Spec into Beads

### Why Granularize?

Pouring takes your reviewed spec tasks and breaks them into even smaller, more atomic units of work. This granularization is intentional and serves several purposes:

**More consistent results** - Smaller tasks are easier for the agent to understand and execute correctly. A task like "add user authentication" is ambiguous; "create password hashing utility function" is clear.

**Less wasted usage** - When a large task fails partway through, you lose all the work. Small tasks mean failures are contained—if one breaks, the others still succeed.

**Better verification at each step** - Each small task goes through the full bearings → implement → verify → commit cycle. This catches issues early rather than accumulating problems across a large implementation.

**Improved quality for unmonitored runs** - When running autonomously (especially overnight), smaller scope means more checkpoints. The agent verifies, tests, and commits at each step rather than building up a large, potentially broken changeset.

The target number of tasks depends on your project size and complexity. More granular is generally better—three similar lines of working code beat one ambitious abstraction that doesn't quite work.

### What Pouring Does

Pouring transforms your reviewed spec tasks into executable Beads issues. Each task becomes a bead that Ralph can pick up and work on.

The pour process:

1. Reads your spec file
2. Creates beads for each task
3. Sets up dependencies between beads
4. Assigns the configured formula to each bead
5. Archives the spec file
6. Updates the spec with a `poured` array tracking created beads

### Running Pour

```bash
/choo-choo-ralph:pour
```

Pour will prompt you to select a spec if multiple exist, or use the most recent one.

### Choosing a Mode

Pour offers two execution modes:

#### Workflow Formula (Recommended)

The workflow formula provides a multi-step process for each task:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  BEARINGS   │───▶│  IMPLEMENT  │───▶│   VERIFY    │───▶│   COMMIT    │
│             │    │             │    │             │    │             │
│ Understand  │    │ Write code  │    │ Run tests   │    │ Commit if   │
│ context     │    │             │    │ & checks    │    │ verified    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

Each phase:

- **Bearings**: Agent reads relevant files, understands context, creates a plan
- **Implement**: Agent writes the code following the plan
- **Verify**: Agent runs tests, linters, type checks
- **Commit**: If verification passes, agent commits with descriptive message

Use workflow formula when:

- Building production features
- Code quality matters
- You want atomic, tested commits
- Running overnight

#### Singular Tasks

Singular mode executes tasks directly without the multi-phase workflow:

```
┌─────────────────────────────────────────┐
│            EXECUTE DIRECTLY             │
│                                         │
│  Read task → Do work → Mark complete    │
└─────────────────────────────────────────┘
```

Use singular tasks when:

- Doing research or exploration
- Prototyping ideas
- Tasks are simple and low-risk
- You want faster iteration

### Pour Arguments

Pour accepts three optional positional arguments:

```bash
/choo-choo-ralph:pour [target-tasks] [spec-file] [formula]
```

| Argument       | Description                                     |
| -------------- | ----------------------------------------------- |
| `target-tasks` | Target number of implementation tasks to create |
| `spec-file`    | Spec name or path (auto-detected if omitted)    |
| `formula`      | Formula name to use (prompted if omitted)       |

**Examples:**

```bash
/choo-choo-ralph:pour                    # Auto-detect everything, prompt for options
/choo-choo-ralph:pour 80                 # Target 80 implementation tasks
/choo-choo-ralph:pour 80 my-feature      # 80 tasks from my-feature spec
/choo-choo-ralph:pour 80 my-feature choo-choo-ralph  # With specific formula
```

### Interactive Prompts

If you don't specify all arguments, pour will prompt you interactively:

1. **Workflow mode**: "Use workflow formula" vs "Create singular tasks"
2. **Formula selection** (workflow mode only): Choose which formula if multiple exist
3. **Confirmation**: "Pour all tasks", "Show task overview first", or "Cancel"

### Preview Before Pouring

Choosing "Show task overview first" writes all proposed beads to `.choo-choo-ralph/pour-preview.md` without creating them. This gives you a chance to review the granularized tasks before committing.

The preview shows:
- Task title
- Description snippet
- Category and priority
- Test step count

Review the preview file in your editor. If the breakdown looks wrong—tasks too big, too small, missing steps, or unclear—go back and refine your spec before pouring. Once you're satisfied, run `/choo-choo-ralph:pour` again and choose "Pour all tasks".

### What Happens After Pour

1. **Tasks created** - Beads appear in `.beads/issues/`
2. **Spec updated** - The spec file gets a `poured` array with bead IDs
3. **Spec archived** - Original spec moves to `.choo-choo-ralph/archive/`
4. **Ready for Ralph** - Tasks are now executable

Example spec after pour:

```markdown
<poured>
- CCR-1: Create user database schema
- CCR-2: Implement password hashing utilities
- CCR-3: User registration endpoint
</poured>
```

---

## Step 4: Run the Ralph Loop

### Starting Ralph

Ralph runs via shell script:

```bash
# Run 5 tasks (default)
./ralph.sh

# Run up to 10 tasks
./ralph.sh 10

# Run with verbose output
./ralph.sh --verbose

# Run 20 tasks with verbose output
./ralph.sh 20 --verbose
```

### What Ralph Does for Each Task

For each task, Ralph follows the configured formula. With the default workflow formula:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RALPH TASK EXECUTION                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. CLAIM TASK                                                              │
│     └─▶ Finds next ready task and sets status to in_progress                │
│                                                                             │
│  2. BEARINGS PHASE                                                          │
│     └─▶ Reads task description and acceptance criteria                      │
│     └─▶ Identifies relevant files to read                                   │
│     └─▶ Creates implementation plan                                         │
│     └─▶ Records [LEARNING] comments for useful discoveries                  │
│                                                                             │
│  3. IMPLEMENT PHASE                                                         │
│     └─▶ Follows bearings plan                                               │
│     └─▶ Writes/modifies code                                                │
│     └─▶ Records [LEARNING] and [GAP] comments                               │
│                                                                             │
│  4. VERIFY PHASE                                                            │
│     └─▶ Runs test suite                                                     │
│     └─▶ Runs linter                                                         │
│     └─▶ Runs type checker (if applicable)                                   │
│     └─▶ Checks acceptance criteria                                          │
│     └─▶ If FAIL: loops back to implement (max 3 attempts)                   │
│                                                                             │
│  5. COMMIT PHASE                                                            │
│     └─▶ Creates descriptive commit message                                  │
│     └─▶ Commits changes                                                     │
│     └─▶ Marks task complete                                                 │
│                                                                             │
│  6. NEXT TASK                                                               │
│     └─▶ If more tasks remain and limit not reached, go to step 1            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### On the Loop, Not In the Loop

There's an important distinction between being **in the loop** (approving each action) and being **on the loop** (observing the system run).

With Ralph, you're on the loop: you're not approving individual tool calls or code changes, but you are watching and learning. This observation is valuable for improving your setup:

- **Refine prompts** - Notice when the agent gets confused or takes wrong turns? Adjust the formula prompts.
- **Tune workflows** - See steps that consistently fail? Maybe the verification is too strict, or bearings needs more guidance.
- **Identify patterns** - Watch what the agent does well and what it struggles with. Feed that back into your spec reviews.

The best results come from actively sitting on the loop—not micromanaging, but observing so you can iterate on your prompts, formulas, and workflow steps. Each run teaches you something about what works for your codebase.

### Observing the Loop

Ralph includes a formatted output display so you can watch what's happening.

#### Normal Mode Output

```
💭 Let me check for ready tasks
🔧 Bash bd ready --assignee ralph --json
   └─ 📋 Ready work (1 issues with no blockers)
💭 I'll work on the bearings step
🔧 Task [Explore] Get oriented in codebase
   └─ Found 3 relevant files...
🔧 Read /src/auth/login.ts
   └─ export function login(email: string, password: string)...
🔧 Edit /src/auth/login.ts
   └─ (file updated)
🔧 Bash npm test
   └─ All tests passed

✓ Done
```

#### Verbose Mode Adds

- 🧠 Thinking blocks (shows Claude's reasoning)
- Full bash commands (wrapped nicely, not truncated)
- Up to 10 lines of tool output (vs 1 line in normal mode)
- Full error messages with context
- Token summary at the end:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Total: 12,345 input, 567 output, 89% cache hit
```

### Testing Before You Sleep

Before starting an overnight run, test with a single task:

```bash
./ralph-once.sh
```

This runs exactly one task and exits. Use it to:

- Verify your setup is working
- Check that the formula produces good results
- Ensure tests are passing
- Confirm commits look correct

If `ralph-once.sh` succeeds, you can confidently start a longer run.

### While Ralph Runs

Ralph handles several situations automatically:

#### Verification Failures

If verification fails (tests, linting, etc.), Ralph:

1. Analyzes the failure
2. Returns to implement phase
3. Attempts to fix the issue
4. Re-runs verification
5. After 3 failed attempts, marks task as blocked

#### Health Check Failures

Ralph periodically checks:

- Git status is clean (no uncommitted changes)
- No untracked files in working directory
- Database connections are healthy (if applicable)

If health checks fail, Ralph pauses and logs the issue.

#### Blocked Tasks

A task becomes blocked when:

- Dependencies are not complete
- Verification fails 3 times
- Health checks fail

Blocked tasks are skipped, and Ralph moves to the next ready task.

---

## Step 5: Harvest Learnings

### Why Harvest?

During execution, agents capture valuable information:

- **[LEARNING]** - Useful discoveries about the codebase

  - "The auth middleware expects tokens in the Authorization header"
  - "All database models extend BaseModel which provides timestamps"

- **[GAP]** - Missing work or incomplete implementations
  - "Missing input validation for user API"
  - "No error handling for network failures"
  - "Integration needed between auth frontend and backend"

Harvesting transforms these comments into permanent improvements.

### Running Harvest

```bash
/choo-choo-ralph:harvest
```

### The Three-Phase Process

#### Phase 1: Generate Harvest Plan

Claude scans completed tasks, extracts learnings and gaps, and creates a plan:

```
Created harvest plan at .choo-choo-ralph/harvest-plan.md
Please review and edit the plan, then run /harvest again to apply.
```

The harvest plan looks like:

```markdown
# Harvest Plan

Generated: 2024-01-15T14:45:00Z
Source: 8 completed tasks

## Learnings to Capture

### For CLAUDE.md

- [ ] Auth middleware location: src/middleware/auth.js
- [ ] Database models extend BaseModel for timestamps
- [ ] Error responses follow { error: string, code: number } format

### For New Skills

- [ ] Create skill: "authentication-patterns" documenting JWT flow

### For Documentation

- [ ] Update API.md with new auth endpoints

## Gaps to Address

Gaps are missing work discovered during implementation. Each gap can become a new task.

- [ ] Missing input validation for user registration API
      Source: choo-def
      Action: pending

- [ ] No error handling for network failures in API client
      Source: choo-xyz
      Action: pending
```

#### Phase 2: Review and Approve

Edit the harvest plan:

- Check/uncheck learnings to include or exclude
- Modify suggested skill/doc content
- Set gap actions to `approved` (create task) or `rejected` (skip)
- Add comments for Claude

Then run harvest again:

```bash
/choo-choo-ralph:harvest
```

#### Phase 3: Apply Changes

Claude reads your reviewed plan and:

- Updates CLAUDE.md with approved learnings
- Creates new skills for patterns
- Updates or creates documentation
- Creates new beads for approved gaps

### The Compounding Effect

Harvest creates a flywheel:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        THE COMPOUNDING FLYWHEEL                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│         ┌──────────────────────────────────────────────┐                   │
│         │                                              │                   │
│         ▼                                              │                   │
│    ┌─────────┐      ┌─────────┐      ┌─────────┐      │                   │
│    │  CODE   │─────▶│ MEMORY  │─────▶│ HARVEST │──────┘                   │
│    │         │      │         │      │         │                           │
│    │ Ralph   │      │ [LEARN] │      │ Skills  │                           │
│    │ writes  │      │ [GAP]   │      │ Docs    │                           │
│    │ code    │      │ notes   │      │ CLAUDE  │                           │
│    └─────────┘      └─────────┘      └─────────┘                           │
│         ▲                                  │                               │
│         │                                  │                               │
│         │           ┌─────────┐           │                               │
│         │           │COMPOUND │           │                               │
│         └───────────│         │◀──────────┘                               │
│                     │ Future  │                                            │
│                     │ Ralphs  │                                            │
│                     │ smarter │                                            │
│                     └─────────┘                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

Each harvest:

1. Captures what Ralph learned
2. Stores it in skills, docs, and CLAUDE.md
3. Future Ralphs read this context
4. Future Ralphs are more effective
5. Future Ralphs generate more learnings
6. Repeat

Over time, your project accumulates a knowledge base that makes each session more productive.

---

## Parallel Execution

For larger specs, you can run multiple Ralph loops simultaneously.

### Running Multiple Ralphs

Open multiple terminals and run:

```bash
# Terminal 1
./ralph.sh 50

# Terminal 2
./ralph.sh 50

# Terminal 3
./ralph.sh 50
```

### How It Works

- **Status-based claiming** - Each Ralph runs `bd ready` to find open tasks, then claims one with `bd update <id> --status in_progress`
- **Independent execution** - Each Ralph works on its own task
- **Shared state** - All Ralphs see the same beads and dependencies
- **Automatic coordination** - When one Ralph completes a task, others see updated dependencies

### Parallel Execution Tips

1. **Start small** - Begin with 2 parallel Ralphs
2. **Monitor stability** - Watch for conflicts or issues
3. **Scale up gradually** - Add more Ralphs if stable
4. **Consider resources** - Each Ralph uses API credits and system resources
5. **Check dependencies** - Ensure tasks have correct dependencies to avoid conflicts

### Common Issues

**Git conflicts**: If two Ralphs modify the same file, one will fail verification. The failing Ralph will retry, and usually succeeds after the other commits.

**Resource contention**: Too many parallel Ralphs can overwhelm your API rate limits or system resources. Start conservatively.

**Database locks**: If tasks modify shared database state, ensure proper transaction handling.

For detailed information on formulas and parallel execution, see [formulas.md](./formulas.md).

---

## Troubleshooting Common Issues

### Spec Generation Issues

**Problem**: Spec is too vague or tasks are too large
**Solution**: Add more detail to your plan, be specific about requirements

**Problem**: Tasks have circular dependencies
**Solution**: Review dependencies in spec, ensure DAG structure (no cycles)

### Pour Issues

**Problem**: Pour fails to create beads
**Solution**: Check that beads is initialized (`/beads:init`)

**Problem**: Formula not found
**Solution**: Check `.choo-choo-ralph/config.yml` for formula configuration

### Ralph Loop Issues

**Problem**: Ralph immediately exits with "No ready tasks"
**Solution**: Check that tasks exist and have no unmet dependencies (`/beads:ready`)

**Problem**: Tasks keep getting blocked
**Solution**: Run `/beads:show <task-id>` to see failure details, fix underlying issue

**Problem**: Tests failing repeatedly
**Solution**: Run tests manually to understand failures, may need to fix test setup

### Harvest Issues

**Problem**: No learnings found
**Solution**: Ensure agents are using [LEARNING] and [GAP] comment format

**Problem**: Harvest plan is empty
**Solution**: Check completed tasks have comments, may need to review formula prompts

---

## Summary

| Step        | Who      | Command                        | Output                                              |
| ----------- | -------- | ------------------------------ | --------------------------------------------------- |
| **Plan**    | You      | (manual)                       | Plan document with goals, requirements, constraints |
| **Spec**    | You + AI | `/choo-choo-ralph:spec`        | Structured task list in `.choo-choo-ralph/`         |
| **Review**  | You      | Edit spec with `<review>` tags | Refined spec with clear, sized tasks                |
| **Pour**    | AI       | `/choo-choo-ralph:pour`        | Beads tasks ready for execution                     |
| **Ralph**   | AI       | `./ralph.sh`                   | Working code with atomic commits                    |
| **Harvest** | You + AI | `/choo-choo-ralph:harvest`     | Updated skills, docs, CLAUDE.md                     |

### Quick Start Checklist

- [ ] Create a plan document with clear requirements
- [ ] Run `/choo-choo-ralph:spec` to generate spec
- [ ] Review spec thoroughly, add `<review>` feedback
- [ ] Iterate on spec until all review tags empty
- [ ] Run `/choo-choo-ralph:pour` to create beads
- [ ] Test with `./ralph-once.sh`
- [ ] Run `./ralph.sh` for full execution
- [ ] Run `/choo-choo-ralph:harvest` after completion
- [ ] Review and approve harvest plan
- [ ] Commit harvested learnings

### Next Steps

- [Spec Format Reference](./spec-format.md) - Complete specification format documentation
- [Formulas Guide](./formulas.md) - Deep dive into execution formulas
- [Customization](./customization.md) - Tailoring Choo Choo Ralph to your project
