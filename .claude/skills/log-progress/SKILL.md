---
name: log-progress
description: >
  This skill should be used when the user asks to "log progress",
  "save progress", "write a log", "session summary", "end session",
  or "wrap up". Also use when the user says goodbye or indicates they
  are finishing work. Creates a timestamped progress log entry in the
  ./log/ directory to preserve context across sessions.
---

# Log Progress

Create a new file at `./log/YYYYMMDD_HHMM_<short_slug>.md` using the current date/time and a brief slug describing the session focus.

Use this template:

```markdown
# Session Log: <Title>

**Date:** YYYY-MM-DD
**Session focus:** <One-line summary>

---

## Work Completed

### 1. <First area of work>
<Description of what was done, key results, tables, figures>

### 2. <Second area of work> (if applicable)
<Description>

---

## Current State

- <Bullet points describing where things stand now>

## Decisions Made

- <Key decisions and their rationale>

## Issues / Blockers

- <Any unresolved problems> (or "None" if clear)

## Next Steps

- <What should be done next>
```

## Guidelines

- Review the conversation history to capture all significant work
- Include key results, tables, and figures when relevant
- Be specific about file paths and changes made
- Keep entries concise but complete enough for context recovery
- Check existing logs in `./log/` to avoid duplicating recent entries
