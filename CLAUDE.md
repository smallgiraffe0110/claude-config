# User-Level Instructions

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
