# User-Level Instructions

## Effort Level
- **ALWAYS use MAX effort.** Every task gets the absolute highest level of thoroughness, analysis, and attention to detail. No shortcuts, no lazy defaults, no holding back. Push beyond "good enough" to the best possible outcome.

## Projects Home
- All my code repos live in **`~/code`**. Treat it as the workspace root.
- **New projects go in `~/code/<name>`.** When creating a new project/app/repo, scaffold it under `~/code/` unless I give an explicit path. Don't create projects in `~` or `~/Downloads`.
- Shell helpers exist: `newproj <name>` (mkdir + git init in ~/code) and `newnext <name>` (create-next-app in ~/code). Repos are tracked with `gita` (`repos` = status of all).

## Tech Stack
- **Framework:** Next.js (App Router preferred)
- **Language:** TypeScript (strict mode)
- **UI:** React with functional components and hooks
- **Styling:** Tailwind CSS

## Package Manager
- Always use **npm**. Never use yarn, pnpm, or bun.
- Use `npm ci` for clean installs in CI/scripts, `npm install` for adding packages.

## Coding Style
- Functional components only — no class components
- Prefer named exports over default exports
- Use `async/await` over `.then()` chains
- Prefer `const` over `let`; never use `var`
- Use early returns to reduce nesting
- Keep files focused — one component per file

## Common Commands
- `npm run dev` — start dev server
- `npm run build` — production build
- `npm test` — run tests
- `npx tsc --noEmit` — type check without emitting
- `npx eslint .` — lint
- `npx prettier --write .` — format

## Git
- Write concise commit messages in imperative mood
- Always check `git status` before committing

## gstack
Use /browse from gstack for all web browsing. Never use mcp__claude-in-chrome__* tools.
Available skills: /office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review,
/design-consultation, /design-shotgun, /design-html, /review, /ship, /land-and-deploy,
/canary, /benchmark, /browse, /open-gstack-browser, /qa, /qa-only, /design-review,
/setup-browser-cookies, /setup-deploy, /retro, /investigate, /document-release, /codex,
/cso, /autoplan, /pair-agent, /careful, /freeze, /guard, /unfreeze, /gstack-upgrade, /learn.
