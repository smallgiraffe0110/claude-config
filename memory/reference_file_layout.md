---
name: file-layout
description: Where things live after the 2026-10-07 cleanup — main projects, side projects, archives, legacy memory notes
metadata:
  type: reference
---

Layout set on 2026-10-07 (see [[current-focus]]):

- `~/code/` top level — main projects only: `implemented-systems`, `medspa-systems`, their two `systems-*` review folders, `claude-config`.
- `~/code/_side/<name>` — every other new project (`newproj` / `newnext` create here).
- `~/code/_archive/` — all legacy repos (SBS, Flathead exo + its worktrees, LV8, snf-*, austin-leads, etc.). `_archive/_from-home/` holds project folders that used to sit loose in `~`.
- `~/Documents/Archive-2026-10/` — loose documents and old Desktop screenshots moved out of `~` and `~/Desktop`.
- `memory/legacy/` (next to this file) — notes for archived projects: austin-leads, exo/Flathead Forge, LV8 CRM, Simple Based Solutions, snfs-facebook-scraper. Paths inside them predate the move (prefix `~/code/` → `~/code/_archive/`). Read only if Hunter asks about that project.
- Same layout on the Mac mini: clone `claude-config`, run `setup.sh`, then `tidy-code.sh --apply`.
