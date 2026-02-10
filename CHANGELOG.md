# Changelog

All notable changes to this project will be documented in this file.

## 0.3.0 - 2026-02-10

### Fixes
- Use `bd list --ready --type epic` instead of `bd ready` in ralph.sh and ralph-once.sh — `bd ready` blocker-aware semantics treats epics with open children as blocked, which prevents molecule orchestrators from picking them up
- Add guidance for `bd --no-daemon ready --mol <id>` to find ready steps within a molecule — `bd ready --parent <id>` incorrectly shows no results due to parent-child blocking semantics

### Notes
- Forked from mj-meyer/choo-choo-ralph v0.2.0

## 0.2.0 - 2026-01-28

### Features
- Add parallel execution support for running multiple Ralph instances without conflicts
