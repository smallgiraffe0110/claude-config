---
name: client-before-after-audit
description: Run Hunter's client before/after audit (website screenshots, Google Business Profile, Lighthouse, search rankings + competitors, ChatGPT answers, citation audit) with ~/code/before-after-capture and write the findings into the client's iCloud folder. Use whenever Hunter says "Run before-after-capture for a new client", gives a client name + website + address + iCloud folder + label (before/after), or asks for a before/after, baseline, audit or "after" snapshot of a client's site or Google profile.
---

# Client before/after audit

Hunter's agency (Implemented Systems / Earls Ventures) snapshots each client before work
starts and again after, to show the improvement. The tool is `~/code/before-after-capture`
(read its README first). Reference run: Kaufman Carpet Cleaning, 2026-10-02 —
`EarlsVentures/Implemented Systems/Kaufman Carpet Cleaning/claude-audit-before/`. Match its
outputs and write-ups.

## Input Hunter gives

```
Run before-after-capture for a new client.
Name / Website / Address / iCloud folder / Label: before|after
Google numbers I see today: <rating>, <total>, <one-star>   (optional)
```

If something is missing, look it up (address from the website or Google Maps) rather than
asking. Only ask if the business can't be identified.

## Rules

- **Everything for a client goes in the client's own folder**:
  `~/Library/Mobile Documents/com~apple~CloudDocs/EarlsVentures/Implemented Systems/<Client>/`.
  Check the folder's current name and location first — Hunter renames and moves them in
  Finder. Create it if missing. Snapshot folder: `claude-audit-before` or `claude-audit-after`.
- Don't commit or push the tool repo unless asked.
- Tell Hunter up front that Chrome will open for ~10–15 minutes and not to touch it or the
  folder while it runs.

## Steps

1. **Config** — write `~/code/before-after-capture/clients/<slug>.json` (copy `kaufman.json`'s shape):
   `name`, `siteUrl`, `gbpQuery` (name + full street address), `destDir` (the client folder),
   `lighthousePaths` (home + a main service page + contact), `nap` (exact name/street/city/
   state/zip/phone as on Google), `keywords` (one "<service> <City> <ST>" per service line from
   the site's nav, ~8–12), `aiPrompts` (three: "Who are the best <trade> companies in <City>,
   <ST>?"; a buyer-specific one for their main customer type; "Is <Name> in <City>, <ST> a good
   company? What do customers say about them?"), and `reported` with Hunter's numbers if given.
   For an "after", reuse the existing config unchanged so the comparison is like-for-like.
2. **Smoke test** — `node src/capture.mjs --client <slug> --only site --limit 3 --out <scratchpad>`,
   then Read the home desktop and mobile screenshots. Fix cookie banners or blank sections
   before the full run; check whether a blank section is really broken on the live site
   (Kaufman's reviews widget was a real 404).
3. **Full run** in the background:
   `node src/capture.mjs --client <slug> --label <label> --dir claude-audit-<label>`
4. **Verify** — no failed pages in `website/pages.json`; Read a few screenshots (home both
   viewports, a service page, a blog post, GBP overview, one ChatGPT answer). If directories
   came back `pageBlocked`, re-run `--only citations` once later; if a re-run is worse, keep the
   better same-day capture and say which run it came from.
5. **Write-ups** in the snapshot folder, following Kaufman's:
   - `CAPTURE-NOTES.md` — GBP numbers (flag any mismatch with Hunter's numbers), page counts,
     concrete site problems found (expired promos, broken widgets, duplicate/leftover pages,
     bad titles, shared meta descriptions, heading issues, missing alt text, thin pages),
     Lighthouse table, the "after" command.
   - `LOCAL-VISIBILITY-AUDIT.md` — rankings table, competitor table, ChatGPT findings (was
     the client named? what rating/negatives did it repeat, from which sources?), ratings
     across platforms, citation table + consistency findings, what wasn't captured, and what
     the "after" should move.
   Verify every number you write against the JSON. Only claim what was actually read
   (e.g. "no wrong phone in the listings we could read").
6. **For an "after"**: also write `BEFORE-VS-AFTER.md` in the client folder comparing the two
   snapshots metric by metric (reviews, rating, Maps/organic positions, ChatGPT mentions,
   Lighthouse, citations fixed, site problems resolved), pointing to paired screenshots.
7. **Update memory** `project_before_after_capture.md` with the client, date and folder.

## Known limits — always state these in the report

- Google organic and AI overview: blocked (captcha); DuckDuckGo stands in for organic.
- Signed-out Google Maps shows ~5 reviews and won't sort, so no one-star texts or review
  dates; Perplexity has a bot check and Copilot a login wall. A one-time sign-in in
  `~/code/before-after-capture/.chrome-profile` should lift these (README has the command).
- Rankings depend on where the search runs from; before and after must run from the same place.
- ChatGPT answers vary between runs; one capture is a sample.
- Google Search's knowledge panel must be screenshotted by hand.
