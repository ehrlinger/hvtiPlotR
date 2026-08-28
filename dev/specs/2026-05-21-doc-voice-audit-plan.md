# hvtiPlotR Documentation Voice Audit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit every documentation surface in the hvtiPlotR package and rewrite it in John Ehrlinger's writing voice, removing AI tells — prose only, no behavioral or API changes.

**Architecture:** Two phases. Phase 1 audits each artifact against the voice spec (`~/Documents/ObsidianVault/memory/writing-voice.md`) via a subagent per artifact, consolidating findings into one report. A hard review gate follows — John approves the report before any rewrite. Phase 2 applies the approved fixes artifact by artifact, then re-renders and checks the package.

**Tech Stack:** R package (roxygen2, devtools, testthat), Quarto vignettes + slide deck, Markdown.

**Design spec:** `dev/specs/2026-05-21-doc-voice-audit-design.md`

**Branch:** `docs/voice-audit` (already created off `main`).

---

## Conventions for every task

- **Voice reference:** `~/Documents/ObsidianVault/memory/writing-voice.md` — the
  "Writing Voice Fingerprint". Narrative vs Terse registers; "AI tells to hunt
  and kill"; the Rules section. Every audit and rewrite is judged against it.
- **Hard constraints:** (1) facts are immutable — never change a version, PR
  number, function/argument name, default, path, or factual claim; (2) only
  prose changes — no code, no example code, no YAML front matter, no badges;
  (3) respect the register of each surface.
- **Commit hygiene:** stage only the files named in the task. The working tree
  has an unrelated uncommitted change (`inst/slides/hvtiPlotR-whats-new.qmd`
  theme line) — leave it unstaged unless a task explicitly edits that file.
- `docs/` is git-ignored in this repo; the audit report and these planning
  docs are local working files, not committed.

## Artifact units

| # | Unit | Files | Register |
|---|---|---|---|
| A | README | `README.md` | Narrative |
| B | Vignette: package overview | `vignettes/hvtiPlotR.qmd` | Narrative |
| C | Vignette: plot functions | `vignettes/plot-functions.qmd` | Narrative |
| D | Vignette: plot decorators | `vignettes/plot-decorators.qmd` | Narrative |
| E | Vignette: SAS migration | `vignettes/sas-migration-guide.qmd` | Narrative |
| F | Vignette: contributing | `vignettes/contributing.qmd` | Narrative |
| G | NEWS | `NEWS.md` (all version entries) | Terse |
| H | Slide deck | `inst/slides/hvtiPlotR-whats-new.qmd` (prose/bullets only) | Narrative |
| I | Roxygen narrative | `@description`/`@details` in `R/help.R`, `R/themes.R`, `R/hazard-plot.R` | Narrative |
| J | Roxygen terse + DESCRIPTION | `@title`/`@param`/`@return` across `R/*.R` (26 files); `DESCRIPTION` `Title`/`Description` | Terse |

---

## Phase 1 — Audit

### Task 1: Audit all artifact units and consolidate the report

**Files:**
- Create: `docs/voice-audit-2026-05-21.md` (local working file)

- [ ] **Step 1: Dispatch one audit subagent per artifact unit (A–J)**

Dispatch the ten audit subagents in parallel (independent read-only analysis).
Each subagent prompt must include:
- the full text of `~/Documents/ObsidianVault/memory/writing-voice.md`,
- the file(s) for that unit and the unit's register (Narrative or Terse),
- the hard constraints (facts immutable; prose only).

Each subagent returns a findings list. Each finding has: a locating quote of
the offending text; the named tell or Rule violated (from the voice spec); a
proposed rewrite. Subagents must NOT edit any file — audit only.

- [ ] **Step 2: Consolidate findings into the report**

Write `docs/voice-audit-2026-05-21.md`, grouped by artifact unit (A–J). For
each unit: a short voice-summary sentence, then the numbered findings
(quote / tell / proposed rewrite). Units with no findings are listed as
"no changes needed".

- [ ] **Step 3: Self-check the report**

Confirm: every unit A–J is represented; no proposed rewrite changes a fact
(version, PR number, name, default, path); Terse units judged against the
Terse ruleset, not narrativized.

- [ ] **Step 4: Present the report to John — REVIEW GATE**

Present `docs/voice-audit-2026-05-21.md` and stop. Do not begin any rewrite
until John approves the report. He may strike, add, or amend findings; the
approved report is the input to Phase 2.

---

## REVIEW GATE — John approves the audit report before Phase 2 begins.

---

## Phase 2 — Rewrite

Each rewrite task takes the approved report for that unit plus the voice spec.
Dispatch one rewrite subagent per unit; its prompt includes the voice spec,
the file, and that unit's approved findings. The subagent applies ONLY the
approved findings (plus any equivalent instance of the same tell it finds in
the same file), changes prose only, and changes no fact.

After each rewrite task, verify the diff: every approved finding for the unit
addressed; `git diff` shows only prose moved — no version/name/default/path
changed.

### Task 2: Rewrite README (unit A)

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Apply the approved unit-A findings** (rewrite subagent, Narrative register).
- [ ] **Step 2: Verify** — `git diff README.md`: only prose changed; no badge markup, links, or code blocks altered.
- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(voice): rewrite README in John's voice"
```

### Task 3: Rewrite package-overview vignette (unit B)

**Files:**
- Modify: `vignettes/hvtiPlotR.qmd`

- [ ] **Step 1: Apply the approved unit-B findings** (rewrite subagent, Narrative register). Prose only — no R code chunks, no YAML.
- [ ] **Step 2: Verify** — `git diff`: only Markdown prose changed; chunk code and YAML untouched.
- [ ] **Step 3: Commit**

```bash
git add vignettes/hvtiPlotR.qmd
git commit -m "docs(voice): rewrite hvtiPlotR vignette in John's voice"
```

### Task 4: Rewrite plot-functions vignette (unit C)

**Files:**
- Modify: `vignettes/plot-functions.qmd`

- [ ] **Step 1: Apply the approved unit-C findings** (rewrite subagent, Narrative register). Prose only.
- [ ] **Step 2: Verify** — `git diff`: only Markdown prose changed.
- [ ] **Step 3: Commit**

```bash
git add vignettes/plot-functions.qmd
git commit -m "docs(voice): rewrite plot-functions vignette in John's voice"
```

### Task 5: Rewrite plot-decorators vignette (unit D)

**Files:**
- Modify: `vignettes/plot-decorators.qmd`

- [ ] **Step 1: Apply the approved unit-D findings** (rewrite subagent, Narrative register). Prose only.
- [ ] **Step 2: Verify** — `git diff`: only Markdown prose changed.
- [ ] **Step 3: Commit**

```bash
git add vignettes/plot-decorators.qmd
git commit -m "docs(voice): rewrite plot-decorators vignette in John's voice"
```

### Task 6: Rewrite SAS-migration vignette (unit E)

**Files:**
- Modify: `vignettes/sas-migration-guide.qmd`

- [ ] **Step 1: Apply the approved unit-E findings** (rewrite subagent, Narrative register). Prose only.
- [ ] **Step 2: Verify** — `git diff`: only Markdown prose changed.
- [ ] **Step 3: Commit**

```bash
git add vignettes/sas-migration-guide.qmd
git commit -m "docs(voice): rewrite sas-migration-guide vignette in John's voice"
```

### Task 7: Rewrite contributing vignette (unit F)

**Files:**
- Modify: `vignettes/contributing.qmd`

- [ ] **Step 1: Apply the approved unit-F findings** (rewrite subagent, Narrative register). Prose only.
- [ ] **Step 2: Verify** — `git diff`: only Markdown prose changed.
- [ ] **Step 3: Commit**

```bash
git add vignettes/contributing.qmd
git commit -m "docs(voice): rewrite contributing vignette in John's voice"
```

### Task 8: Rewrite NEWS.md (unit G)

**Files:**
- Modify: `NEWS.md`

- [ ] **Step 1: Apply the approved unit-G findings** (rewrite subagent, Terse register). Every version entry is in scope. CRITICAL: do not change any version number, PR reference (`#nn`), function/argument name, or what-shipped fact — voice only.
- [ ] **Step 2: Verify** — `git diff NEWS.md`: confirm every `#nn`, version header, and factual claim is byte-identical except for prose voice.
- [ ] **Step 3: Commit**

```bash
git add NEWS.md
git commit -m "docs(voice): rewrite NEWS entries in John's voice"
```

### Task 9: Rewrite slide deck prose (unit H)

**Files:**
- Modify: `inst/slides/hvtiPlotR-whats-new.qmd`

- [ ] **Step 1: Apply the approved unit-H findings** (rewrite subagent, Narrative register). Slide prose and bullet text only — do NOT touch the YAML front matter (including the uncommitted `theme:` line) or any code chunk.
- [ ] **Step 2: Verify** — `git diff`: only slide prose/bullets changed; YAML and code untouched.
- [ ] **Step 3: Commit**

```bash
git add inst/slides/hvtiPlotR-whats-new.qmd
git commit -m "docs(voice): rewrite what's-new slide prose in John's voice"
```

### Task 10: Rewrite roxygen narrative prose (unit I)

**Files:**
- Modify: `R/help.R`, `R/themes.R`, `R/hazard-plot.R`

- [ ] **Step 1: Apply the approved unit-I findings** (rewrite subagent, Narrative register). Edit only `@description`/`@details` prose text — not `@param`, `@return`, `@examples`, code, or roxygen tags themselves.
- [ ] **Step 2: Regenerate docs**

```r
devtools::document()
```

- [ ] **Step 3: Verify** — `git diff` on `R/*.R` and `man/*.Rd`: only `@description`/`@details` prose changed; signatures, examples, and other tags untouched.
- [ ] **Step 4: Commit**

```bash
git add R/help.R R/themes.R R/hazard-plot.R man/
git commit -m "docs(voice): rewrite roxygen description/details prose in John's voice"
```

### Task 11: Rewrite roxygen terse prose + DESCRIPTION (unit J)

**Files:**
- Modify: `R/*.R` (`@title`/`@param`/`@return` text), `DESCRIPTION`

- [ ] **Step 1: Apply the approved unit-J findings** (rewrite subagent, Terse register). Edit only the prose of `@title`, `@param`, `@return` lines and the `DESCRIPTION` `Title`/`Description` fields. Do not change argument names, types stated, defaults, or any code.
- [ ] **Step 2: Regenerate docs**

```r
devtools::document()
```

- [ ] **Step 3: Verify** — `git diff` on `R/*.R`, `man/*.Rd`, `DESCRIPTION`: only terse prose changed; no argument name or default altered; `Version` line untouched.
- [ ] **Step 4: Commit**

```bash
git add R/ man/ DESCRIPTION
git commit -m "docs(voice): tighten roxygen param/return and DESCRIPTION prose"
```

---

## Phase 3 — Verify, re-render, deliver

### Task 12: Re-render vignette HTML and run the package check

**Files:**
- Modify: tracked vignette `.html` files whose `.qmd` changed

- [ ] **Step 1: Identify tracked vignette HTML**

Run: `git ls-files vignettes/ | grep '\.html$'`
For each tracked `.html` whose matching `.qmd` was edited in Phase 2, re-render:

```bash
cd vignettes && quarto render <name>.qmd --to html && cd ..
```

- [ ] **Step 2: Run the full package check**

```r
devtools::test()
devtools::check()
```

Expected: `devtools::test()` — 0 failures. `devtools::check()` — 0 errors, 0
warnings (unchanged from before this work). Prose-only changes must not affect
either.

- [ ] **Step 3: Commit the re-rendered HTML**

```bash
git add vignettes/*.html
git commit -m "docs(voice): regenerate vignette HTML"
```

### Task 13: Add the synced voice-spec copy

**Files:**
- Create: `writing-voice.md` (repo root)
- Modify: `.Rbuildignore`

- [ ] **Step 1: Copy the voice spec into the repo**

Copy the current contents of `~/Documents/ObsidianVault/memory/writing-voice.md`
verbatim to `writing-voice.md` at the repo root.

- [ ] **Step 2: Exclude it from the built package**

Add this line to `.Rbuildignore`:

```
^writing-voice\.md$
```

- [ ] **Step 3: Verify** — `devtools::check()` still 0 errors / 0 warnings (the new file must not trigger a "non-standard file at top level" NOTE because `.Rbuildignore` excludes it).
- [ ] **Step 4: Commit**

```bash
git add writing-voice.md .Rbuildignore
git commit -m "docs: add synced copy of the writing-voice spec"
```

### Task 14: Open the pull request

- [ ] **Step 1: Push the branch**

```bash
git push -u origin docs/voice-audit
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create --base main --head docs/voice-audit \
  --title "docs: voice audit — rewrite all documentation in John's voice" \
  --body "<summary of the voice pass: artifacts touched, that it is prose-only, devtools::check clean, links the design spec>"
```

- [ ] **Step 3: Report** the PR URL. John reviews and merges.

---

## Self-review

| Spec requirement | Task |
|---|---|
| Audit every artifact surface (README, 5 vignettes, NEWS, slides, roxygen narrative + terse, DESCRIPTION) | Task 1 (units A–J) |
| Subagent-per-artifact audit | Task 1, Step 1 |
| Consolidated audit report | Task 1, Step 2 |
| Review gate before rewrite | Task 1, Step 4 + explicit GATE |
| Rewrite each artifact against the voice spec | Tasks 2–11 |
| Two registers respected | Each task names Narrative or Terse |
| Facts immutable | Hard constraint in Conventions; verify step in every rewrite task; Task 8 emphasises it for NEWS |
| Re-render vignette HTML | Task 12 |
| `devtools::check()` 0/0 | Tasks 12 and 13 |
| Synced voice-spec copy added + `.Rbuildignore` | Task 13 |
| Single PR, one commit per artifact | Tasks 2–11 each commit; Task 14 single PR |

Phase 2 rewrite tasks intentionally do not contain the literal rewritten text:
the edits are not known until the Phase 1 audit and the review gate are
complete. Each rewrite task is a precise procedure whose input is the approved
report for that unit.
