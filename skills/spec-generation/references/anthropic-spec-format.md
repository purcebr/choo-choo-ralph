# Anthropic Autonomous Coding Agent Specification Format

This document describes the XML-like specification format used by Anthropic's autonomous coding research for defining software projects. The format provides structured guidance to AI coding agents, enabling them to build complete applications autonomously.

## Overview

The specification format uses XML-like tags to organize project information into logical sections. This structure helps AI agents:

- Understand the full scope before starting
- Navigate between related concerns
- Track implementation progress
- Maintain consistency across features

## YAML Frontmatter

Every spec file MUST start with YAML frontmatter before the XML content:

```yaml
---
title: "Project Name"
created: 2026-01-11
poured: []
iteration: 1
auto_discovery: false
auto_learnings: false
---
```

- **title**: Human-readable name (matches `<project_name>`)
- **created**: Date created (use `date +%Y-%m-%d` bash command)
- **poured**: Array of root bead IDs created by `/pour` (starts empty)
- **iteration**: Refinement count (1 = initial, increments on each `/spec` refinement)
- **auto_discovery**: (optional, default: `false`) Enable auto task creation from discovered gaps during implementation
- **auto_learnings**: (optional, default: `false`) Enable auto skill creation from learnings captured during implementation

---

## Root Element

```markdown
---
title: "My Application"
created: 2026-01-11
poured: []
iteration: 1
auto_discovery: false
auto_learnings: false
---
<project_specification>
  <!-- All sections go here -->
</project_specification>
```

The root `<project_specification>` element wraps the entire specification, following the YAML frontmatter.

---

## Core Sections

### project_name

**Purpose**: A brief, descriptive title for the project.

```xml
<project_name>My Application - Brief Description</project_name>
```

**Guidance**:
- Keep it concise but descriptive
- Include a subtitle if helpful for context
- This becomes the canonical name referenced throughout

---

### overview

**Purpose**: High-level description of what to build and why.

```xml
<overview>
  Build a [type of application] that [main purpose]. The application should
  provide [key capabilities] including [feature highlights]. The UI should
  [design direction] with a focus on [user experience priorities].
</overview>
```

**Guidance**:
- 2-4 sentences covering scope and goals
- Mention primary user value proposition
- Include key design direction or inspiration
- Set expectations for quality and style

**Scaling**:
- Simple feature: One sentence describing the addition
- Full app: Full paragraph covering scope, goals, and approach

---

### technology_stack

**Purpose**: Define all technologies, frameworks, and tools to use.

```xml
<technology_stack>
  <frontend>
    <framework>React with Vite</framework>
    <styling>Tailwind CSS</styling>
    <state_management>React hooks and context</state_management>
    <port>Only launch on port 3000</port>
  </frontend>
  <backend>
    <runtime>Node.js with Express</runtime>
    <database>SQLite with better-sqlite3</database>
    <api_integration>External API name</api_integration>
  </backend>
  <communication>
    <api>RESTful endpoints</api>
    <streaming>SSE for real-time updates</streaming>
  </communication>
</technology_stack>
```

**Common Sub-sections**:
- `<frontend>` - UI framework, styling, state management, routing
- `<backend>` - Runtime, database, external integrations
- `<communication>` - How frontend and backend communicate
- `<api_key>` - Special instructions for API key handling
- `<testing>` - Test frameworks and approaches

**Guidance**:
- Be specific about versions if they matter
- Include port numbers and environment constraints
- Mention CDN vs npm for styling libraries
- Specify any required external services

---

### prerequisites

**Purpose**: Environment setup and assumptions before implementation.

```xml
<prerequisites>
  <environment_setup>
    - Repository includes .env with required keys configured
    - Dependencies pre-installed via npm/pnpm
    - Specific directory structure expectations
    - Required CLI tools or services
  </environment_setup>
</prerequisites>
```

**Guidance**:
- List what should already exist
- Specify directory conventions
- Mention any pre-configured resources
- Document assumptions about the environment

---

### core_features

**Purpose**: Detailed breakdown of all features to implement.

```xml
<core_features>
  <feature_category_name>
    - Feature item with description
    - Another feature with key details
    - Sub-feature that supports the category
  </feature_category_name>

  <another_category>
    - Features organized by domain
    - Related functionality grouped together
  </another_category>
</core_features>
```

**Common Categories**:
- `<main_interface>` - Primary user-facing functionality
- `<data_management>` - CRUD operations, storage
- `<user_settings>` - Preferences, customization
- `<advanced_features>` - Power user capabilities
- `<accessibility>` - A11y requirements
- `<responsive_design>` - Mobile/tablet considerations

**Guidance**:
- Group related features logically
- Use bullet points for individual items
- Be specific about behavior, not just names
- Include edge cases and special states
- Order from most to least important within categories

**Scaling**:
- Simple feature: Single category with 3-5 items
- Full app: Multiple categories covering all aspects

---

### database_schema

**Purpose**: Define all data models and their relationships.

```xml
<database_schema>
  <tables>
    <table_name>
      - id (primary key convention)
      - field_name, another_field, etc.
      - foreign_key_id (relationship to other_table)
      - created_at, updated_at
      - json_field (JSON: description of structure)
    </table_name>

    <related_table>
      - id, parent_table_id
      - specific_fields
      - metadata (JSON array or object)
    </related_table>
  </tables>
</database_schema>
```

**Guidance**:
- List tables as separate child elements
- Use bullet points for fields
- Note JSON fields with structure hints
- Include timestamp fields for auditing
- Document foreign key relationships
- Add notes for complex field types

**Scaling**:
- Simple feature: May not need this section
- Full app: Complete data model with all tables

---

### api_endpoints_summary

**Purpose**: Define the API contract between frontend and backend.

```xml
<api_endpoints_summary>
  <resource_name>
    - GET /api/resources
    - POST /api/resources
    - GET /api/resources/:id
    - PUT /api/resources/:id
    - DELETE /api/resources/:id
    - POST /api/resources/:id/action
  </resource_name>

  <another_resource>
    - Standard CRUD endpoints
    - Special action endpoints
    - Streaming endpoints (SSE)
  </another_resource>
</api_endpoints_summary>
```

**Guidance**:
- Group by resource/domain
- Follow REST conventions
- Note special endpoints (streaming, file upload)
- Include authentication endpoints
- Document query parameters for search/filter

**Scaling**:
- Simple feature: May only add to existing API
- Full app: Complete API surface

---

### ui_layout

**Purpose**: Describe the visual structure and organization.

```xml
<ui_layout>
  <main_structure>
    - Overall layout description (columns, panels)
    - Responsive behavior summary
    - Key structural components
  </main_structure>

  <component_area>
    - Elements in this area
    - Interactive components
    - State-dependent variations
  </component_area>

  <modals_overlays>
    - Modal dialogs and their purposes
    - Overlay patterns
  </modals_overlays>
</ui_layout>
```

**Common Sub-sections**:
- `<main_structure>` - Overall page layout
- `<header>` / `<sidebar>` / `<footer>` - Persistent navigation
- `<main_content>` - Primary content area
- `<panels>` - Secondary content areas
- `<modals_overlays>` - Modal dialogs and overlays

**Guidance**:
- Describe spatial relationships
- Note responsive breakpoints
- Include interactive elements
- Mention empty states and loading states

---

### design_system

**Purpose**: Visual design specifications for consistency.

```xml
<design_system>
  <color_palette>
    - Primary: description (#hexcode)
    - Background: light and dark variants
    - Text: primary and secondary colors
    - Accent: interactive element colors
    - Semantic: error, success, warning colors
  </color_palette>

  <typography>
    - Font families (primary, monospace)
    - Heading styles
    - Body text specifications
    - Code formatting
  </typography>

  <components>
    <component_type>
      - Variant descriptions
      - State specifications
      - Sizing and spacing
    </component_type>
  </components>

  <animations>
    - Transition durations
    - Animation patterns
    - Loading states
  </animations>
</design_system>
```

**Guidance**:
- Provide specific color values when available
- Reference design inspiration if applicable
- Include both light and dark mode values
- Specify component variants and states
- Document animation timing

**Scaling**:
- Simple feature: May inherit from existing system
- Full app: Complete design system definition

---

### key_interactions

**Purpose**: Document critical user flows step by step.

```xml
<key_interactions>
  <flow_name>
    1. User initiates action
    2. System responds with feedback
    3. Data is processed/saved
    4. UI updates to reflect change
    5. User can proceed to next action
  </flow_name>

  <another_flow>
    1. Sequential steps
    2. Including edge cases
    3. And error handling
  </another_flow>
</key_interactions>
```

**Guidance**:
- Number steps sequentially
- Include both user and system actions
- Cover happy path and key error cases
- Document feedback and state changes
- Focus on complex or critical flows

---

### implementation_steps

**Purpose**: Ordered phases for building the project.

```xml
<implementation_steps>
  <step number="1">
    <title>Setup and Foundation</title>
    <tasks>
      - Initialize project structure
      - Set up database and models
      - Create basic API scaffolding
      - Implement health check
    </tasks>
  </step>

  <step number="2">
    <title>Core Functionality</title>
    <tasks>
      - Build primary feature
      - Implement main UI component
      - Connect frontend to backend
      - Add basic styling
    </tasks>
  </step>

  <!-- Additional steps... -->
</implementation_steps>
```

**Guidance**:
- Order from foundational to polish
- Group related tasks in each step
- Each step should be independently testable
- Include both frontend and backend tasks
- End with polish, optimization, and edge cases

**Common Phase Pattern**:
1. Project setup and database
2. Core feature implementation
3. Additional features
4. Organization/management features
5. Advanced features
6. Settings and customization
7. Sharing/collaboration
8. Polish and optimization

---

### success_criteria

**Purpose**: Define what "done" looks like.

```xml
<success_criteria>
  <functionality>
    - Core features work as specified
    - All CRUD operations functional
    - Error handling in place
    - Edge cases handled
  </functionality>

  <user_experience>
    - Interface is intuitive
    - Responsive on all devices
    - Fast performance
    - Clear feedback for actions
  </user_experience>

  <technical_quality>
    - Clean code structure
    - Proper error handling
    - Security best practices
    - Optimized performance
  </technical_quality>

  <design_polish>
    - Consistent visual style
    - Smooth animations
    - Accessibility compliance
    - Professional appearance
  </design_polish>
</success_criteria>
```

**Common Categories**:
- `<functionality>` - Features work correctly
- `<user_experience>` - Usability and feel
- `<technical_quality>` - Code and architecture
- `<design_polish>` - Visual refinement

**Guidance**:
- Be specific and measurable where possible
- Cover all major quality dimensions
- Include both technical and user-facing criteria
- Set appropriate bar for the project scope

---

## Scaling the Format

### For Simple Features

Minimal spec with essential sections only:

```markdown
---
title: "Add Dark Mode Toggle"
created: 2026-01-11
poured: []
iteration: 1
auto_discovery: false
auto_learnings: false
---
<project_specification>
  <project_name>Add Dark Mode Toggle</project_name>

  <overview>
    Add a theme toggle to the settings panel that switches between
    light and dark modes, persisting the preference to localStorage.
  </overview>

  <core_features>
    <theme_toggle>
      - Toggle button in settings
      - Immediate visual switch
      - Preference persistence
      - System preference detection
    </theme_toggle>
  </core_features>

  <success_criteria>
    <functionality>
      - Theme switches instantly on toggle
      - Preference persists across sessions
      - Respects system preference on first visit
    </functionality>
  </success_criteria>
</project_specification>
```

### For Full Applications

Include all sections with comprehensive detail:

- Complete `<technology_stack>` with all layers
- Full `<database_schema>` with all tables
- Comprehensive `<api_endpoints_summary>`
- Detailed `<ui_layout>` for all views
- Complete `<design_system>` with colors, typography, components
- Multiple `<key_interactions>` for all major flows
- 8-10 `<implementation_steps>` covering full build
- Multi-category `<success_criteria>`

---

## Best Practices

### Clarity
- Use specific, actionable language
- Avoid ambiguity in feature descriptions
- Provide examples for complex concepts

### Completeness
- Cover all aspects of the feature/application
- Don't assume knowledge - be explicit
- Include error states and edge cases

### Organization
- Group related items together
- Order sections logically
- Use consistent formatting

### Flexibility
- Allow for implementation decisions
- Focus on "what" not always "how"
- Leave room for agent judgment on details

---

## Usage Notes

This format is designed for autonomous AI coding agents. The structure:

1. **Enables top-down planning** - Agent can read entire spec first
2. **Supports incremental implementation** - Steps provide natural phases
3. **Provides reference material** - Agent can look up details as needed
4. **Defines completion** - Success criteria establish the finish line

The XML-like structure is not parsed formally - it's a documentation pattern that provides clear organization while remaining human-readable.
