# hvtiPlotR Documentation Voice Audit — Design

**Date:** 2026-05-21
**Goal:** Audit every documentation surface in the hvtiPlotR package and rewrite
it in John Ehrlinger's writing voice, removing AI tells. No behavioral or API
changes — prose only.

## Voice reference

The single source of truth is the voice spec at
`~/Documents/ObsidianVault/memory/writing-voice.md` ("John Ehrlinger — Writing
Voice Fingerprint"). It defines:

- **Two registers** — *Narrative* (vignettes, README, roxygen
  `@description`/`@details`, methods prose) and *Terse* (roxygen
  `@param`/`@return`, NEWS bullets).
- **Rules** — em-dashes sparingly, no ellipses in package docs, no
  overstatement, imperfection allowed, teaching repetition preserved.
- **AI tells to hunt and kill** — mechanical parallelism, flavorlessness,
  missing "we"/"you", forced tricolons, sterile hedged balance, overstatement,
  "in order to" / "it is important to note" / "leverage" / "utilize".

The audit and rewrite are both performed against this spec.

## Scope — artifacts in scope

| Artifact | Register |
|---|---|
| `README.md` | Narrative |
| `vignettes/hvtiPlotR.qmd` | Narrative |
| `vignettes/plot-functions.qmd` | Narrative |
| `vignettes/plot-decorators.qmd` | Narrative |
| `vignettes/sas-migration-guide.qmd` | Narrative |
| `vignettes/contributing.qmd` | Narrative |
| `NEWS.md` (all version entries) | Terse |
| `inst/slides/hvtiPlotR-whats-new.qmd` | Narrative (slide prose) |
| `R/*.R` roxygen `@description` / `@details` | Narrative |
| `R/*.R` roxygen `@param` / `@return` / `@title` | Terse |
| `DESCRIPTION` `Title` / `Description` fields | Terse |

**Out of scope:** code, function behavior, API names, examples' code, badge
markup, YAML front matter, the rendered `.html` artifacts (regenerated, not
hand-edited).

## Hard constraints

1. **Facts are immutable.** Voice edits never change a version number, PR
   reference, function name, argument name, default value, file path, or any
   factual claim. Released `NEWS.md` entries keep their content; only prose
   voice changes.
2. **Code and examples untouched.** Only prose — Markdown narrative, roxygen
   comment text, slide bullet text.
3. **Two registers respected.** Narrative surfaces edited against the Narrative
   ruleset; terse surfaces against the Terse ruleset. Do not "narrativize"
   `@param` lines or strip teaching analogies from vignettes.

## Phase 1 — Audit

Approach: **subagent per artifact.** One subagent per artifact (or small group
of small artifacts), each given the full voice spec and one file. Each returns
structured findings. The controller consolidates them.

Each finding records:
- the artifact and a locating quote of the offending text,
- the specific tell or rule violated (named from the voice spec),
- a proposed rewrite.

Output: a single consolidated report at `docs/voice-audit-2026-05-21.md`,
grouped by artifact.

**Review gate:** John reviews the audit report before any rewrite. The report
is a working document; it is not committed to the package long-term (it may be
removed or `.Rbuildignore`'d during cleanup).

## Phase 2 — Rewrite

After the audit report is approved:

- Apply the approved fixes artifact by artifact.
- One subagent per artifact for the rewrite, given the voice spec, the file,
  and that artifact's approved findings.
- Re-render `vignettes/plot-functions.qmd` to HTML (repo convention commits the
  rendered vignette HTML; see commit `e90923e`). Re-render any other vignette
  whose committed HTML is tracked and whose `.qmd` changed.
- Run `devtools::check()` — must stay at 0 errors / 0 warnings. Roxygen prose
  changes are re-documented with `devtools::document()`.

## Side fix — synced voice spec

The voice spec states "package repos hold a synced copy." hvtiPlotR has none.
Add a copy of `writing-voice.md` to the repo so future documentation work has
the reference locally. Placement: repo root as `writing-voice.md`, added to
`.Rbuildignore` so it does not ship in the built package.

## Delivery

- Branch: `docs/voice-audit`.
- Single PR to `main`.
- One commit per artifact, so the history is reviewable file by file.
- Separate commits for the re-rendered HTML and the synced voice-spec copy.

## Verification

- `devtools::check()` — 0 errors, 0 warnings (unchanged from current state).
- `devtools::document()` clean after roxygen edits.
- `quarto render` of any edited vignette succeeds.
- Spot-check: no finding from the audit report left unaddressed; no fact
  changed (diff review confirms only prose moved).

## Out of scope

- Sibling repos (ggRandomForests, hvtiRutilities, etc.).
- The Obsidian vault's own notes.
- Restructuring documentation (new sections, reordering) — this is a voice
  pass, not a content redesign.
