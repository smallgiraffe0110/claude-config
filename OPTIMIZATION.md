# Claude Code Optimization Playbook

Everything learned about making this Claude Code setup as capable as possible,
distilled from web research (2026) + tailored to this config. The model is
already maxed (**Opus 4.8 / `xhigh` effort**) — so every remaining gain is in the
**harness**: verification, grounding, context discipline, and tool hygiene.

Status key: ✅ live in this repo · 🔜 recommended next · 🧪 optional / situational

---

## The one principle

> Verification is the single highest-leverage practice. Give Claude a way to check
> its own output and quality jumps measurably. CLAUDE.md instructions are followed
> ~70% of the time; **hooks enforce at 100%** because they can't be reasoned around.

Second principle: **context is the budget.** Quality degrades past ~75% context
utilization even as raw output rises. Protect the window.

---

## ✅ Implemented

| Lift | What | Where |
|---|---|---|
| **Top model + effort** | `claude-opus-4-8`, `effortLevel: xhigh` | `settings.json` |
| **Verification hooks** | eslint `--fix` per edit; `tsc --noEmit` at turn-end, **blocks** on type errors; bails outside JS/TS | `hooks/verify.js` + `settings.json` |
| **Context7 MCP** | real-time, version-specific library docs → kills hallucinated/outdated APIs | user scope (`~/.claude.json`), added by `setup.sh` |
| **Lean CLAUDE.md** | only what Claude would get wrong; verification + context7 guidance | `CLAUDE.md` |
| **Persistent memory** | native auto-memory + `memory/MEMORY.md` index | `memory/` |
| **Skill plugins** | superpowers (TDD, debugging, brainstorming), frontend-design, vercel, startup-skills, caveman | `settings.json` |
| **Browser/QA** | gstack `/browse` + qa/design-review/ship skills | gstack install |

---

## 🔜 Recommended next (cheap, high ROI)

- **Prune the active MCP tool surface.** Past ~40–50 visible tools the model picks
  the wrong one. This setup has ~7 connectors (Canva, Gmail, Calendar, Drive,
  Notion, M365, Vercel) + Context7. Keep **4–6 hot per project**; disable the rest
  per-project. Canva is already disabled in `settings.local.json` — same pattern.
- **Context hygiene as habit:**
  - Stop around **75%** context, not 90%. Use `/context` to see token spend, `/compact` to continue lean.
  - **Scope investigations to subagents** (`Agent`/`Explore`/`Workflow` tools) so big searches don't flood the main window — get back the summary, not the file dump.
- **Visual verification loop for frontend.** Screenshot the result, compare to the
  mock → ~2–3× quality on UI work. gstack `/browse` + frontend-design already
  enable this; make it the default loop for UI changes.
- **Plan mode for risky/multi-file changes.** Cost of planning ≪ cost of rolling
  back a bad multi-file change.

## 🧪 Optional / situational (the menu of new ideas)

- **Serena MCP** — semantic, symbol-level code retrieval + editing (not grep).
  Worth it on large repos; pairs naturally with Context7.
- **Sequential-thinking MCP** — structured, revisable multi-step reasoning for
  genuinely hard decisions.
- **TDD Guard hook** (`nizos/tdd-guard`) — PreToolUse hook that blocks edits which
  skip red-green. superpowers already ships a TDD *skill*; add the hook only if you
  want it enforced architecturally.
- **Agent Teams** (experimental) — multiple coordinated Claude Code sessions
  (lead + read-only-planning teammates). Enable with
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Heavier than the built-in `Workflow`
  tool; reach for it only when one context can't hold the work.
- **claude-mem** (`thedotmack/claude-mem`) — 3-layer compressed cross-session
  memory, ~10× token-efficient recall. **Redundant** with native auto-memory +
  `MEMORY.md` here — skip unless you outgrow the native system.

---

## How the verification hook behaves (quick ref)

- `PostToolUse(Edit|Write|MultiEdit)` → `eslint --fix` the changed file; surfaces
  remaining problems to Claude.
- `Stop` (turn end) → `npm run typecheck` (if defined) else `npx tsc --noEmit`;
  **blocks the turn** on type errors so they get fixed before hand-off.
- Uses only `node_modules/.bin` (never installs), **instant no-op** when there's no
  `package.json`/`tsconfig.json`, loop-guarded via `stop_hook_active`.
- To soften to advisory: remove the `Stop` block in `settings.json` (keeps eslint).

## Tuning Context7

Say **"use context7"** in a prompt when working against any library API. Optional
API key at `context7.com/dashboard` raises rate limits. Add it as a header:
`claude mcp add --transport http --scope user context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: <key>"`.

---

## Sources

- [Anthropic — Best practices](https://code.claude.com/docs/en/best-practices)
- [Claude Code power-user tips](https://support.claude.com/en/articles/14554000-claude-code-power-user-tips)
- [Hooks / subagents / skills guide](https://ofox.ai/blog/claude-code-hooks-subagents-skills-complete-guide-2026/)
- [Context engineering guide](https://www.generative.inc/the-complete-claude-code-guide-2026-planning-context-engineering-and-high-leverage-development)
- [Best MCP servers 2026](https://www.bannerbear.com/blog/8-best-mcp-servers-for-claude-code-developers-in-2026/)
- [Context7](https://claude.com/plugins/context7) · [Serena/sequential-thinking setup](https://robertmarshall.dev/blog/turning-claude-code-into-a-development-powerhouse/)
- [TDD Guard](https://github.com/nizos/tdd-guard) · [claude-mem](https://github.com/thedotmack/claude-mem) · [Agent Teams](https://code.claude.com/docs/en/agent-teams)
