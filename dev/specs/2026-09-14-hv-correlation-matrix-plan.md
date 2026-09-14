# hv_correlation_matrix() Implementation Plan (hvtiPlotR)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `hvtiPlotR::hv_correlation_matrix()` (+ `sample_correlation_data()`),
the plot half of the SAS `proc corr ... plots=matrix` job, for the `dc-tables` template.

**Architecture:** Follows the package's two-step contract: `hv_correlation_matrix()`
returns an `hv_data` subclass (`$data` long lower-triangle pairs, `$meta`,
`$tables$coefficients`); `plot.hv_correlation_matrix()` returns a **bare** ggplot
(`geom_point` + `facet_grid`) the caller decorates with `theme_hv_*()`.
No GGally dependency.

**Tech Stack:** ggplot2 (already Imports), testthat 3e.

## Global Constraints

- Source: hvtiRtemplates `dev/specs/2026-09-09-eda-templates-design.md` §6: "scatter-plot
  matrix, mirroring `plots=matrix`. Returns an `hv_data`-classed object with a
  `sample_*_data()` companion, per that package's convention."
- Construct through `new_hv_data(data, meta, tables, subclass)` (`R/hvti-data.R`).
- Validate with the package's existing `.check_df()` / `.check_cols()` (used by `hv_eda()`).
- Lower triangle only: k(k−1)/2 panels. At exemplar scale (17 vars × ~11,000 rows)
  the full matrix would be ~3M points; the triangle halves it, and the upper
  triangle duplicates it anyway.
- No new Imports. Branch `feat/hv-correlation-matrix`; PR; no version bump in the PR;
  NEWS entry at the top under a `# hvtiPlotR (unreleased)` heading (add it if absent).

---

### Task 0: Branch and commit this plan

- [ ] `cd ~/Documents/GitHub/hvtiPlotR && git fetch origin && git switch -c feat/hv-correlation-matrix origin/main`
- [ ] Copy this file to `dev/specs/2026-09-14-hv-correlation-matrix-plan.md`; commit `docs: plan hv_correlation_matrix()`.

### Task 1: Data object and sample data

**Files:**
- Create: `R/correlation-matrix.R`
- Test: `tests/testthat/test-correlation-matrix.R`

**Interfaces:**
- Produces: `sample_correlation_data(n = 300, seed = 42)` → data.frame
  `a1c, glucose, creatinine, albumin, a1c_grp`;
  `hv_correlation_matrix(data, vars, labels = NULL, method = c("pearson", "spearman"))`
  → object of class `c("hv_correlation_matrix", "hv_data")` with
  `$data` (`col_var`, `row_var` factors; `x`, `y` numeric),
  `$meta` (`vars`, `labels`, `method`, `n_obs`), `$tables$coefficients` (k×k matrix, dimnames = labels).

- [ ] **Step 1: Failing tests**

```r
test_that("sample_correlation_data is deterministic and shaped", {
  a <- sample_correlation_data(n = 50, seed = 1)
  expect_identical(a, sample_correlation_data(n = 50, seed = 1))
  expect_equal(nrow(a), 50L)
  expect_true(all(c("a1c", "glucose", "creatinine", "albumin", "a1c_grp") %in% names(a)))
})

test_that("hv_correlation_matrix builds the lower triangle", {
  d <- sample_correlation_data(n = 100)
  cm <- hv_correlation_matrix(d, vars = c("a1c", "glucose", "creatinine", "albumin"))
  expect_s3_class(cm, c("hv_correlation_matrix", "hv_data"))
  panels <- unique(cm$data[c("col_var", "row_var")])
  expect_equal(nrow(panels), 6L)
  # lower triangle: the row variable always comes after the column variable
  expect_true(all(as.integer(panels$row_var) > as.integer(panels$col_var)))
  expect_equal(nrow(cm$data), 6L * 100L)
})

test_that("rows missing either coordinate are dropped per panel", {
  d <- sample_correlation_data(n = 100)
  d$glucose[1:10] <- NA
  cm <- hv_correlation_matrix(d, vars = c("a1c", "glucose", "albumin"))
  counts <- table(paste(cm$data$col_var, cm$data$row_var))
  expect_equal(as.integer(counts[["a1c glucose"]]), 90L)
  expect_equal(as.integer(counts[["a1c albumin"]]), 100L)
})

test_that("coefficients are the pairwise matrix under labels", {
  d <- sample_correlation_data(n = 100)
  cm <- hv_correlation_matrix(d, vars = c("a1c", "glucose"),
                              labels = c("HbA1c", "Glucose"), method = "spearman")
  expect_equal(dimnames(cm$tables$coefficients)[[1]], c("HbA1c", "Glucose"))
  expect_equal(cm$tables$coefficients[1, 2],
               stats::cor(d$a1c, d$glucose, method = "spearman"))
  expect_equal(levels(cm$data$col_var), c("HbA1c", "Glucose"))
})

test_that("errors are clear", {
  d <- sample_correlation_data(n = 20)
  expect_error(hv_correlation_matrix(d, vars = "a1c"), "at least two")
  expect_error(hv_correlation_matrix(d, vars = c("a1c", "a1c_grp")), "numeric")
  expect_error(hv_correlation_matrix(d, vars = c("a1c", "glucose"), labels = "x"),
               "one label per")
})
```

- [ ] **Step 2: Run** `Rscript -e 'devtools::test(filter = "correlation-matrix")'` → FAIL (function not found).
- [ ] **Step 3: Implement** in `R/correlation-matrix.R`:

```r
#' Sample data for hv_correlation_matrix()
#'
#' Simulated preoperative labs with a built-in dependence on HbA1c, shaped
#' like the correlation job it stands in for.
#'
#' @param n Number of patients.
#' @param seed Random seed.
#' @return A data frame with numeric `a1c`, `glucose`, `creatinine`,
#'   `albumin`, and a three-level factor `a1c_grp`.
#' @examples
#' head(sample_correlation_data(n = 10))
#' @export
sample_correlation_data <- function(n = 300, seed = 42) {
  set.seed(seed)
  a1c <- stats::rnorm(n, 6.5, 1.2)
  data.frame(
    a1c        = round(a1c, 1),
    glucose    = round(20 * a1c + stats::rnorm(n, 0, 25)),
    creatinine = round(stats::rlnorm(n, 0, 0.3), 2),
    albumin    = round(4 - 0.1 * a1c + stats::rnorm(n, 0, 0.4), 1),
    a1c_grp    = cut(a1c, c(-Inf, 6, 7, Inf), labels = c("<6", "6-7", ">7"))
  )
}

#' Prepare a scatter-plot matrix
#'
#' The plot half of SAS `proc corr ... plots=matrix`: one scatter panel per
#' unordered pair of `vars`, lower triangle only. Call [plot()] on the result
#' for a bare `ggplot`; the coefficient table with Fisher intervals is
#' `hvtiRtables::hv_correlation_table()`.
#'
#' Rows missing either coordinate are dropped panel by panel (pairwise
#' deletion, as `proc corr` does), so a variable with missing values thins
#' only the panels it appears in.
#'
#' @param data Data frame; one row per patient.
#' @param vars Character vector of at least two numeric columns, in display order.
#' @param labels Optional character vector of display labels, one per `vars`.
#' @param method Coefficient stored in `$tables$coefficients`: `"pearson"` or `"spearman"`.
#' @return An object of class `c("hv_correlation_matrix", "hv_data")`:
#'   `$data` (columns `col_var`, `row_var`, `x`, `y`), `$meta` (`vars`,
#'   `labels`, `method`, `n_obs`), and `$tables$coefficients`, the pairwise
#'   coefficient matrix.
#' @seealso [plot.hv_correlation_matrix()], [sample_correlation_data()]
#' @examples
#' d <- sample_correlation_data()
#' cm <- hv_correlation_matrix(d, c("a1c", "glucose", "creatinine", "albumin"))
#' plot(cm) + theme_hv_manuscript()
#' @export
hv_correlation_matrix <- function(data, vars, labels = NULL,
                                  method = c("pearson", "spearman")) {
  .check_df(data)
  method <- match.arg(method)
  if (!is.character(vars) || length(vars) < 2L)
    stop("`vars` needs at least two column names.", call. = FALSE)
  .check_cols(data, vars)
  not_num <- vars[!vapply(data[vars], is.numeric, logical(1))]
  if (length(not_num))
    stop("A scatter-plot matrix needs numeric columns; not numeric: ",
         paste(not_num, collapse = ", "), call. = FALSE)
  if (is.null(labels)) labels <- vars
  if (length(labels) != length(vars))
    stop("`labels` needs one label per `vars` entry (", length(vars), ").",
         call. = FALSE)

  idx <- utils::combn(seq_along(vars), 2L)
  long <- do.call(rbind, lapply(seq_len(ncol(idx)), function(p) {
    i <- idx[1L, p]
    j <- idx[2L, p]
    x <- data[[vars[i]]]
    y <- data[[vars[j]]]
    ok <- !is.na(x) & !is.na(y)
    data.frame(col_var = rep(labels[i], sum(ok)), row_var = rep(labels[j], sum(ok)),
               x = x[ok], y = y[ok], stringsAsFactors = FALSE)
  }))
  long$col_var <- factor(long$col_var, levels = labels)
  long$row_var <- factor(long$row_var, levels = labels)

  coef <- suppressWarnings(stats::cor(data[vars], use = "pairwise.complete.obs",
                                      method = method))
  dimnames(coef) <- list(labels, labels)

  new_hv_data(
    data = long,
    meta = list(vars = vars, labels = labels, method = method,
                n_obs = nrow(data)),
    tables = list(coefficients = coef),
    subclass = "hv_correlation_matrix"
  )
}
```

- [ ] **Step 4: Run** → PASS. **Step 5: Commit** `feat: hv_correlation_matrix() data object`.

### Task 2: Plot method

**Files:** Modify `R/correlation-matrix.R`; test in `tests/testthat/test-correlation-matrix.R`.

- [ ] **Step 1: Failing test**

```r
test_that("plot returns a bare faceted ggplot", {
  cm <- hv_correlation_matrix(sample_correlation_data(n = 50),
                              c("a1c", "glucose", "albumin"))
  p <- plot(cm)
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$facet, "FacetGrid")
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
})
```

- [ ] **Step 2: Implement**

```r
#' Plot an hv_correlation_matrix object
#'
#' Bare scatter-plot matrix: points only, free scales per panel, variable
#' names in the strips. Decorate with a `theme_hv_*()` theme.
#'
#' @param x An `hv_correlation_matrix` object.
#' @param alpha Point transparency; large cohorts need it low.
#' @param point_size Point size.
#' @param ... Ignored.
#' @return A `ggplot` object.
#' @importFrom rlang .data
#' @export
plot.hv_correlation_matrix <- function(x, alpha = 0.3, point_size = 0.6, ...) {
  ggplot2::ggplot(x$data, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_point(alpha = alpha, size = point_size) +
    ggplot2::facet_grid(rows = ggplot2::vars(.data$row_var),
                        cols = ggplot2::vars(.data$col_var),
                        scales = "free", switch = "both") +
    ggplot2::labs(x = NULL, y = NULL)
}
```

- [ ] **Step 3: Run** → PASS. **Step 4: Commit** `feat: plot method for hv_correlation_matrix`.

### Task 3: Docs, pkgdown, NEWS

- [ ] `Rscript -e 'devtools::document()'`; confirm `export(hv_correlation_matrix)`, `export(sample_correlation_data)`, `S3method(plot,hv_correlation_matrix)`.
- [ ] `_pkgdown.yml`: `grep -n "hv_eda" _pkgdown.yml`, and add `hv_correlation_matrix`, `plot.hv_correlation_matrix`, `sample_correlation_data` to that same section (pkgdown's `check` fails on topics missing from the index).
- [ ] `NEWS.md`: add at the top (above `# hvtiPlotR 2.7.13`), creating the heading if absent:

```markdown
# hvtiPlotR (unreleased)

## New `hv_correlation_matrix()`: the scatter-plot matrix of `proc corr plots=matrix`

Lower-triangle scatter panels over any set of numeric variables, pairwise
deletion per panel, and the coefficient matrix in `$tables$coefficients`.
`sample_correlation_data()` is its companion. It backs the `dc-tables` job
template; the coefficient table with Fisher intervals is
`hvtiRtables::hv_correlation_table()`.
```

- [ ] Definition of done: `devtools::test()`, `devtools::check()` 0/0/0, `lintr::lint_package()` clean. Push, `gh pr create`, maintainer merges.
- [ ] **After merge, separate commit (at most one version name per day):** name `2.7.14` in DESCRIPTION (`Version`, `Date`) and NEWS. Plan C pins `hvtiPlotR (>= 2.7.14)`.
