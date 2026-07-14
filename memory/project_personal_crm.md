---
name: project-personal-crm
description: "Orbit — Hunter's single-user message-first personal CRM at ~/code/personal-crm, forked from Flathead EXO"
metadata: 
  node_type: memory
  type: project
  originSessionId: 53ecc42f-4393-46bd-8c37-6c363f37b896
---

**Orbit** (`~/code/personal-crm`) = Hunter's **personal CRM**, message-first, forked from
[[project-flathead-exo]] (the fund "second brain") on 2026-06-22. Goal: capture inbound
messages (iMessage/SMS + LinkedIn) to track what people message him about and nurture
long-term relationships. "Orbit" is a placeholder brand name (easily renamed).

**Confirmed decisions:** (1) fork EXO + strip to single user; (2) channels = iMessage/SMS
(local Mac chat.db) + LinkedIn (data-export import); email/manual deferred; (3) cloud
Supabase + Vercel with a local Mac agent pushing chat.db deltas; (4) de-tenant strategy =
**NEUTRALIZE not rip** — keep the 49 migrations + RLS, but provision exactly ONE principal
tenant, gate login to `PRINCIPAL_EMAIL` (email+password, Azure disabled), default all tiers
T1/cloud. Plan file: `~/.claude/plans/hazy-stirring-bumblebee.md`.

**DEPLOYED LIVE (2026-06-22) at https://crm.hunterearls.dev.** Supabase = reused the
empty **"The Brain"** project (`alohxgsbjrpoojiizqjp`, us-east-1) — migrations 0001-0050
applied via Management API (the broken fund migration 0049 was neutralized to a no-op);
`message-ingest` edge fn deployed with `INGEST_TOKEN` secret; auth = email+password,
auto-confirm on. Web = Vercel project `orbit-crm` (smallgiraffe0110), custom domain
`crm.hunterearls.dev` via Cloudflare CNAME→cname.vercel-dns.com (DNS-only) + Let's Encrypt.
Owner account = **hunter@hunterearls.dev** (auth user created + principal tenant claimed
via SQL). End-to-end ingest verified (synthetic message → contact/thread/dedup, then wiped).
Secrets in `~/code/personal-crm/.deploy-secrets.env` (gitignored). Hunter's CF API token +
R2 keys were pasted in chat 2026-06-22 — SHOULD BE ROTATED. Remaining live step: grant Full
Disk Access + run `agent/imessage-sync` (npm run sync) to pull real iMessages.

**Earlier status: P0 + P1 code-complete & green.**
- P0: single-user auth (`apps/web/src/lib/onboarding.ts` rewritten), sign-in page + nav
  rebranded (Home/Contacts/Messages/Notes), fund badges → personal types
  (`relationship-tags.ts`), fund routes hidden from nav (still on disk). `tsc`+`next build` green.
- P1 message core: migration `0050_messages.sql` (contact_handles / message_threads /
  messages + rollup trigger); edge fn `message-ingest` + `_shared/messages.ts` (handle→entity
  resolution, dedup; `deno check` clean); local Mac agent `agent/imessage-sync/` (reads
  chat.db, Apple-epoch conversion, 6 unit/fixture tests pass — live read blocked only by Full
  Disk Access); web Messages feed at `/inbox` (`messages-view.tsx`, `lib/messages.ts`,
  `/api/messages/thread/[id]`).

**v2 SHIPPED (2026-06-22): focused intelligent CRM, live with real data.** Reshaped per
Hunter: (1) agent now skips 4+-person group chats + caps 100 most-recent msgs/contact, no
cursor (`readCappedMessages`); (2) Apple Contacts importer (`agent/.../contacts.ts` +
`sync-contacts` + `contacts-ingest` fn + `_shared/contacts.ts`) — 317 named contacts imported,
so messages resolve to real names not phone numbers; (3) dropped `uq_entities_live_name`
(0051 — contacts dedup by HANDLE not name); (4) relationship scoring (`lib/relationship.ts`:
recency×frequency×reciprocity score, last-talked, in/out, reach-out queue) surfaced in a clean
new Contacts UI (`contacts-view.tsx`) + CRM Home dashboard; (5) per-contact notes (0052 +
`/api/contacts/[id]`); (6) STRIPPED all fund modules (agents/automations/vault/research/
pipeline/approvals/outputs/todos) — nav = Home/Contacts/Messages. Live data: 317 contacts,
2269 messages, 103 people messaged, 113 threads. INGEST batches kept small (msgs 75, contacts
40) to stay under the edge resource limit. Re-run sync anytime: `cd agent/imessage-sync &&
npm run sync-contacts && npm run sync`.

**Auth = todo-style (2026-06-22):** Replaced Supabase Auth with the SAME mechanism as
[[project-todolist-app]]'s todolist (`~/code/hunterearls-dev/todolist`): jose HS256 JWT in an
HttpOnly cookie (`crm_session`), env-secret creds (`OWNER_EMAIL`/`OWNER_PASSWORD`/`AUTH_SECRET`
in Vercel), `/login` page + server action, middleware gate, logout in sidebar. No signup.
Supabase is now DB-ONLY: `supabaseServer()` returns the SERVICE-ROLE client (RLS bypassed,
single owner), `getCallerContext()` resolves the one principal tenant (no Supabase session).
Login is **username + password** (not email), no signup, app name is just **"CRM"** (not
Orbit). Creds: username **hunter** / **PotatoSalad!** (Vercel env `OWNER_USERNAME` + `OWNER_PASSWORD`). Data
pages are `force-dynamic`. Project lives at `~/code/personal-crm` (could move under
`~/code/hunterearls-dev/` beside todolist if desired — not done).

**EXO directory view restored (2026-06-22):** `/people` (Contacts) now renders the original
EXO dense "Attio" `PeopleView` (Avatar + SparkBars sparkline + TagPills + relationship score +
last-touch + profile drawer), powered by MESSAGE data. Keystone: `loadActivity()` in
`lib/people.ts` repointed from `crm_interactions` → `messages` (so score/sparkline/last-touch
reflect texts). All contacts are scope "directory" (single-user, no shared/private split);
fund UI removed (Ask EXO, Orgs, lead lists). PersonDrawer shows the message thread + notes
(`contact_profiles.notes`). `api/people/[id]` had its `auth.getUser` 401 gates removed (jose
arch). `contacts-view.tsx`/`relationship.ts` now orphaned (dashboard still uses relationship.ts).
Verified live: authed /people = 200, 478 sparklines, real names render.

**Reject-all + enrichment wired (2026-06-22):** Review queue has a "Reject all" button; the
EXO enrichment flow is re-enabled (per-contact Enrich in the drawer + batch update + proposals
review). The enabling fix: ALL `api/people` + `api/crm` routes had dead `supabase.auth.getUser()`
401 gates — replaced with `getSession()` across ~18 routes (jose arch). GOTCHA fixed: setting
`PRINCIPAL_EMAIL=hunter` (to satisfy `canViewWireframes` which compares to it) broke the root
layout's `assertServerEnv()` (required `@`) → every page 500'd. Fix = relaxed `lib/env.ts` to
only require `NEXT_PUBLIC_SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` (dropped the
PRINCIPAL_EMAIL/@ guard — it protected dead Supabase-Auth tenant-claim). Also deleted stale
`apps/web/.env` + `.env.local` (localhost/sb_secret leftovers that polluted local `next start`;
both gitignored, never deployed). Debug tip: real CRM config = `.deploy-secrets.env` + Vercel.
Enrichment is LIVE but inert until `BRAVE_SEARCH_API_KEY` + `OPENROUTER_API_KEY` set in Vercel.

**AI contact descriptions LIVE (2026-06-22):** DeepSeek V4 flash (`deepseek/deepseek-v4-flash`,
"V4 lite") via OpenRouter reads each contact's real message history → writes a 2-3 sentence
"who they are + what you talk about" description into `contact_profiles.description`
(origin='ai'), shown in the EXO drawer/directory. `OPENROUTER_API_KEY` + `CRM_UPDATE_MODEL`
set in Vercel. Backfilled 39 contacts (≥3 msgs) via `apps/web/scripts/describe-contacts.mjs`
(run: `cd apps/web && source ../../.deploy-secrets.env && node scripts/describe-contacts.mjs`).
In-app per-contact **"Describe from messages"** button → `POST /api/people/[id]/describe`
(live, verified). EMBEDDINGS DONE — OpenRouter DOES serve embeddings (`POST /api/v1/embeddings`,
`openai/text-embedding-3-small`, 1536-dim, same key). Backfilled `entities.embedding` from
name+description via `apps/web/scripts/embed-contacts.mjs` (40 contacts). pgvector
`search_contacts(query_embedding vector(1536), match_count)` RPC (migration 0053). Endpoint
`POST /api/people/search {query}` embeds query → RPC → ranked contacts. UI = "Search by meaning"
bar (`semantic-search.tsx`) atop the Contacts page (PeopleView root changed h-screen→h-full,
page wraps in flex-col). Verified live: "gaming"→Johny Rigney, "marketing/business"→DyLon/Mike.
**"Fix everything, no more envs" pass (2026-06-22):** Made the AI layer self-sustaining on
ONLY the OpenRouter key. (1) Removed the dead Brave "Enrich" button from the drawer (+ disabled
the EXO web "update all" UI: page.tsx `canRunContactUpdate={false}`, `updateProposals={[]}`) —
no Brave key needed anywhere. (2) Shared helper `lib/ai-server.ts` (`describeAndEmbed`,
`embedToVector`, `describeFromMessages`); the per-contact Describe route now AUTO-EMBEDS, so
describing keeps semantic search current (verified 50 described = 50 embedded). (3) New batch
`POST /api/people/describe-all` (describe+embed undescribed contacts w/ ≥3 msgs, 6/call) + a
"Describe new" button in the Contacts top bar that loops it → one-click catch-up for new
contacts, no scripts/cron. Local scripts `describe-contacts.mjs`/`embed-contacts.mjs` still
exist as fallback but aren't needed. Brave web/LinkedIn enrichment still needs
`BRAVE_SEARCH_API_KEY` (the "Enrich" button is web-search; the new "Describe" button is
message-based and is the more valuable one for personal contacts).

**LinkedIn import BUILT (2026-06-22):** No LinkedIn API exists — uses the official "Get a copy
of your data" export. `contacts-ingest`/`_shared/contacts.ts` extended: IncomingContact now
takes `linkedin` (→ linkedin handle), `role`, `description` (won't clobber a message-based
desc); redeployed. Local importer in `agent/imessage-sync`: `src/linkedin.ts` (parse) +
`src/import-linkedin.ts` (CLI, reads zip via adm-zip OR folder; finds Connections/messages/
Profile.csv) → POSTs contacts-ingest + message-ingest (channel='linkedin'). Cross-channel
merge via shared email/handle. Run: `npm run import-linkedin:dry -- /path/export.zip` (preview)
then `npm run import-linkedin -- /path/export.zip`. 11 tests pass. NOT yet run on real data
(Hunter must request+download his LinkedIn export first; connections ~10min, messages ~24h).

**Still open:** Brave web enrichment (#12) needs `BRAVE_SEARCH_API_KEY` + `OPENROUTER_API_KEY`/
`LLM_API_KEY` as Vercel+function secrets (code exists in `crm-intelligence.ts`/`enrich.ts`);
orphaned old fund UI files (people-view.tsx etc.) still on disk (unused, compile clean) —
optional cleanup; schedule the agent via the launchd plist for ongoing sync.

Shares no infra with [[project-flathead-exo]] (separate repo/Supabase project). Build per
Hunter's stack: Next.js App Router + TS strict + Tailwind + npm.
