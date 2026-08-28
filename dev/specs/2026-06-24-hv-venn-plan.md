# hv_venn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `hv_venn()` — a 2-3 set Venn diagram that reads the same logical-column input as `hv_upset()`, computes a region-count table, and renders a bare ggplot via `ggvenn`.

**Architecture:** One new file `R/venn-plot.R`, mirroring `R/upset-plot.R`. An internal `.venn_regions()` enumerates the `2^k-1` non-empty regions and counts them; `hv_venn()` validates (reusing the existing validators + `hv_upset`'s binary-column check, capped at 3 sets) and builds an `hv_data` object carrying `$tables$regions`; `plot.hv_venn()` returns `ggvenn::ggvenn(data, columns = sets, ...)`; `print.hv_venn()` prints the standard header.

**Tech Stack:** R, ggvenn (new `Imports`), ggplot2, testthat, roxygen2/devtools.

---

## File Structure

- `R/venn-plot.R` (new) — `.venn_regions()` (internal), `hv_venn()`, `plot.hv_venn()`, `print.hv_venn()`, all roxygen.
- `tests/testthat/test_venn.R` (new) — all tests.
- `DESCRIPTION`, `NAMESPACE`, `man/*.Rd`, `_pkgdown.yml`, `vignettes/plot-functions.qmd`, `README.md`, `NEWS.md` — wiring, docs, release.

Run this file's tests with:
`Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`

Reference facts:
- `sample_upset_data()` returns a data frame of **logical** columns: `AV_Replacement`, `AV_Repair`, `MV_Replacement`, `MV_Repair`, `TV_Repair`, `Aorta`, `CABG`.
- Validators (in `R/validators.R`): `.check_df(x, arg = "data")`, `.check_cols(data, cols, data_arg = "data")`.
- `new_hv_data(data, meta, tables = list(), subclass)` (in `R/hvti-data.R`).
- `ggvenn::ggvenn(data, columns, show_percentage, show_counts, fill_color, text_size, set_name_size, ...)` returns a ggplot.

---

### Task 1: `.venn_regions()` region-count helper

**Files:**
- Create: `R/venn-plot.R`
- Test: `tests/testthat/test_venn.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test_venn.R`:

```r
# tests/testthat/test_venn.R
library(testthat)
library(ggplot2)

test_that(".venn_regions counts the 3 regions of a 2-set frame", {
  df <- data.frame(
    A = c(TRUE,  TRUE,  FALSE, TRUE,  FALSE),
    B = c(FALSE, TRUE,  TRUE,  FALSE, FALSE)
  )
  reg <- .venn_regions(df, c("A", "B"))
  expect_equal(nrow(reg), 3L)                       # A only, B only, A & B
  expect_setequal(reg$region, c("A only", "B only", "A & B"))
  expect_equal(reg$n[reg$region == "A only"], 2L)   # rows 1,4
  expect_equal(reg$n[reg$region == "B only"], 1L)   # row 3
  expect_equal(reg$n[reg$region == "A & B"], 1L)    # row 2
})

test_that(".venn_regions has 7 regions for 3 sets and treats NA as absent", {
  df <- data.frame(
    A = c(TRUE,  TRUE,  NA),
    B = c(TRUE,  FALSE, FALSE),
    C = c(TRUE,  FALSE, FALSE)
  )
  reg <- .venn_regions(df, c("A", "B", "C"))
  expect_equal(nrow(reg), 7L)
  expect_equal(reg$n[reg$region == "A & B & C"], 1L)  # row 1
  expect_equal(reg$n[reg$region == "A only"], 1L)     # row 2 (row 3 NA->absent)
  expect_equal(sum(reg$n), 2L)                        # row 3 is all-absent, uncounted
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: FAIL — could not find function `.venn_regions`.

- [ ] **Step 3: Write minimal implementation**

Create `R/venn-plot.R`:

```r
# venn-plot.R
# Venn diagram for 2-3 sets. The small-set-count sibling of hv_upset(): reads
# the same logical / 0-1 set-membership columns and renders overlapping circles
# via ggvenn. Use hv_upset() when there are more than three sets.
#
# `region` and `n` are columns of the region-count table; suppress R CMD check
# notes about undefined globals.
utils::globalVariables(c("region", "n"))

# ---------------------------------------------------------------------------
# Internal: enumerate the 2^k - 1 non-empty Venn regions and count the rows
# matching each exact in/out membership pattern. NA membership counts as
# absent (FALSE), matching hv_upset().
.venn_regions <- function(data, sets) {
  ind <- as.matrix(data[sets])
  mode(ind) <- "logical"
  ind[is.na(ind)] <- FALSE

  k        <- length(sets)
  patterns <- expand.grid(rep(list(c(FALSE, TRUE)), k))
  names(patterns) <- sets
  patterns <- patterns[rowSums(patterns) > 0, , drop = FALSE]  # drop all-absent

  key_pat <- apply(patterns, 1L, function(r) paste(as.integer(r), collapse = ""))
  key_row <- apply(ind,      1L, function(r) paste(as.integer(r), collapse = ""))
  counts  <- as.integer(table(factor(key_row, levels = key_pat)))

  region <- vapply(seq_len(nrow(patterns)), function(i) {
    inset <- sets[unlist(patterns[i, ], use.names = FALSE)]
    if (length(inset) == 1L) paste0(inset, " only")
    else paste(inset, collapse = " & ")
  }, character(1L))

  out <- cbind(patterns, region = region, n = counts, stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add R/venn-plot.R tests/testthat/test_venn.R
git commit -m "feat: add .venn_regions() region-count helper"
```

---

### Task 2: `hv_venn()` constructor + validation

**Files:**
- Modify (append to): `R/venn-plot.R`
- Test (append to): `tests/testthat/test_venn.R`

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test_venn.R`:

```r
test_that("hv_venn returns an hv_venn / hv_data object with region table", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
  expect_s3_class(v, "hv_venn")
  expect_s3_class(v, "hv_data")
  expect_equal(v$meta$sets, c("AV_Replacement", "MV_Replacement", "CABG"))
  expect_equal(v$meta$n_sets, 3L)
  expect_equal(nrow(v$tables$regions), 7L)
})

test_that("hv_venn errors on fewer than 2 sets", {
  dta <- sample_upset_data(n = 50, seed = 1)
  expect_error(hv_venn(dta, sets = "CABG"), "at least 2")
})

test_that("hv_venn errors on more than 3 sets and names hv_upset", {
  dta <- sample_upset_data(n = 50, seed = 1)
  expect_error(
    hv_venn(dta, sets = c("AV_Replacement", "AV_Repair",
                          "MV_Replacement", "CABG")),
    "hv_upset"
  )
})

test_that("hv_venn errors on a non-binary column", {
  dta <- sample_upset_data(n = 50, seed = 1)
  dta$age <- rnorm(nrow(dta), 65, 10)
  expect_error(hv_venn(dta, sets = c("CABG", "age")), "binary")
})

test_that("hv_venn errors on a missing column", {
  dta <- sample_upset_data(n = 50, seed = 1)
  expect_error(hv_venn(dta, sets = c("CABG", "nonexistent")),
               "not found|not a column|not in")
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: FAIL — could not find function `hv_venn`.

- [ ] **Step 3: Write minimal implementation**

Append to `R/venn-plot.R`:

```r
#' Prepare a Venn diagram for plotting
#'
#' Validates a wide set-membership data frame and returns an \code{hv_venn}
#' object carrying a region-count table. Call \code{\link{plot.hv_venn}} on the
#' result for a bare \pkg{ggplot2} Venn diagram. \code{hv_venn()} is the
#' small-set-count companion to \code{\link{hv_upset}}, reading the same input;
#' for more than three sets use \code{\link{hv_upset}}.
#'
#' @param data A data frame; one row per patient. Each set column must be
#'   logical or 0/1 numeric.
#' @param sets Character vector of \strong{2 to 3} column names to draw as sets.
#'
#' @return An object of class \code{c("hv_venn", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{The input data frame.}
#'   \item{\code{$meta}}{Named list: \code{sets}, \code{n_patients},
#'     \code{n_sets}.}
#'   \item{\code{$tables$regions}}{A data frame with one logical column per set
#'     (the in/out membership pattern), a \code{region} label, and \code{n}
#'     (patients in that exact region).}
#' }
#'
#' @seealso \code{\link{plot.hv_venn}}, \code{\link{hv_upset}},
#'   \code{\link{sample_upset_data}}
#'
#' @examples
#' dta <- sample_upset_data(n = 300, seed = 42)
#' v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
#' v$tables$regions
#'
#' @export
hv_venn <- function(data, sets) {
  .check_df(data)
  if (!(is.character(sets) && length(sets) >= 2L))
    stop("`sets` must be a character vector of at least 2 column names.",
         call. = FALSE)
  if (length(sets) > 3L)
    stop("`hv_venn()` supports at most 3 sets; use `hv_upset()` for more.",
         call. = FALSE)
  .check_cols(data, sets)
  non_binary <- sets[!vapply(data[sets], function(x)
    is.logical(x) || (is.numeric(x) && all(x %in% c(0, 1, NA))),
    logical(1))]
  if (length(non_binary) > 0L)
    stop("hv_venn requires binary (0/1 or logical) columns. ",
         "Non-binary column(s): ", paste(non_binary, collapse = ", "), ".",
         call. = FALSE)

  data <- as.data.frame(data)
  new_hv_data(
    data = data,
    meta = list(
      sets       = sets,
      n_patients = nrow(data),
      n_sets     = length(sets)
    ),
    tables   = list(regions = .venn_regions(data, sets)),
    subclass = "hv_venn"
  )
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: PASS (the 5 new tests plus Task 1's).

- [ ] **Step 5: Commit**

```bash
git add R/venn-plot.R tests/testthat/test_venn.R
git commit -m "feat: hv_venn() constructor with 2-3 set validation"
```

---

### Task 3: `plot.hv_venn()` renderer

**Files:**
- Modify (append to): `R/venn-plot.R`
- Test (append to): `tests/testthat/test_venn.R`

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test_venn.R`:

```r
test_that("plot(hv_venn) returns a ggplot", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  expect_s3_class(plot(v), "ggplot")
})

test_that("plot(hv_venn) is composable with theme_hv_manuscript()", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
  p   <- plot(v) + theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_venn) honours show_percentage and a fill override", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  p   <- plot(v, show_percentage = FALSE,
              fill = c("steelblue", "firebrick"))
  expect_s3_class(p, "ggplot")
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: FAIL — no applicable method for `plot` applied to an object of class `hv_venn` (falls back to default and errors, or "could not find").

- [ ] **Step 3: Write minimal implementation**

Append to `R/venn-plot.R`:

```r
#' Plot an hv_venn object
#'
#' Draws a 2-3 set Venn diagram using \code{ggvenn::ggvenn()} and returns a
#' bare \pkg{ggplot2} object you can finish with \code{+}.
#'
#' @param x An \code{hv_venn} object.
#' @param show_percentage Logical; show each region's percentage. Default
#'   \code{TRUE}.
#' @param show_counts Logical; show each region's count. Default \code{TRUE}.
#' @param fill Optional vector of fill colours, one per set. \code{NULL}
#'   (default) uses \pkg{ggvenn}'s palette.
#' @param text_size Region label text size. Default \code{4}.
#' @param set_name_size Set name text size. Default \code{6}.
#' @param ... Forwarded to \code{ggvenn::ggvenn()} for finer styling (unlike
#'   most \code{plot.hv_*} methods, which ignore \code{...}; \pkg{ggvenn} bakes
#'   labels into its geoms, so forwarding is the only way to reach them).
#'
#' @return A \code{\link[ggplot2]{ggplot}} object. Compose with
#'   \code{\link{theme_hv_manuscript}}, \code{labs()}, etc.
#'
#' @seealso \code{\link{hv_venn}}
#'
#' @examples
#' dta <- sample_upset_data(n = 300, seed = 42)
#' v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
#' plot(v) + theme_hv_manuscript()
#'
#' @export
plot.hv_venn <- function(x, show_percentage = TRUE, show_counts = TRUE,
                         fill = NULL, text_size = 4, set_name_size = 6, ...) {
  args <- list(
    data            = x$data,
    columns         = x$meta$sets,
    show_percentage = show_percentage,
    show_counts     = show_counts,
    text_size       = text_size,
    set_name_size   = set_name_size,
    ...
  )
  if (!is.null(fill)) args$fill_color <- fill
  do.call(ggvenn::ggvenn, args)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/venn-plot.R tests/testthat/test_venn.R
git commit -m "feat: plot.hv_venn() renders a ggvenn diagram"
```

---

### Task 4: `print.hv_venn()`

**Files:**
- Modify (append to): `R/venn-plot.R`
- Test (append to): `tests/testthat/test_venn.R`

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test_venn.R`:

```r
test_that("print.hv_venn produces a <hv_venn> header", {
  dta <- sample_upset_data(n = 100, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  expect_output(print(v), "<hv_venn>")
})

test_that("print.hv_venn returns x invisibly", {
  dta <- sample_upset_data(n = 100, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  ret <- withVisible(print(v))
  expect_false(ret$visible)
  expect_identical(ret$value, v)
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: FAIL — the default print method runs, no `<hv_venn>` output.

- [ ] **Step 3: Write minimal implementation**

Append to `R/venn-plot.R`:

```r
#' Print an hv_venn object
#'
#' @param x An \code{hv_venn} object from \code{\link{hv_venn}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_venn <- function(x, ...) {
  m <- x$meta
  cat("<hv_venn>\n")
  cat(sprintf("  N patients  : %d  (%d sets)\n", m$n_patients, m$n_sets))
  cat(sprintf("  Sets        : %s\n", paste(m$sets, collapse = ", ")))
  cat(sprintf("  Regions     : %d\n", nrow(x$tables$regions)))
  invisible(x)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test_venn.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/venn-plot.R tests/testthat/test_venn.R
git commit -m "feat: print.hv_venn() header"
```

---

### Task 5: Dependency, docs, pkgdown, release

**Files:**
- Modify: `DESCRIPTION`, `NAMESPACE` (generated), `man/` (generated), `_pkgdown.yml`, `vignettes/plot-functions.qmd`, `README.md`, `NEWS.md`

- [ ] **Step 1: Add `ggvenn` to Imports**

In `DESCRIPTION`, in the `Imports:` block, add a line `    ggvenn,` (alphabetical order is not required by the existing file; place it near `ggupset`). For example, change:

```
    ggupset (>= 0.4.0),
```

to:

```
    ggupset (>= 0.4.0),
    ggvenn,
```

- [ ] **Step 2: Regenerate roxygen docs + NAMESPACE**

Run: `Rscript -e 'devtools::document()'`
Expected: creates `man/hv_venn.Rd`, `man/plot.hv_venn.Rd`, `man/print.hv_venn.Rd`; `NAMESPACE` gains `export(hv_venn)`, `S3method(plot, hv_venn)`, `S3method(print, hv_venn)`.

- [ ] **Step 3: Add the three topics to `_pkgdown.yml`**

In `_pkgdown.yml`, find the `- title: "Exploratory Data Analysis"` section (it lists `hv_upset` / `plot.hv_upset` / `print.hv_upset`). Add the three Venn topics after the upset entries:

```yaml
  - hv_upset
  - plot.hv_upset
  - print.hv_upset
  - hv_venn
  - plot.hv_venn
  - print.hv_venn
```

- [ ] **Step 4: Add a vignette example**

In `vignettes/plot-functions.qmd`, find the UpSet section (search for `hv_upset(`). After it, add:

````markdown
### Venn diagram (2-3 sets)

For two or three overlapping groups, `hv_venn()` draws the familiar
overlapping-circle Venn. It reads the same logical set-membership columns as
`hv_upset()`, so the same data drives either view; reach for `hv_upset()` once
there are more than three sets. The region counts behind the figure are kept in
`v$tables$regions` for a methods table.

```{r}
#| label: fig-venn
#| fig-width: 6
#| fig-height: 5
dta <- sample_upset_data(n = 400, seed = 7)
v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))

plot(v) + theme_hv_manuscript()
```
````

- [ ] **Step 5: Add a README gallery row**

In `README.md`, in the "Exploratory & Multivariate" table (the one listing `hv_upset()`), add a row:

```markdown
| `hv_venn()` | Venn diagram of 2-3 overlapping set memberships, with a region-count table; the small-set-count companion to `hv_upset()` |
```

- [ ] **Step 6: Bump version and NEWS**

In `DESCRIPTION` line 4, set the next minor version. If the current value is `2.4.0`, change it to `2.6.0` (the numbers-at-risk work claims 2.5.0). If `DESCRIPTION` already reads `2.5.0` (that PR merged first), change it to `2.6.0`. Run `grep '^Version' DESCRIPTION` first and bump to one minor above whatever is there, ending in `.0`.

In `NEWS.md`, add a new top section above the current top entry, using the SAME version string you set in `DESCRIPTION`:

```markdown
# hvtiPlotR 2.6.0

## New features

- `hv_venn()` draws a 2-3 set Venn diagram of overlapping set memberships — the
  small-set-count companion to `hv_upset()`, reading the same logical / 0-1
  set-membership columns. It returns an object carrying a `$tables$regions`
  count table (one row per Venn region), and `plot()` renders a bare ggplot via
  ggvenn that you finish with `+ theme_hv_*`. For more than three sets, use
  `hv_upset()`.

**Dependency:** `ggvenn` added to `Imports`.

```

- [ ] **Step 7: Run the full suite and check**

Run: `Rscript -e 'devtools::document(); res <- devtools::check(args="--no-manual", quiet=TRUE); cat("E", length(res$errors), "W", length(res$warnings), "N", length(res$notes), "\n"); cat(res$errors, res$warnings, res$notes, sep="\n---\n")'`
Expected: full test suite green; the only check findings should be the pre-existing stray-untracked-file WARNING + NOTE (the `Yahoo slide template LIGHT ROOM.pptx` filename and `hazard_fixtures_key*` top-level files). Any error/warning/note that references `hv_venn`, `venn-plot`, the new Rd files, `ggvenn`, or a NEWS-version mismatch is a real problem — fix it (the NEWS top header must equal the `DESCRIPTION` version exactly).

- [ ] **Step 8: Commit**

```bash
git add DESCRIPTION NAMESPACE man/ _pkgdown.yml vignettes/plot-functions.qmd README.md NEWS.md
git commit -m "docs: document hv_venn(), add ggvenn dep, bump version"
```

---

## Notes for the implementer

- `ggvenn` is a hard `Imports`, so no `requireNamespace()` guards or `skip_if_not_installed()` are needed.
- Mirror `R/upset-plot.R` for style — same validators, same `new_hv_data()` shape, same print-header format.
- `plot.hv_venn()` forwards `...` to `ggvenn::ggvenn()` on purpose (documented in the roxygen). Do not "fix" it to ignore `...`.
- Do NOT stage the stray untracked files (`.codegraph/`, `hazard_fixtures_key*`, `inst/extdata/Yahoo slide template LIGHT ROOM.pptx`).
- `_pkgdown.yml` MUST list the new exported topics (Step 3) — omitting them fails the pkgdown CI job, as happened on an earlier PR.
- This branch (`feat/venn-diagram`) is off `main`; open a PR when done; **John merges**.
