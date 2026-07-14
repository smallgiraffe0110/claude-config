---
name: default-to-high-effort
description: "User's standing default is HIGH effort (one level below MAX/xhigh); step up to MAX only when explicitly asked"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: db3ad2b0-9336-4f20-97f1-e22b1d900a9a
---

Default to HIGH effort on every task — strong thoroughness, analysis, and attention to detail, no shortcuts or lazy defaults. Step up to MAX (xhigh) only when explicitly asked.

**Why:** User set HIGH as the standing default on 2026-06-10, dialing back from a previous MAX-effort standing instruction. Configured via `effortLevel: "high"` in ~/.claude/settings.json; the old `CLAUDE_CODE_EFFORT_LEVEL=max` override was removed from ~/.zshrc.
**How to apply:** Approach tasks with deep analysis and meticulous attention to detail at the HIGH level. Reserve MAX/xhigh for tasks where the user explicitly requests it.
