---
name: project-flathead-exo
description: Flathead EXO (EXO 2nd Brain) — Supabase RLS-governed index over a private markdown vault (Supabase Storage); captures MS365 email + Granola notes
metadata: 
  node_type: memory
  type: project
  originSessionId: cc9344dd-c0a2-4d8e-8cea-5ec1e6ad86cc
---

Flathead EXO (`~/code/flathead-exo`) = the **EXO 2nd Brain** for Flathead Forge (VC
fund). Multi-tenant, RLS-governed Postgres **index** over a markdown knowledge vault
(canonical = markdown files in a **private Supabase Storage bucket** — Option B, no GitHub
for v1), with a capture layer pulling email + Granola notes. Gated to @flatheadforge.com.

**Authoritative source files** (vendored at `docs/superpowers/inputs/`): the principal
provided `exo_foundation_schema.sql` (Supabase Phase-1 spine) + `ARCHITECTURE_GROUNDRULES.md`.
"If a rule conflicts with convenience, the rule wins." These OVERRODE the original CF
design — re-founded 2026-06-10.

**Stack (decided):** Supabase — Postgres + pgvector + RLS + Auth (Azure provider) +
**Vault** (secrets) + **Edge Functions** (Deno) + pg_cron/pg_net. Next.js + `@supabase/ssr`
frontend (Vercel). Capture runtime = Supabase-native. P1 email source = **Outlook/MS365**.

**Five load-bearing rules:** (1) tenant_id + tier (T0–T3) on every table day one;
(2) RLS written with every table, never off; (3) permission and sensitivity are TWO axes,
never one `role`; (4) DB is the INDEX — canonical = markdown files (Supabase Storage vault), rebuildable;
(5) auth identity ≠ tenant identity ≠ agent identity. Plus: secrets in Vault by handle
(NEVER in a table the model reads), NO hard deletes (archived_at + version), append-only
audit_log wired day one, tier-classify BEFORE any cloud model. **No Mac mini** (decided):
T3 = kept in a **private silo** — owner-only RLS partition of the vault (`_silo/` path),
content_md null, excluded from cloud AI (stored ≠ processed); `deployment_target` seam retained.
**Secret list** = per-tenant `tier_rules` table (RLS owner-only — itself a private silo);
classifier reads it. Vault writer = SupabaseStorageVaultWriter (private `vault` bucket).

**Capture pattern:** capture → normalize → entity-link → extract → store → act.
**Acceptance test = P1 definition of done:** seed Principal + Partner, write a T3 entity
owned by Principal, query as Partner → ZERO rows via RLS (not app code). If it fails, stop.

**Phasing:** P1 = foundation schema + RLS acceptance test + gated Supabase-Auth onboarding
(login→partner tenant + read-grants only + audit) + Outlook capture spine (normalize→tier→
versioned store, Vault token, pg_cron poll) + RLS-scoped dashboard. P2 = Granola (key→Vault) +
backfill window. P3 = entity-link (NER) + task extraction. P4 = embeddings + pgvector search.

**UI:** split-screen (provided mock) — left form panel, right swappable placeholder hero;
title "Get started with Flathead EXO"; one "Continue with Microsoft" button (Azure OAuth).

Spec: `docs/superpowers/specs/2026-06-10-flathead-exo-design.md` (v2). Plan:
`docs/superpowers/plans/2026-06-10-flathead-exo-p1.md` (v2). Status: **P1 code-complete + merged
to `main`** (commit ac3c212), built subagent-driven (14 tasks, each spec+quality reviewed + a
final holistic review). Runnable gates PASS: 9 Deno unit tests (tier/graph/markdown), web
`tsc --noEmit` + `next build`. DB-backed gates (migrations apply, the RLS acceptance test =
P1 definition-of-done, integration/e2e) are WRITTEN but UNRUN — no Docker in the build env;
**hunter must run them + do the hosted Azure/Supabase/Vercel deploy per `README.md`**.
RESOLVED: principal=hunter@flatheadforge.com,
vault=Supabase Storage (Option B). Open: hunter's initial tier_rules entries (or seed empty);
per-account silos via additive `capture_items_owner_read` (each account reads its OWN T3;
cross-account sealed). Open sub-q: should principal see OTHER accounts' silos (default yes). Shares no
infra with [[project-todolist-app]] anymore (that's CF; this is Supabase).
