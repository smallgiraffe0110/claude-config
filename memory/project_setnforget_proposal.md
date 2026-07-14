---
name: project-setnforget-proposal
description: "SetNForget Systems proposal to Academic Platforms — editable source at ~/code/setnforget-proposals, built with Homebrew WeasyPrint"
metadata: 
  node_type: memory
  type: project
  originSessionId: e2948d10-e367-4a09-ac86-68ce545379b2
---

The "Academic Platforms AI Reader & Teacher" proposal (SetNForget Systems → Jeff Amrein) lives at `~/code/setnforget-proposals/academic-platforms/`. `proposal.html` is the single-file source of truth (inline CSS + inline SVG charts), reconstructed on 2026-07-13 from the v4 PDF because the original HTML source was lost.

Build with `weasyprint proposal.html <out>.pdf` — WeasyPrint 69.0 is installed via Homebrew. `uvx weasyprint` does NOT work on this Mac: SIP strips the `DYLD_*` env vars needed to locate Homebrew's Pango/GObject libs. Prices repeat in ~7 places including the SVG bar chart (geometry notes in the folder's README).
