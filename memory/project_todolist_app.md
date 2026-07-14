---
name: project-todolist-app
description: "hunterearls-dev/todolist — deployed collaborative todo app, deploy workflow, and the agreed phase-4 next step"
metadata: 
  node_type: memory
  type: project
  originSessionId: 55bcdc96-2670-424b-a92f-1b98561c0243
---

**~/code/hunterearls-dev/todolist** — Next.js 16 todo app, started as a Collect UI rebuild, now a deployed multi-tenant collaborative hub. Live at **https://todo.hunterearls.dev** on Cloudflare Workers (OpenNext) + D1.

Built in phases, each spec'd + planned in `docs/superpowers/` and shipped via subagent-driven TDD with per-task spec+quality review:
- **Phase 1** — sidebar workspace hub (Personal + project workspaces), task/section CRUD, dnd-kit drag, task detail popover, localStorage.
- **Phase 2** — Cloudflare deploy, D1 + Drizzle, credential auth (owner email+password) → jose JWT cookie, server-action repo behind the same signatures, focus/15s sync, completed-tab linger.
- **Phase 3** — per-workspace access codes (member session scoped to one workspace via `{role:"member",workspaceId}`, codes hashed `sha256(code+AUTH_SECRET)`, owner sets/rotates in a settings panel, write-only — plaintext shown once), task name-labels (managed per-workspace list, colored chips, picker), mobile responsive fixes.

**Auth model:** owner = Hunter (HUNTER_EMAIL/HUNTER_PASSWORD Worker secrets, sees everything). Team members log in with a per-workspace access code (no individual accounts), scoped server-side to that one workspace. `core.ts` is the sole writer; every mutation is access-gated on `session.workspaceId`/`assertOwner`.

**Deploy workflow (operational, not in repo):** Cloudflare API token + account id live in a gitignored `.cf-deploy-creds` at the project root (`export CLOUDFLARE_API_TOKEN=…` / `export CLOUDFLARE_ACCOUNT_ID=…`). To deploy: `source .cf-deploy-creds && npm run deploy`. Remote D1 migrations: `source .cf-deploy-creds && npx wrangler d1 migrations apply todolist --remote`. The 5 app secrets (AUTH_SECRET, HUNTER_EMAIL/PASSWORD, TEAM_DOMAIN/PASSWORD — last two now unused) are Worker secrets set via `wrangler secret put`.

**Agreed next step — Phase 4 (deferred, not started):** give an agent/Claude Code easy access to the todo list. Build order: (1) an owner **bearer-token API** — teach `/api/snapshot` (read) + a few mutation endpoints to accept `Authorization: Bearer <token>` → owner access; (2) an **MCP server** wrapping it (`list_tasks`/`add_task`/`complete_task`/`assign_label`) so Claude Code can query the list conversationally. Token from option 1 authenticates the MCP server. See [[project_claude_config_repo]] for the related config-backup project.
