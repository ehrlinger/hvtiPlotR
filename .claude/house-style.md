<!--
  GENERATED FILE - DO NOT EDIT.

  Composed by tools/house-style/compose-house-style.R in the
  ehrlinger-personal repository. Edit the sources in the Obsidian vault
  (memory/), then recompose. Editing this file directly will be reverted
  by the next compose and flagged by --check.

  repo:            hvtiPlotR
  profile:         package-internal
  default persona: (a)
  sources:
    writing-voice.md               sha256:c32b3886f897
    writing-reader-profile.md      sha256:1dbeec1cd525
    writing-context.md             sha256:87d5555936e1
    r-package-structure.md         sha256:708b4defc1f3
-->

# House Style — hvtiPlotR

Default reader persona for this repository: **(a)**. Write for one persona at a time.

---

# John Ehrlinger — Writing Voice Fingerprint

Reference for keeping documentation and prose in a consistent human voice.
Canonical copy lives in the Obsidian vault; package repos hold a synced copy.

## The voice in one line

Pedagogical and conversational: start from something the reader already knows,
build to the new idea with a concrete analogy, and don't be afraid of a little
personality or a slightly imperfect sentence.

## Two registers

**Narrative** (vignettes, README, roxygen @description/@details, methods prose)
- Open from the familiar: "Most readers are familiar with simple linear regression..."
- Carry one concrete analogy through a hard idea (a fruit basket, the blind men
  and the elephant, a "noise-reduction filter").
- Question-headed sections: "Why Cluster?", "Where Do We Stop?".
- First person plural: "in our practice", "we proceed". Address the reader as "you".
- Gloss terms inline in parentheses; scare-quote a piece of jargon the first
  time it appears ("rules", "elbow", "eyeballing").
- Start sentences with But / Yet / Thus / Now when it helps the flow.
- **Conversational, not chatty.** A colleague explaining the method at a
  whiteboard, not a blog post. Keep an analogy when it teaches; cut winking
  asides and cute phrasing. "no Tukey rule hiding in the middle" is too cute;
  "not the usual Tukey 1.5 IQR whiskers" is right. Plain and direct beats
  folksy. The reader is a peer, so don't perform for them.
- Vary sentence length. A short flat statement after a long one lands well.

**Terse** (roxygen @param/@return, NEWS bullets)
- Compressed, but still plain and concrete, not sterile.
- State the thing; skip the preamble. "Logical; if TRUE, ..." not "This
  argument controls whether...".
- No analogies, no question headers here; the voice shows in word choice.

## Rules

- Em-dashes: use sparingly. Native to the voice and honestly overused. Keep one
  where it earns the pause; otherwise a comma, parentheses, or a full stop.
- Ellipses: an informal-register habit (text, email). Keep them out of package docs.
- Don't overstate. No overselling. Cut "enhanced", "powerful", "seamlessly",
  "robust" (as a brag), "comprehensive". State what the thing does, at its size.
- Imperfection is allowed. Mild redundancy, an occasional long sentence: human
  texture, not an error to scrub. Don't polish to a glassy finish.
- Repetition that teaches is voice, not defect. Restating a concept, or a
  callback structure (state the problems up front, answer each later), is kept.
  Repeat when it clarifies; cut repetition that only fills space.

## When NOT to apply this voice

This voice governs documentation *prose* — Narrative and Terse. It does not
govern:

- CRAN-facing `\value` / `@return` boilerplate, which follows R documentation
  convention, not register.
- R error, warning, and message strings, which state the condition plainly.
- Code comments, which explain the code to a maintainer, not the method to a
  reader.

When the task is one of these, ignore the registers and write to the local
convention.

## AI tells to hunt and kill

- Mechanical parallelism: same-shaped sentences with no teaching purpose, lists
  padded to equal length. (Pedagogical repetition is NOT this; preserve it.)
- Flavorlessness: correct but with no analogy, no picture, nothing a person
  would actually say.
- Missing "we"/"you": abstract, authorless prose.
- Forced tricolons: "fast, simple, and reliable".
- Hedge-free sterile balance: "X. However, Y. It is worth noting Z."
- Overstatement (see Rules).
- "in order to", "it is important to note", "leverage", "utilize".

Punctuation density is NOT a tell. The tells are structural.

## Before / after

AI:   "Set per_class = TRUE to enable the computation of per-class one-vs-rest
       ROC curves, providing enhanced flexibility for multi-class analysis."
John: "Set per_class = TRUE and a multi-class forest gives you one ROC curve
       per class, each class scored against all the others."


## Reference exemplars

Canonical samples of the voice, by register. When in doubt, read the one whose
register matches the task.

- **Plain-English explanatory** (the gold standard for teaching a method):
  `boilerplates/methods/VarPro Modeling in Plain English.docx` and
  `boilerplates/methods/supp_SIDclustering_methods.docx` (OneDrive, CORR
  Analysis Team). Opens from the familiar, carries one analogy throughout
  (fruit basket, noise-reduction filter), question-headed sections, "we"/"you",
  numbered-problems-answered-later callback.
- **Short-form announcement** (LinkedIn / release posts): the TemporalHazard
  1.0.3 LinkedIn post, below. Compresses the narrative register: familiar
  opener, one rhetorical-question hook, one carried picture, understatement,
  "we"/"you", no marketing tricolons.
- **Recipe book ("When to use it" sections)**: the Survival Plots chapter
  opener in `hvti_graphics/survival.qmd`. Narrative register aimed at a
  biostatistician reader: names the clinical question first ("how long until an
  event"), defines the one idea that makes the method its own (right-censoring),
  ties the function to the SAS macro the reader already trusts (`%kaplan`), and
  closes on how the object is used. No overstatement, "you" throughout.
- **Formal academic**: arXiv 1612.08974 and 1501.07196 (Ishwaran/Ehrlinger).
  Passive, citation-dense, no "you" — use only when the task is a methods paper.

### Short-form exemplar — TemporalHazard 1.0.3 (LinkedIn, 2026-05-29)

> When modeling survival after surgery, we know that risk is not constant. It's
> high in the days right after the operation, falls to a low steady rate once
> patients recover, then creeps back up years later as they age. So why do we
> so often force a single Weibull curve onto all three? It can't be early, flat,
> and late at once — the Weibull curve splits the difference and fits none of
> these segments well.
>
> Additive hazards (Blackstone, Naftel, and Turner, 1986) allow us to linearly
> combine hazard functions into a coherent single model. Instead of forcing one
> shape, you add up several: an early phase, a constant phase, a late phase,
> each with its own scale and its own covariate effects. It's been the workhorse
> of cardiac surgery outcomes ever since, and its code has been openly licensed
> for years — but running it still meant a SAS license.
>
> TemporalHazard is that model, rebuilt in pure R at Cleveland Clinic. We
> checked it against the original program fit for fit, so the numbers match what
> longtime SAS users already trust. Putting it in R opens these methods to many
> more users.
>
> Around that core it does what you'd want: five distributions, stepwise
> selection, confidence limits on predictions, and the usual diagnostics —
> Kaplan-Meier overlays, calibration, bootstrap. The vignettes walk a real
> clinical dataset start to finish, the way you'd actually run the analysis.

Why it works: familiar opener ("we know that risk is not constant"), a
rhetorical-question hook ("So why do we so often..."), one carried picture
(early/flat/late), understatement ("the usual diagnostics"), and "we"/"you"
throughout. No forced tricolon, no padded feature list, no overselling.

---

# Reader Profiles — documentation audiences

A menu of selectable audiences for the `ehrlinger-writing` harness. Write for
ONE persona at a time, not a blend. The active persona is chosen per task
(explicit choice → repo `CLAUDE.md` default → ask). The `hvti_graphics` recipes
book defaults to persona (a); the public CRAN packages (`ggRandomForests`,
`temporal_hazard`) default to persona (d).

*Retitled 2026-07-16: this was "HVTI graphics documentation", but the harness
also governs two public CRAN packages whose readers have no HVTI context. See
(d).*

## (a) HVTI/CORR biostatistician — DEFAULT for the recipes book

The biostats team (Austin, Kelsey, Wendy) adopting the house plotting style.

- **Already knows:** R, ggplot2, survival analysis, the CORR datasets.
- **Wants from a recipe:** all three at once — runnable code to copy, a call on
  which plot to use, and the meaning of a specific argument. They open a recipe
  for any of the three, often in the same sitting.
- **Lands when:** the code runs as written, the argument is shown in context,
  the recipe says when to use the plot, and the figure comes with a reading
  guide.
- **Bounces when:** the recipe opens with a wall of code before saying what the
  plot is for, or shows a figure with no guide on how to read it.
- **Watch for:** the reader hand-rolling a plot in raw ggplot instead of using
  the `hvtiPlotR`/`ggRandomForests` constructor that already makes it. Second,
  drifting off house style by skipping the `hv_*` theme or the two-step S3
  workflow.

## (c) External R user migrating from SAS — bilingual

Knows both the SAS workflow and R. Anchors: `%kaplan`, `plot.sas`,
PROC LIFETEST/PHREG, the Blackstone-Naftel-Turner additive hazard. The need is
not hand-holding through R; it is confirmation that the R output matches the
SAS original they already trust.

- **Already knows:** the SAS workflow AND R.
- **Wants from a recipe:** confirmation the R output matches the SAS original
  they trust.
- **Lands when:** the recipe ties the R function to the SAS macro it replaces
  and states that the numbers match.
- **Bounces when:** the R version is presented with no bridge to, or no
  reconciliation against, the SAS they know.


---

# Project Context — HVTI graphics ecosystem

Why we write the way we do. The harness reads this so prose carries the right
assumptions about purpose and constraints.

## The ecosystem

- **hvtiPlotR** — ggplot2 themes and plot constructors; the R replacement for
  the historical `plot.sas` macro.
- **ggRandomForests** — graphics for random forests and variable priority
  (varPro), built on randomForestSRC.
- **temporal_hazard** — additive (Blackstone, Naftel, and Turner, 1986) hazard
  models in pure R.
- **hvti_graphics** — this recipes book, which ties the three together into a
  house style for clinical figures.

## Purpose

A single source of ggplot2 recipes for publication-quality, house-style figures
for HVTI CORR (Cardiovascular Outcomes Registries and Research, Cleveland Clinic
Heart & Vascular Institute) publications and presentations. Each recipe pairs a
figure with the code that produces it, so the next person starts from a working
script instead of a blank one.

Two ideas run through the book: a figure is built in two steps (a constructor
prepares and validates the data, then `plot()` hands you a bare ggplot you finish
with `+`), and every example stands on its own with its own sample data.

## Constraints that shape the writing

- **CORR publication standards** — figures must meet journal expectations.
- **Reproducibility** — Git, renv, dataset manifests; every figure regenerable.
- **No PHI** — never in code, prose, or example data.
- **R-first** — R is the working language; SAS is the heritage we migrate from.
- **SAS-migration heritage** — many readers trust SAS output, so we say when the
  R version matches the original (the way we checked temporal_hazard fit for fit).

---

# R Package Structural Rules — house style

This document governs the structural side of the house style: README order,
the roxygen contract, vignette roles, pkgdown layout, `DESCRIPTION` fields,
and versioning. `writing-voice.md` and `writing-reader-profile.md` govern how
you write; this one governs what has to be there and in what order. It is
written for the person about to write or audit a package README — most often
the biostatistician who already knows R and is deciding whether this
package's front door matches the other seven.

Derived from `hvtiPlotR`, the de-facto template across the eight-package
portfolio, with a small number of deliberate improvements it does not yet
itself reflect. Recorded so the other seven — and hvtiPlotR, on those few
points — can be brought into line with it rather than the rules drifting to
match whichever package they came from.

## README canonical order

Twelve elements, in this order. Skip an element only when its "required"
condition doesn't hold — don't reorder around a skip.

| # | Element | Required |
|---|---|---|
| 1 | `# <pkg> — <plain-language subtitle>` | always |
| 2 | Badge block | always |
| 3 | Provenance callout | if fork, SAS port, or inherited |
| 4 | Status block | if version < 1.0.0 |
| 5 | Lede paragraph | always |
| 6 | Docs-site link | if pkgdown |
| 7 | Installation | always |
| 8 | Quick start, runnable | always |
| 9 | Function reference, grouped tables | always |
| 10 | Documentation and vignette index | if vignettes |
| 11 | Related packages | if ecosystem member |
| 12 | Citation | `package-cran` only |

**Lede openings.** Three are permitted. Which one is right depends on where
the reader already stands, and forcing everyone through the same opening
would flatten a real difference between them:

- *What it is and who it is for* — the reader has already been told to use
  the package. Current examples: hvtiPlotR, hvtiPropensityScores.
- *The pain you already have* — the reader still needs convincing to adopt.
  Current example: hvtiRtables.
- *What works today* — the reader is judging whether the package is ready.
  Current example: hvtiRdatasets.

Whichever opening you use, the first paragraph says what the package does.
That part isn't optional across the three.

**Provenance.** Mandatory wherever it applies, and in this portfolio that's
nearly everywhere — most of these packages started life as something else.
Three kinds:

- *SAS-macro port* — hvtiPlotR (`plot.sas`), hvtiPropensityScores,
  hvtiRutilities (`PROC CONTENTS`, `PROC MEANS`), hvtiRtables (SAS table
  macro).
- *Upstream fork* — hvtiBoostmtree, forked from `kogalur/boostmtree` at
  v1.5.1.
- *Institutional inheritance* — TemporalHazard, from the UAB SAS/C HAZARD
  code.

The callout states what the package descends from and how faithful it is to
that source. For a fork, it also states what was renamed and what wasn't —
a reader diffing against upstream needs to know which names still line up.

**Status block.** Required while the version's major digit is 0, forbidden
once it isn't. While a package is pre-1.0, the status block says which parts
are implemented and which aren't, so a reader can judge readiness without
going and reading the NEWS file. Once you cross 1.0.0 the block goes away —
the version number is now doing that job.

**Badge tiers**, in fixed order, each tier its own blank-line-separated
block:

- *Universal:* R-CMD-check, codecov, repostatus, pkgdown.
- *Internal only:* GitHub r-package version.
- *CRAN only:* CRAN status, cranlogs, cranlogs grand-total.
- *Optional:* lint, lifecycle, License, DOI.

The hand-rolled dynamic-regex version badge currently living in
hvtiRutilities is replaced by the standard GitHub r-package badge — it's
doing the same job with more code to maintain.

**Function reference** is grouped markdown tables by domain, one table per
function family, each a two-column table naming the callable and describing
it — the name column is `Function` or `Constructor`, whichever fits the
package's API. Not nested bullet lists, and not prose. The README's job here
is navigational — it maps "what am I trying to do" onto "which function" —
and a table does that in a way a reader can scan that a paragraph can't.
Tutorial content belongs in the vignettes; behavioral detail belongs in
roxygen `@details`.

## Roxygen contract

Roxygen 8.0.0, with `Roxygen: list(markdown = TRUE)`.

Every exported object carries `@description`, one `@param` per argument,
`@return`, `@examples`, and either `@family` or `@seealso`. `@return` is
mandatory, no exceptions — it's a CRAN requirement, and it's already on the
release checklist, so an export missing one should never reach that gate in
the first place.

Internal helpers stay out of the public index — by `@keywords internal` or
`@noRd`, whichever fits the helper. `@keywords internal` keeps a documented
topic that's simply hidden from the reference index, right for a helper a
determined reader might still want to look up. `@noRd` generates no topic at
all, right for a helper that's purely an implementation detail. The rule is
the outcome, not the tag: nothing internal shows up in the public index.

**Package-level documentation** lives in `R/<pkg>-package.R`, the filename
`usethis::use_package_doc()` generates. Three packages currently keep this
in `help.R` instead; rename with `git mv` — content and `NAMESPACE` are
unaffected by the move. hvtiRtables has no package doc at all and gains one.
At minimum it states what the package is, who it's for, the workflow the
package expects, and links to the vignettes.

**Voice registers**, per `writing-voice.md`:

- `@description` and `@details` — Narrative register.
- `@param` and `@return` — Terse register.
- `\value` boilerplate follows R documentation convention rather than either
  register — see that document's "When NOT to apply this voice" section.

**Examples** run against `sample_*()` companions or stock datasets (`mtcars`,
`pbc`, `Boston`) — never against PHI, and never against an internal dataset a
reader outside HVTI can't obtain. An example that's slow but still runnable
uses `\donttest`, never `\dontrun` — the difference matters because
`\dontrun` examples don't get checked at all, and a stale one can sit broken
for a release cycle before anyone notices. An example touching a Suggests
dependency is guarded with `requireNamespace()`.

## Vignette roles

Vignettes fill named roles, not free-form topics. A reader looking for the
methods write-up shouldn't have to guess which file it's hiding in.

| Role | Filename | Required for |
|---|---|---|
| Overview | `<pkg>.qmd` | all packages |
| SAS migration | `sas-migration-guide.qmd` | SAS ports; persona (c) |
| Reference | one or more; consolidated or split by family | packages with more than one family |
| Methods and mathematics | e.g. `mathematical-foundations.qmd` | method packages |
| Contributing | `contributing.qmd` | optional |

The SAS-migration vignette ties each R function to the SAS macro it replaces
and states that the numbers match. Persona (c) doesn't need hand-holding
through R — they already know R. What they need is confirmation that this
gives the same answer as the SAS they already trust.

**Reference vignettes.** "One or more" isn't a headcount to hit — it means a
reference vignette can cover every function family in a single indexed
document, or be split family by family, whichever suits the package, so long
as no family goes undocumented and the overview vignette or the pkgdown
index tells a reader where to look. hvtiPlotR takes the consolidated form:
`plot-functions.qmd` documents the plotting functions and
`plot-decorators.qmd` documents the decorator family, both indexed from the
overview vignette. Under this rule `plot-decorators.qmd` is simply a second
reference vignette, not a free-form topic outside the table above.

**Naming exemption.** TemporalHazard keeps `sas-to-r-migration.qmd` rather
than renaming to the standard filename. Renaming a published vignette breaks
`vignette()` calls and indexed pkgdown URLs that are already out in the
world, and that's not a price worth paying just for filename consistency.
hvtiRdatasets, whose `coming-from-sas.qmd` isn't published yet, renames to
the standard name — there's nothing to break.

**Front matter** carries `title`, `author`, `date: today`, `format: html`
with `toc: true`, and the three `%\Vignette*` fields with
`%\VignetteEngine{quarto::html}`.

Vignette prose method — how to write the body once the role and front matter
are settled — is owned by `vignette-clarity-pass.md` and isn't restated
here.

## pkgdown

Follows the hvtiPlotR model:

- `reference:` split into titled sections, each with a prose `desc:` that
  says when to reach for that family, not merely what it contains.
- `articles:` grouped by vignette role.
- `navbar:` cross-linking to related packages in the ecosystem.
- `template:` bootstrap 5 with the light-switch enabled.

Every exported object appears in exactly one `reference:` section. pkgdown
fails the build on an unreferenced topic, and that failure is the check that
keeps this rule honest rather than aspirational.

## DESCRIPTION

Title Case in `Title`. Software names quoted in `Description`. DOIs written
space-free as `<doi:10.xxxx/yyyy>`. `URL` lists both the GitHub repo and the
pkgdown site. `BugReports` set. `VignetteBuilder: quarto`.
`Config/roxygen2/version: 8.0.0`.

## Versioning

Defers entirely to the global versioning rule: a straight three-digit
semantic version, no `.9000` suffix and no fourth digit, the patch digit for
incremental work, and the minor and major digits reserved for the
maintainer's own consolidation decisions — never rolled by an agent on its
own judgment.

A documentation-only retrofit against this house style is a patch bump, with
the matching `NEWS.md` entry so the version-grep test passes.

What has to happen before a version actually ships — the CRAN Cookbook audit,
`R CMD check --as-cran` with the manual built, the check-time budget, the
reverse-dependency pass — is owned by `r-package-release-checklist.md` and
isn't restated here. A patch bump on a published package still runs that gate
in full, because a documentation change rebuilds the vignettes.
