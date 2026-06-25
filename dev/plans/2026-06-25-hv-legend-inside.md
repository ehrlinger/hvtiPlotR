# `hv_legend_inside()` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an exported `hv_legend_inside()` helper to hvtiPlotR that places a ggplot's legend in the emptiest panel corner, falling back to an outside legend when no corner is clear.

**Architecture:** Pure post-processing transform on a built ggplot (same family as `hv_ggsave_dims()`/`hv_ph_location()`). `ggplot_build()` → collect layer `(x,y)` → normalize to the panel range → count occupancy in four corner boxes → place the legend in the emptiest corner if its occupancy ≤ `threshold`, else use `fallback`. Returns `plot + theme(...)`.

**Tech Stack:** R, ggplot2 4.0 (modern inside-legend API: `legend.position = "inside"` + `legend.position.inside` + `legend.justification.inside`), testthat 3e, roxygen2, pkgdown.

**Branch:** `feat/hv-legend-inside` (already created). **Spec:** `dev/specs/2026-06-25-hv-legend-inside-design.md`.

---

## File Structure

- **Create** `R/legend-inside.R` — `hv_legend_inside()` + four file-local internal helpers (`.legend_points`, `.legend_panel_range`, `.legend_corner_occupancy`, `.legend_corner_theme`). Single responsibility: legend auto-placement.
- **Create** `tests/testthat/test_legend_inside.R` — testthat suite.
- **Modify** `NAMESPACE` — `export(hv_legend_inside)` + importFrom (via `devtools::document()`, do not hand-edit).
- **Modify** `R/help.R` — add a `save`/utilities bullet referencing `hv_legend_inside()` (optional, match existing list).
- **Modify** `_pkgdown.yml` — add `hv_legend_inside` to the "Saving & Utilities" reference section.
- **Modify** `NEWS.md` + `DESCRIPTION` — version bump (both) + NEWS entry.

Validation reuses the existing `.check_scalar_positive()` from `R/validators.R`.

---

### Task 1: Skeleton + argument validation (always returns fallback)

**Files:**
- Create: `R/legend-inside.R`
- Create: `tests/testthat/test_legend_inside.R`

- [ ] **Step 1: Write the failing test**

```r
# tests/testthat/test_legend_inside.R
library(testthat)
library(ggplot2)

mk <- function(df) ggplot(df, aes(x, y, colour = g)) + geom_point()
# a plot whose points fill all four corners (no clear empty corner)
full_df <- data.frame(
  x = c(0, 0, 1, 1, 0.05, 0.95, 0.05, 0.95),
  y = c(0, 1, 0, 1, 0.05, 0.05, 0.95, 0.95),
  g = rep(c("a", "b"), 4)
)

test_that("hv_legend_inside validates its inputs", {
  p <- mk(full_df)
  expect_error(hv_legend_inside("not a plot"), "ggplot")
  expect_error(hv_legend_inside(p, threshold = 1.5), "\\[0, 1\\]")
  expect_error(hv_legend_inside(p, box_frac = 0.7), "0.5")
  expect_error(hv_legend_inside(p, box_frac = -1), "positive")
  expect_error(hv_legend_inside(p, fallback = "middle"))  # match.arg
})

test_that("hv_legend_inside returns a ggplot with an outside legend when the panel is full", {
  p <- hv_legend_inside(mk(full_df))
  expect_s3_class(p, "ggplot")
  expect_identical(p$theme$legend.position, "right")
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_legend_inside.R")'`
Expected: FAIL — `could not find function "hv_legend_inside"`.

- [ ] **Step 3: Write minimal implementation (validation + always-fallback)**

```r
# R/legend-inside.R

#' @noRd
# Validate args shared by hv_legend_inside().
.legend_validate <- function(threshold, box_frac, pad) {
  .check_scalar_positive(box_frac, "box_frac")
  .check_scalar_positive(pad, "pad")
  if (!is.numeric(threshold) || length(threshold) != 1L ||
      !is.finite(threshold) || threshold < 0 || threshold > 1)
    stop("`threshold` must be a single number in [0, 1].", call. = FALSE)
  if (box_frac > 0.5)
    stop("`box_frac` must be <= 0.5 (corner boxes would overlap).",
         call. = FALSE)
  invisible(TRUE)
}

hv_legend_inside <- function(plot, threshold = 0.08, box_frac = 0.30,
                             pad = 0.02, fallback = "right") {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  fallback <- match.arg(fallback, c("right", "left", "top", "bottom"))
  .legend_validate(threshold, box_frac, pad)

  plot + ggplot2::theme(legend.position = fallback)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_legend_inside.R")'`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add R/legend-inside.R tests/testthat/test_legend_inside.R
git commit -m "feat: hv_legend_inside() skeleton + arg validation"
```

---

### Task 2: Facet / multi-panel guard → fallback + message

**Files:**
- Modify: `R/legend-inside.R`
- Test: `tests/testthat/test_legend_inside.R`

- [ ] **Step 1: Write the failing test**

```r
test_that("hv_legend_inside falls back with a message on facets", {
  p <- mk(full_df) + facet_wrap(~g)
  expect_message(out <- hv_legend_inside(p), "panel")
  expect_identical(out$theme$legend.position, "right")
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_legend_inside.R")'`
Expected: FAIL — no message emitted (current impl never builds the plot).

- [ ] **Step 3: Implement the build + facet guard**

Replace the body of `hv_legend_inside()` (after validation) with:

```r
  fb <- ggplot2::theme(legend.position = fallback)

  b <- ggplot2::ggplot_build(plot)
  if (length(b$layout$panel_params) > 1L) {
    message("hv_legend_inside(): multiple panels; using the fallback legend ",
            "position ('", fallback, "').")
    return(plot + fb)
  }

  plot + fb   # placeholder until Task 3 adds corner logic
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_legend_inside.R")'`
Expected: PASS (all three tests).

- [ ] **Step 5: Commit**

```bash
git add R/legend-inside.R tests/testthat/test_legend_inside.R
git commit -m "feat: hv_legend_inside() facet guard -> fallback + message"
```

---

### Task 3: Corner occupancy + placement (the core)

**Files:**
- Modify: `R/legend-inside.R`
- Test: `tests/testthat/test_legend_inside.R`

- [ ] **Step 1: Write the failing tests**

```r
# Helper: read the inside-anchor back from a returned plot.
inside_pos <- function(p) p$theme$legend.position.inside

test_that("hv_legend_inside places the legend in the empty corner", {
  cases <- list(
    tr = c(1 - 0.02, 1 - 0.02),
    tl = c(0.02,      1 - 0.02),
    br = c(1 - 0.02,  0.02),
    bl = c(0.02,      0.02)
  )
  # Build explicit fixtures so exactly one corner box is empty.
  fixtures <- list(
    tr = data.frame(x = c(0,0,1,0.5,0.1), y = c(0,1,0,0.5,0.1)),
    tl = data.frame(x = c(0,1,1,0.5,0.9), y = c(0,0,1,0.5,0.1)),
    br = data.frame(x = c(0,0,1,0.5,0.1), y = c(0,1,1,0.5,0.9)),
    bl = data.frame(x = c(0,1,1,0.5,0.9), y = c(1,0,1,0.5,0.9))
  )
  for (corner in names(cases)) {
    df <- fixtures[[corner]]; df$g <- "a"
    p <- hv_legend_inside(ggplot(df, aes(x, y, colour = g)) + geom_point())
    expect_identical(p$theme$legend.position, "inside",
                     info = paste("corner", corner))
    expect_equal(inside_pos(p), cases[[corner]], info = paste("corner", corner))
  }
})

test_that("hv_legend_inside respects a custom fallback when the panel is full", {
  p <- hv_legend_inside(mk(full_df), fallback = "bottom")
  expect_identical(p$theme$legend.position, "bottom")
})

test_that("hv_legend_inside falls back when there are no usable points", {
  p <- hv_legend_inside(ggplot() + theme_grey())
  expect_identical(p$theme$legend.position, "right")
})

test_that("hv_legend_inside reads coordinates in built (post-flip) space", {
  # data empties the top-right in data space; coord_flip swaps axes.
  df <- data.frame(x = c(0,0,1,0.5,0.1), y = c(0,1,0,0.5,0.1), g = "a")
  p <- hv_legend_inside(
    ggplot(df, aes(x, y, colour = g)) + geom_point() + coord_flip()
  )
  expect_identical(p$theme$legend.position, "inside")
})
```

(Note: each `fixtures` data frame leaves exactly one corner box — the outer `box_frac = 0.30` band in each axis — empty, while the extreme points `(0,*)`/`(1,*)`/`(*,0)`/`(*,1)` pin the panel range so normalization is predictable.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_legend_inside.R")'`
Expected: FAIL — placement tests fail (impl still returns fallback).

- [ ] **Step 3: Implement the corner logic**

Add these internal helpers to `R/legend-inside.R` (above `hv_legend_inside`):

```r
#' @noRd
# Collect finite (x, y) from every layer of a built plot.
.legend_points <- function(b) {
  parts <- lapply(b$data, function(d) {
    if (all(c("x", "y") %in% names(d)))
      data.frame(x = d$x, y = d$y) else NULL
  })
  parts <- Filter(Negate(is.null), parts)
  if (length(parts) == 0L) return(NULL)
  xy <- do.call(rbind, parts)
  xy[is.finite(xy$x) & is.finite(xy$y), , drop = FALSE]
}

#' @noRd
# Panel x/y range from a built plot (ggplot2 >= 3.3 uses x.range/y.range;
# fall back to the ViewScale continuous_range on newer builds).
.legend_panel_range <- function(b) {
  pp <- b$layout$panel_params[[1]]
  xr <- pp$x.range; if (is.null(xr)) xr <- pp$x$continuous_range
  yr <- pp$y.range; if (is.null(yr)) yr <- pp$y$continuous_range
  list(x = xr, y = yr)
}

#' @noRd
# Fraction of points inside each of the four corner boxes (named tr/tl/br/bl).
.legend_corner_occupancy <- function(x, y, rng, box_frac) {
  nx <- (x - rng$x[1]) / diff(rng$x)
  ny <- (y - rng$y[1]) / diff(rng$y)
  n  <- length(nx)
  frac <- function(hx, hy) {
    xin <- if (hx) nx >= (1 - box_frac) else nx <= box_frac
    yin <- if (hy) ny >= (1 - box_frac) else ny <= box_frac
    sum(xin & yin) / n
  }
  c(tr = frac(TRUE, TRUE), tl = frac(FALSE, TRUE),
    br = frac(TRUE, FALSE), bl = frac(FALSE, FALSE))
}

#' @noRd
# Theme layer anchoring an inside legend at a corner (modern ggplot2 4.0 API).
.legend_corner_theme <- function(corner, pad) {
  a <- switch(corner,
    tr = list(pos = c(1 - pad, 1 - pad), just = c(1, 1)),
    tl = list(pos = c(pad,     1 - pad), just = c(0, 1)),
    br = list(pos = c(1 - pad, pad),     just = c(1, 0)),
    bl = list(pos = c(pad,     pad),     just = c(0, 0))
  )
  ggplot2::theme(
    legend.position             = "inside",
    legend.position.inside      = a$pos,
    legend.justification.inside = a$just
  )
}
```

Then replace the Task-2 placeholder (`plot + fb   # placeholder ...`) with:

```r
  pts <- .legend_points(b)
  if (is.null(pts) || nrow(pts) == 0L) return(plot + fb)

  rng <- .legend_panel_range(b)
  if (diff(rng$x) == 0 || diff(rng$y) == 0) return(plot + fb)

  occ  <- .legend_corner_occupancy(pts$x, pts$y, rng, box_frac)
  best <- names(occ)[which.min(occ)]   # ties -> first: tr, tl, br, bl
  if (occ[[best]] <= threshold)
    plot + .legend_corner_theme(best, pad)
  else
    plot + fb
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_legend_inside.R")'`
Expected: PASS (all tests).

- [ ] **Step 5: Run the full suite (no regressions)**

Run: `Rscript -e 'suppressMessages(library(testthat)); suppressMessages(devtools::load_all(quiet=TRUE)); r <- as.data.frame(test_dir("tests/testthat", reporter="silent", stop_on_failure=FALSE)); cat("FAILED:", sum(r$failed), " PASS:", sum(r$passed), "\n")'`
Expected: `FAILED: 0`.

- [ ] **Step 6: Commit**

```bash
git add R/legend-inside.R tests/testthat/test_legend_inside.R
git commit -m "feat: hv_legend_inside() corner-box auto-dodge placement"
```

---

### Task 4: Roxygen docs + export

**Files:**
- Modify: `R/legend-inside.R` (roxygen block above `hv_legend_inside`)
- Modify: `NAMESPACE` (generated)

- [ ] **Step 1: Add the roxygen block** above `hv_legend_inside`:

```r
#' Place a ggplot legend inside the emptiest panel corner
#'
#' Inspects a built plot, finds the panel corner with the fewest data points,
#' and anchors the legend there. When no corner is clear of data (e.g. dense
#' multi-curve panels), or the plot is faceted, the legend is sent to an outside
#' position instead. The CORR house convention is in-panel legends placed in
#' dead space; this automates the corner choice.
#'
#' Apply it *after* the house theme (which sets `legend.position = "none"`) so
#' its position wins.
#'
#' @param plot A single-panel \code{ggplot}.
#' @param threshold Maximum fraction of data points allowed in the chosen corner
#'   box for an in-panel legend. If the emptiest corner exceeds it, `fallback`
#'   is used. Default `0.08`.
#' @param box_frac Corner-box size as a fraction of panel width and height
#'   (`<= 0.5`). Default `0.30`.
#' @param pad Inset of the legend anchor from the panel edge, in npc units.
#'   Default `0.02`.
#' @param fallback Outside `legend.position` used when no corner is empty enough
#'   or the plot cannot be reasoned about (facets). One of `"right"`, `"left"`,
#'   `"top"`, `"bottom"`. Default `"right"`.
#'
#' @return The input `plot` with a \code{\link[ggplot2]{theme}} layer added that
#'   sets the legend position.
#'
#' @seealso Worked recipe with rendered output:
#'   \url{https://ehrlinger.github.io/hvti_graphics/legends.html}.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   library(ggplot2)
#'   p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'   hv_legend_inside(p)
#' }
#'
#' @importFrom ggplot2 ggplot_build theme
#' @export
```

- [ ] **Step 2: Regenerate docs**

Run: `Rscript -e 'devtools::document()'`
Expected: `man/hv_legend_inside.Rd` created; `NAMESPACE` gains `export(hv_legend_inside)` and `importFrom(ggplot2,ggplot_build)`.

- [ ] **Step 3: Verify export + Rd**

Run: `Rscript -e 'cat("export:", any(grepl("export\\(hv_legend_inside\\)", readLines("NAMESPACE"))), "| Rd:", file.exists("man/hv_legend_inside.Rd"), "\n")'`
Expected: `export: TRUE | Rd: TRUE`.

- [ ] **Step 4: Commit**

```bash
git add R/legend-inside.R NAMESPACE man/hv_legend_inside.Rd
git commit -m "docs: roxygen + export for hv_legend_inside()"
```

---

### Task 5: pkgdown index + NEWS + version bump

**Files:**
- Modify: `_pkgdown.yml`
- Modify: `NEWS.md`
- Modify: `DESCRIPTION`

- [ ] **Step 1: Add to the pkgdown reference index.** In `_pkgdown.yml`, under the `- title: "Saving & Utilities"` section's `contents:`, add `- hv_legend_inside` immediately after `- hv_ggsave_dims`.

- [ ] **Step 2: Bump the version (BOTH files).**
  - `DESCRIPTION` line 4: `Version: 2.7.0` → `Version: 2.8.0`.
  - `NEWS.md`: add a new top section:

```markdown
# hvtiPlotR 2.8.0

## New features

- `hv_legend_inside()`: place a plot's legend in the emptiest panel corner
  automatically, falling back to an outside position when no corner is clear
  (e.g. dense multi-curve panels). Apply it after the house theme. See the
  recipes-book legends chapter.
```

> **Version note for the maintainer:** `2.8.0` (new exported function). Per the
> versioning discipline, confirm the minor-digit roll before tagging; if held,
> use `2.7.1`/a `.9000` dev suffix to satisfy the NEWS-vs-DESCRIPTION grep test.

- [ ] **Step 3: Verify NEWS/DESCRIPTION agree**

Run: `Rscript -e 'd <- read.dcf("DESCRIPTION")[,"Version"]; n <- grepl(d, paste(readLines("NEWS.md"), collapse="\n"), fixed=TRUE); cat("DESCRIPTION:", d, "| in NEWS:", n, "\n")'`
Expected: `DESCRIPTION: 2.8.0 | in NEWS: TRUE`.

- [ ] **Step 4: Commit**

```bash
git add _pkgdown.yml NEWS.md DESCRIPTION
git commit -m "docs: index hv_legend_inside in pkgdown + NEWS 2.8.0"
```

---

### Task 6: Release gate

**Files:** none (verification only).

- [ ] **Step 1: Full test suite**

Run: `Rscript -e 'suppressMessages(library(testthat)); suppressMessages(devtools::load_all(quiet=TRUE)); r <- as.data.frame(test_dir("tests/testthat", reporter="silent", stop_on_failure=FALSE)); cat("FAILED:", sum(r$failed), " WARN:", sum(r$warning), " PASS:", sum(r$passed), "\n")'`
Expected: `FAILED: 0`.

- [ ] **Step 2: `R CMD check --as-cran` with the manual**

Run: `Rscript -e 'res <- devtools::check(document = FALSE, cran = TRUE, manual = TRUE, error_on = "never"); cat("E:", length(res$errors), "W:", length(res$warnings), "N:", length(res$notes), "\n")'`
Expected: `E: 0 W: 0 N: 0`. If any new note/warning traces to `hv_legend_inside` (e.g. `\value` missing, example runtime, undocumented arg), fix it and re-run.

- [ ] **Step 3: Push the branch + open the PR (do not merge — the maintainer merges/tags).**

```bash
git push -u origin feat/hv-legend-inside
gh pr create --base main --head feat/hv-legend-inside \
  --title "feat: hv_legend_inside() — auto-dodge legend placement (v2.8.0)" \
  --body "Implements hv_legend_inside() per dev/specs/2026-06-25-hv-legend-inside-design.md. Corner-box point-count places the legend in the emptiest panel corner, fallback to outside when no corner is clear (auto-handles dense stratified-curve panels). Tests + roxygen + pkgdown + NEWS 2.8.0. R CMD check --as-cran 0/0/0. Phase 2 (book adoption) is a separate PR."
```

---

## Self-Review

**Spec coverage:**
- API (threshold/box_frac/pad/fallback) → Task 1 (validation) + Task 3 (use). ✓
- Build/normalize/corner algorithm → Task 3. ✓
- Facet/patchwork guard + message → Task 2. ✓
- No-points fallback → Task 3 (test + guard). ✓
- coord_flip via built coords → Task 3 (test). ✓
- `.check_scalar_positive` reuse + threshold/box_frac/fallback validation → Task 1. ✓
- 9-test plan → Tasks 1–3 cover validation, full→fallback, each corner, custom fallback, facets+message, no-points, coord_flip; composability is implicit (inside overrides "none"). ✓
- Export + roxygen + book `@seealso` → Task 4. ✓
- pkgdown + NEWS + version + release gate → Tasks 5–6. ✓
- Phase 2 explicitly out of scope. ✓

**Patchwork note:** `ggplot_build()` is only called on a `ggplot`; the `inherits(plot, "ggplot")` guard in Task 1 rejects a bare patchwork before build, so the facet-count guard covers the in-scope multi-panel case. A patchwork passed in errors at validation (acceptable; documented as single-panel `ggplot` input).

**Type consistency:** helper names `.legend_points`, `.legend_panel_range`, `.legend_corner_occupancy`, `.legend_corner_theme`, `.legend_validate` are used consistently across tasks; corner keys `tr/tl/br/bl` consistent between occupancy and theme.

**ggplot2 4.0 API:** placement uses `legend.position = "inside"` + `legend.position.inside` + `legend.justification.inside` (verified warning-free under `error_on = warning`); tests read those exact elements back.
