# hvtiPlotR

Plot constructors and methods for the HVTI CORR group — the largest public surface in the
family: **79 exports and 47 registered S3 methods**. Nearly everything downstream draws
through it, so a change to a returned object's class, element names or column names is a
breaking change for other packages, not just for this one.

This file is the operational contract and applies in full. It is tool neutral, so Codex and
any other agent read the same rules. Claude Code affordances live in `CLAUDE.md`, which
imports this file.

**Two companion documents already exist and are not restated here.** Read them:

- `CONTRIBUTING.md` — the code conventions table (file naming, the `hv_<concept>()` +
  `plot.hv_<concept>()` pair, column-name arguments as strings, colours and themes left to
  the caller, tidy eval via `.data[[col]]`, snapshot workflow) and the quick-start commands.
- `testing-strategy.md` — the test inventory, the named coverage gaps and the priority plan.
  Consult it before claiming a coverage gap is new.

## Definition of done

- `devtools::test()` passes. The runner is `tests/test-all.R`.
- `devtools::check()` is **0 errors, 0 warnings, 0 notes**. Verified 2026-08-20 at 2.7.6
  (1m 46s with `--no-manual` and vignettes skipped; the manual has its own gate), and again
  2026-08-31 at 2.7.11 from a clean `git archive` export with vignettes **built**, which is the
  invocation that gives a trustworthy 0/0/0 — see the locale and clean-export notes under
  the gates table.
- `devtools::document()` has been run and `man/` and `NAMESPACE` are committed with the
  source change.
- Every new export appears in `_pkgdown.yml` — the index here is explicit; see the rules.
- A new plot function has a test that asserts its layers carry **data**, not merely that it
  returned a ggplot. See the helper rule below.

## The automated gates

| workflow | runs on | fails on |
|---|---|---|
| `R-CMD-check.yaml` | PR + push to `main` | `R CMD check` across platforms |
| `lint.yaml` | PR + push to `main` | **any lint under `.lintr`.** `LINTR_ERROR_ON_LINT: true` since 2.7.9, when the 98 pre-existing lints were cleared ([#89](https://github.com/ehrlinger/hvtiPlotR/issues/89)). Run `lintr::lint_package()` before pushing; it must return zero. The `house-style` job in the same workflow gates separately, on house-style artifact drift. |
| `pkgdown.yaml` | PR + push to `main`, release, manual | the site build |
| `test-coverage.yaml` | PR + push to `main` | coverage upload; snapshots upload via `upload-snapshots: true` |
| `check-manual.yaml` | **push to `main` only — never a PR** | the PDF manual build — catches raw Unicode in `.Rd` that `--no-manual` skips |

⚠️ **`check-manual.yaml` does not gate pull requests.** Its triggers are `push` to
`main`/`master`, `release` and `workflow_dispatch`; there is no `pull_request`. So a raw-Unicode
`.Rd` passes every check a PR runs and only turns `main` red *after* the merge. If a change
touches `man/` or any roxygen block, build the manual yourself before handing the PR over:

```sh
R CMD Rd2pdf --no-preview --output=/tmp/manual.pdf .
```

En and em dashes are fine and already appear in 30 of the `man/*.Rd` files; they are the only
non-ASCII characters in the tree. It is Greek letters, combining marks and the like that break
the build. The `pdfTeX warning (dest): ... referenced but does not exist` lines are long-standing
cross-reference noise, not a failure.

⚠️ **Reproducing `R CMD check` locally needs a UTF-8 locale.** A plain `Rscript` session can
report `LC_CTYPE` as bare `en_US` (observed on macOS, 2026-08-31), and tangling
`vignettes/sas-migration-guide.qmd` then dies with
`conversion failure on 'FEV₁ Temporal Trend' in 'mbcsToSbcs'`. That is an environment artifact,
not a package defect, but it surfaces as a check ERROR and reads exactly like a regression from
whatever branch you are on. The runners are unaffected — `R-CMD-check.yaml` has been green on
`main` throughout. Build from a clean export rather than the working tree, too: a working-tree
build leaves `inst/doc` empty, which fabricates two vignette WARNINGs and hides the real result:

```sh
LC_ALL=en_US.UTF-8 R CMD check --no-manual hvtiPlotR_<version>.tar.gz
```

⚠️ Four of the five workflows carry `paths-ignore: ['.claude/**']`, so a commit touching only the
generated house-style artifact skips them. `lint.yaml` deliberately does **not**, because its
`house-style` job is precisely what checks that artifact.

## Rules for this repo

- **Roxygen markdown is ENABLED here.** `DESCRIPTION` carries
  `Roxygen: list(markdown = TRUE)`, so write markdown in roxygen blocks — backticks,
  `**bold**`, `[fn()]` links — and it renders correctly.
  ⚠️ **This inverts the sibling packages.** `hvtiRutilities` and `hvtiRtemplates` have no
  such field, so markdown there lands *literally* in the `.Rd` and must be written as
  `\code{}` / `\strong{}` / `\link{}`. Check `DESCRIPTION` before copying a roxygen block
  between repos in either direction.
- **Lines are 120 characters here.** `.lintr` raises `line_length_linter` because the plot
  constructors take many named arguments and read better whole than wrapped.
  ⚠️ A third value in the family: `hvtiRutilities` is 80, `hvtiRtemplates` is 135. Read
  `.lintr` rather than assuming.
- **`.lintr` deviates from lintr's defaults in three places, and only three.**
  `indentation_linter` and `commented_code_linter` are OFF, because both fire heavily on the
  aligned-argument style used throughout `R/` and on vignette chunks that show an alternative
  call commented out. `object_length_linter` is 35 rather than 30, because six exported
  `sample_*` generators are longer than 30 and renaming an export is a breaking change.
  `object_name_linter` accepts `SNAKE_CASE` as well as `snake_case`, for the score-scale
  constants that shout deliberately. Everything else is lintr's default and **is** enforced.
  ⚠️ The gate is live, so the temptation is to widen a rule here to clear one awkward site.
  Do not. A genuine false positive goes behind a `# nolint: <linter>.` on the line, with a
  comment saying why the tool is wrong; there are five of them, three in `R/` and two in
  `tests/`, and each one carries its reason.
- **Test files are `test_*.R` with an underscore**, not the `test-*.R` hyphen used in
  `hvtiRutilities` and `hvtiRtemplates`. Match the local convention when adding a file.
- **A plot test must prove the plot has data.** `tests/testthat/helper-plot-data.R` drives
  ggplot2's `ggplot_build()` so a plot that "renders" while every layer holds zero rows is
  caught — the same protection as a visual review without needing a graphics device. It
  keeps a `.decorator_geoms` list (`GeomHline`, `GeomVline`, `GeomAbline`) whose row count
  is decoration and therefore *not* evidence that the plotted dataset has rows: those layers
  are exempt from `min_rows` but must still draw at least one row, because a reference line
  can be mapped to the data — `plot.hv_sankey()` draws one — and so can collapse to zero.
  `GeomBlank` is listed separately in `.empty_geoms` and exempt outright, since drawing
  nothing is its purpose. `expect_s3_class(plot(obj), "ggplot")` alone is a smoke test, not
  coverage.
- **Every exported object must be added to `_pkgdown.yml`.** The `reference:` index is
  explicit — 15 titled sections against 79 exports — and pkgdown errors on a topic missing
  from it.
  ⚠️ `hvtiRtemplates` deliberately has **no** `reference:` section so pkgdown auto-indexes.
  Two conventions in one family.
- **Changing a returned object's class, element names or column names is a breaking change.**
  This package is the family's plotting layer; check who consumes the object before altering
  its shape.
- **`testthat` edition 3**, with snapshots under `tests/testthat/_snaps`. Generate a new
  baseline locally with `devtools::test()` and commit the `.snap`; accept intentional changes
  with `testthat::snapshot_accept()` rather than deleting the file.

## Gotchas

- **`NEWS.md` is `.Rbuildignore`d here**, so it does not ship in the tarball. Still update it
  — it is the human record and the pkgdown site reads it — but do not expect
  `news(package = "hvtiPlotR")` to find it from an installed copy.
- **`.Rbuildignore` carries a long legacy tail** from this package's ggRandomForests ancestry
  (`jss.cls`, `useR2014.pdf`, `packrat`, commented-out vignette rules). Do not treat it as a
  curated list; add what you need and leave the archaeology alone unless asked.
- `VignetteBuilder` is **quarto**, not `knitr`.
- A stray `tests/testthat/Rplots.pdf` exists — a graphics-device artifact, already
  `.Rbuildignore`d. Do not commit new ones.

## Git and versioning

- **Never push to `main`.** Branch, then open a PR and let the maintainer merge.
- **`main` is protected by a GitHub ruleset, and nothing in this repo records that.** A clone
  shows no trace of it, so it is stated here. The ruleset is named `protect main`, carries the
  same four rules in every repository that has one, and enforces them on the default branch:
  no deletion, no force-push, pull-request-only, and an **automatic Copilot code review** on
  every PR. A rejected push comes from the server, not a local hook.
  ⚠️ Fourteen repositories carry it, not twelve, and they are not byte-identical:
  `ggRandomForests` adds `required_status_checks`. Verify rather than assuming the family
  matches.
  ⚠️ The merge-blocking settings are **parameters of the `pull_request` rule**, one level below
  the rule types listed above, which is why a list of rule types never shows them. Read them in
  one call, `--jq` included:

  ```sh
  gh api repos/ehrlinger/<repo>/rulesets/<id> \
    --jq '.rules[] | select(.type=="pull_request") | .parameters'
  ```

  ⚠️ It requires **zero approvals**, and `require_code_owner_review` is **false**, so a PR can
  merge unreviewed. Adding a `CODEOWNERS` file does not change that on its own; the flag has to
  be turned on as well. Checked against the API on 2026-08-21.
  ⚠️ `required_review_thread_resolution` was turned **off** across all fourteen repositories on
  2026-08-21. Copilot still reviews every PR and still opens threads, but an unresolved thread
  no longer blocks the merge button. Nothing now forces that feedback to be read, so address
  and resolve Copilot threads before handing a PR over.
  ⚠️ `require_extra_approval_for_unattributed_changes` is **true** and was deliberately left
  alone. It can demand an approval on commits GitHub cannot attribute to a user account.
- Versions are **straight three digits** (`2.7.6`). Never a `.9000` suffix or a fourth digit.
- **Patch-digit bumps only**, as fixes land. Minor and major are the maintainer's decision.
- Bump `DESCRIPTION`, refresh its `Date`, and add the matching `NEWS.md` entry in the same
  commit.

## Change discipline

1. **Think before coding.** Do not assume, ask. If the request is ambiguous or a name, path
   or signature is uncertain, surface the confusion rather than running with a guess.
2. **Simplicity first.** Write the minimum that solves the stated problem. No speculative
   abstractions.
3. **Surgical changes.** Touch only what the task requires. Do not refactor, reformat or
   re-style adjacent code. Raise nearby problems separately rather than folding them in.
4. **Goal-driven execution.** State what done looks like before starting, and use tests as
   the criterion. For a plot function that means a data-carrying assertion, not a smoke test.

## Prose

Documentation prose — vignettes, README, roxygen `@description` and `@details` — follows the
house voice. Remember markdown is enabled here, unlike in most of the family.
