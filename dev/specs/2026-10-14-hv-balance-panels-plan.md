# hv_balance() panels, pairs and direct inputs: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `hv_balance()` accepts `cobalt::bal.tab()` / hvtiRpropensity `ps_*` objects (singly or as an
imputation list), facets by pairwise comparison, draws variance-ratio and KS panels beside SMD, and
reports a suggested figure height.

**Architecture:** A new file `R/covariate-balance-input.R` turns any supported input into one long data
frame (`variable`, `group`, `stat`, `pair`, `std_diff`). `hv_balance()` in `R/covariate-balance.R` runs
that adapter first, then the existing validation on the result, adding `stat` and `pair` columns for
data-frame input. `plot.hv_balance()` stays one bare ggplot, adding `facet_grid(pair ~ stat)` only when a
dimension has more than one level, with reference lines drawn per stat.

**Tech Stack:** R, ggplot2 (>= 4.0.0), testthat edition 3, roxygen2 with markdown on, cobalt 5.0.0 and
hvtiRpropensity 0.2.0 (Suggests only).

**Spec:** [`2026-10-14-hv-balance-panels-design.md`](2026-10-14-hv-balance-panels-design.md). Issue #219.

## Global Constraints

- Branch `feat/balance-panels` (exists; the spec is committed on it). Never push to `main`.
- No `cobalt::` or `hvtiRpropensity::` calls anywhere in `R/`; both go in **Suggests** only.
- Lines ≤ 120 characters; object names ≤ 35 characters; `lintr::lint_package()` must return zero.
- No em-dashes (U+2014) in any file you write; a hook rejects them. En dashes are fine for ranges.
- No raw Greek or combining Unicode in roxygen; `±` escapes in R strings are fine.
- Test files are `test_*.R` (underscore). Plot tests prove data with `expect_plot_has_data()` from
  `tests/testthat/helper-plot-data.R`, not just `expect_s3_class(p, "ggplot")`.
- Tests needing cobalt or hvtiRpropensity start with `skip_if_not_installed("cobalt")` /
  `skip_if_not_installed("hvtiRpropensity")`.
- No version bump; one `news/feat-balance-panels.md` fragment.
- Errors use `stop(..., call. = FALSE)`.
- Existing behaviour that must keep working: `hv_balance(list(variable = "x", group = "y", std_diff = 1))`
  errors with `"data.frame"`; every one of the 30 existing tests in `tests/testthat/test_covariate_balance.R`
  passes unchanged.

Run tests for this file with:

```bash
Rscript -e 'devtools::test(filter = "covariate_balance")'
```

---

## File structure

| file | responsibility |
|---|---|
| `R/covariate-balance-input.R` (create) | adapters: `bal.tab`, `bal.tab.multi`, `ps_data`, imputation lists, pooling |
| `R/covariate-balance.R` (modify) | constructor (`stat`/`pair` columns, new args, meta), print, plot (facets, per-stat lines), `hv_balance_height()` |
| `tests/testthat/helper-balance-fixtures.R` (create) | builders for cobalt / ps fixtures (38-term, three-group, exact-mean) |
| `tests/testthat/test_covariate_balance.R` (modify) | all new tests appended below the existing ones |
| `DESCRIPTION`, `_pkgdown.yml`, `NAMESPACE`, `man/`, `news/feat-balance-panels.md` | housekeeping |

---

### Task 1: `hv_balance_height()`

**Files:**
- Modify: `R/covariate-balance.R` (append after `plot.hv_balance()`, before the sample-data section at line 272)
- Modify: `_pkgdown.yml:147-149` (Propensity section)
- Test: `tests/testthat/test_covariate_balance.R` (append)

**Interfaces:**
- Produces: `hv_balance_height(n_rows, base_size = 12, n_pairs = 1)` returning a numeric scalar (inches).
  Task 2 calls it to fill `$meta$suggested_height`.

- [ ] **Step 1: Write the failing test** (append to `tests/testthat/test_covariate_balance.R`)

```r
# ---------------------------------------------------------------------------
# hv_balance_height
# ---------------------------------------------------------------------------

test_that("hv_balance_height gives about 8 in for 38 rows at 12 pt", {
  expect_equal(hv_balance_height(38), 0.17 * 38 + 1.5)
  expect_equal(round(hv_balance_height(38), 2), 7.96)
})

test_that("hv_balance_height scales with base_size", {
  expect_equal(hv_balance_height(38, base_size = 18), 1.5 * hv_balance_height(38))
})

test_that("hv_balance_height adds rows and strip space per pair", {
  expect_equal(hv_balance_height(10, n_pairs = 3), 0.17 * 30 + 0.3 * 2 + 1.5)
})

test_that("hv_balance_height rejects non-positive input", {
  expect_error(hv_balance_height(0), "n_rows")
  expect_error(hv_balance_height(10, base_size = -1), "base_size")
  expect_error(hv_balance_height(10, n_pairs = 0), "n_pairs")
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: FAIL, `could not find function "hv_balance_height"`.

- [ ] **Step 3: Implement** (in `R/covariate-balance.R`, after `plot.hv_balance()`)

```r
#' Suggested figure height for a covariate balance plot
#'
#' Covariate labels overprint when a balance plot is drawn too short. This
#' returns a height that leaves about 0.17 in per covariate row at 12 pt,
#' plus room for the x axis, its title and a legend, scaled by `base_size`.
#'
#' @param n_rows    Number of covariate rows (`length(var_levels)`).
#' @param base_size Theme base font size in points. Default `12`.
#' @param n_pairs   Number of pairwise-comparison facet rows. Default `1`.
#'
#' @return Height in inches, a numeric scalar.
#'
#' @seealso [hv_balance()], whose `$meta$suggested_height` holds this value
#'   at `base_size = 12`.
#'
#' @examples
#' hv_balance_height(38)                 # about 8 in
#' hv_balance_height(38, base_size = 16)
#' hv_balance_height(12, n_pairs = 3)    # three-group design
#'
#' @export
hv_balance_height <- function(n_rows, base_size = 12, n_pairs = 1) {
  .check_scalar_positive(n_rows,    "n_rows")
  .check_scalar_positive(base_size, "base_size")
  .check_scalar_positive(n_pairs,   "n_pairs")
  s <- base_size / 12
  s * (0.17 * n_rows * n_pairs + 0.3 * (n_pairs - 1) + 1.5)
}
```

In `_pkgdown.yml`, after the `- print.hv_balance` line add `  - hv_balance_height`.

- [ ] **Step 4: Document and run**

Run: `Rscript -e 'devtools::document()' && Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: PASS, `NAMESPACE` gains `export(hv_balance_height)`, `man/hv_balance_height.Rd` created.
If `.check_scalar_positive`'s message does not include the argument name, read it in
`R/validators.R:53` and adjust the `expect_error` regexps to its actual text.

- [ ] **Step 5: Commit**

```bash
git add R/covariate-balance.R tests/testthat/test_covariate_balance.R _pkgdown.yml NAMESPACE man/hv_balance_height.Rd
git commit -m "feat: hv_balance_height() suggests a figure height for balance plots (#219)"
```

---

### Task 2: Constructor data model (`stat`, `pair`, new arguments, meta, print)

**Files:**
- Modify: `R/covariate-balance.R` (helpers at top; `hv_balance()` lines 146-184; `print.hv_balance()` lines 193-205)
- Test: `tests/testthat/test_covariate_balance.R` (append)

**Interfaces:**
- Consumes: `hv_balance_height()` (Task 1).
- Produces:
  - `cb_stat_labels`: named character vector
    `c(smd = "Standardized difference (%)", variance_ratio = "Variance ratio", ks = "KS statistic")`.
  - `hv_balance(data, variable_col, group_col, std_diff_col, var_levels, threshold, stat_col = NULL,
    pair_col = NULL, stats = "smd", vr_threshold = c(0.5, 2), ks_threshold = NULL,
    group_labels = c("Before", "After"))`.
  - `$data` gains `stat` (factor, levels = `stats`) and `pair` (character `NA` when no pairs, else
    factor with levels in first-appearance order).
  - `$meta` gains `stats`, `pairs` (character, length 0 when none), `n_imputations` (integer),
    `vr_threshold`, `ks_threshold`, `suggested_height`.
  - Task 4 replaces the `long <- NULL` line with `long <- .cb_as_long(data, stats, group_labels)`.

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---------------------------------------------------------------------------
# hv_balance: stat / pair data model
# ---------------------------------------------------------------------------

cb_long_df <- function() {
  base <- sample_covariate_balance_data(n_vars = 4)
  rbind(
    transform(base, stat = "smd"),
    transform(base, stat = "ks", std_diff = abs(std_diff) / 100)
  )
}

test_that("hv_balance adds stat = smd and pair = NA for plain input", {
  cb <- hv_balance(sample_covariate_balance_data())
  expect_true(all(cb$data$stat == "smd"))
  expect_true(all(is.na(cb$data$pair)))
  expect_equal(cb$meta$stats, "smd")
  expect_identical(cb$meta$pairs, character(0))
  expect_equal(cb$meta$n_imputations, 1L)
})

test_that("hv_balance stores suggested_height from hv_balance_height", {
  cb <- hv_balance(sample_covariate_balance_data(n_vars = 12))
  expect_equal(cb$meta$suggested_height, hv_balance_height(12))
})

test_that("hv_balance keeps only the requested stats from stat_col", {
  cb <- hv_balance(cb_long_df(), stat_col = "stat")
  expect_equal(levels(cb$data$stat), "smd")
  expect_equal(nrow(cb$data), 8L)
  cb2 <- hv_balance(cb_long_df(), stat_col = "stat", stats = c("smd", "ks"))
  expect_equal(levels(cb2$data$stat), c("smd", "ks"))
  expect_equal(nrow(cb2$data), 16L)
})

test_that("hv_balance reads pair_col and records pairs in order", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"))
  cb <- hv_balance(d, pair_col = "cmp")
  expect_equal(cb$meta$pairs, c("B vs. A", "C vs. A"))
  expect_equal(levels(cb$data$pair), c("B vs. A", "C vs. A"))
  expect_equal(cb$meta$suggested_height, hv_balance_height(3, n_pairs = 2))
})

test_that("hv_balance errors when stats names a stat with no rows", {
  expect_error(
    hv_balance(sample_covariate_balance_data(), stats = c("smd", "ks")),
    "no rows"
  )
})

test_that("hv_balance errors on an unknown stats value", {
  expect_error(hv_balance(sample_covariate_balance_data(), stats = "mean"), "should be one of")
})

test_that("hv_balance errors on unknown values in stat_col", {
  d <- transform(sample_covariate_balance_data(), stat = "ovl")
  expect_error(hv_balance(d, stat_col = "stat"), "unknown statistic")
})

test_that("hv_balance refuses to overwrite an unnamed stat or pair column", {
  d <- transform(sample_covariate_balance_data(), stat = "x")
  expect_error(hv_balance(d), "already has a column named `stat`")
})

test_that("hv_balance validates vr_threshold, ks_threshold and group_labels", {
  d <- sample_covariate_balance_data()
  expect_error(hv_balance(d, vr_threshold = c(0.5, 2, 3)), "vr_threshold")
  expect_error(hv_balance(d, vr_threshold = -1), "vr_threshold")
  expect_error(hv_balance(d, ks_threshold = 1.5), "ks_threshold")
  expect_error(hv_balance(d, group_labels = "x"), "group_labels")
})

test_that("print.hv_balance reports stats, pairs and height", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"))
  out <- capture.output(print(hv_balance(d, pair_col = "cmp")))
  expect_true(any(grepl("Stats", out)))
  expect_true(any(grepl("B vs. A, C vs. A", out)))
  expect_true(any(grepl("Height", out)))
})
```

- [ ] **Step 2: Run to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: FAIL (`unused argument (stat_col = "stat")`, `$meta$stats` is `NULL`, and so on).

- [ ] **Step 3: Implement**

Add below `cb_validate_params()` in `R/covariate-balance.R`:

```r
cb_stat_labels <- c(
  smd            = "Standardized difference (%)",
  variance_ratio = "Variance ratio",
  ks             = "KS statistic"
)

cb_validate_stat_args <- function(vr_threshold, ks_threshold, group_labels) {
  if (!is.numeric(vr_threshold) || !length(vr_threshold) %in% 1:2 ||
      anyNA(vr_threshold) || any(vr_threshold <= 0))
    stop("`vr_threshold` must be one or two positive numbers.", call. = FALSE)
  if (!is.null(ks_threshold) &&
      (!is.numeric(ks_threshold) || length(ks_threshold) != 1L ||
       is.na(ks_threshold) || ks_threshold < 0 || ks_threshold > 1))
    stop("`ks_threshold` must be NULL or a single number in [0, 1].", call. = FALSE)
  if (!is.character(group_labels) || length(group_labels) != 2L || anyNA(group_labels))
    stop("`group_labels` must be a length-2 character vector.", call. = FALSE)
}

# Add the canonical `stat` and `pair` columns, keep only the requested stats
# and fix factor levels so facets follow `stats` and first-appearance order.
cb_add_stat_pair <- function(working, stat_col, pair_col, stats) {
  for (nm in c("stat", "pair")) {
    src <- if (nm == "stat") stat_col else pair_col
    if (nm %in% names(working) && !identical(src, nm))
      stop(sprintf(
        "`data` already has a column named `%s`; pass %s_col = \"%s\" to use it.",
        nm, nm, nm), call. = FALSE)
  }
  working[["stat"]] <- if (is.null(stat_col)) "smd" else as.character(working[[stat_col]])
  working[["pair"]] <- if (is.null(pair_col)) NA_character_ else as.character(working[[pair_col]])

  unknown <- setdiff(unique(working[["stat"]]), names(cb_stat_labels))
  if (length(unknown))
    stop(sprintf(
      "`stat_col` holds unknown statistic(s): %s. Expected smd, variance_ratio or ks.",
      paste(unknown, collapse = ", ")), call. = FALSE)
  absent <- setdiff(stats, working[["stat"]])
  if (length(absent))
    stop(sprintf("`stats` asks for %s, but `data` has no rows for it.",
                 paste(absent, collapse = " and ")), call. = FALSE)

  working <- working[working[["stat"]] %in% stats, , drop = FALSE]
  working[["stat"]] <- factor(working[["stat"]], levels = stats)
  if (!is.null(pair_col))
    working[["pair"]] <- factor(working[["pair"]], levels = unique(working[["pair"]]))
  working
}
```

Replace `hv_balance()` (signature and body, lines 146-184) with:

```r
hv_balance <- function(
  data,
  variable_col = "variable",
  group_col    = "group",
  std_diff_col = "std_diff",
  var_levels   = NULL,
  threshold    = 10,
  stat_col     = NULL,
  pair_col     = NULL,
  stats        = "smd",
  vr_threshold = c(0.5, 2),
  ks_threshold = NULL,
  group_labels = c("Before", "After")
) {
  stats <- match.arg(stats, names(cb_stat_labels), several.ok = TRUE)
  cb_validate_stat_args(vr_threshold, ks_threshold, group_labels)

  n_imputations <- 1L
  long <- NULL
  if (!is.null(long)) {
    data          <- long$data
    n_imputations <- long$n_imputations
    variable_col  <- "variable"
    group_col     <- "group"
    std_diff_col  <- "std_diff"
    stat_col      <- "stat"
    pair_col      <- "pair"
    # Two-group input has no comparisons: drop the all-NA column so the
    # label-completeness check does not reject it.
    if (all(is.na(data[["pair"]]))) {
      data[["pair"]] <- NULL
      pair_col <- NULL
    }
  }

  cb_validate_input(data, variable_col, group_col, std_diff_col)
  .check_cols(data, c(stat_col, pair_col))
  cb_validate_params(threshold, point_size = 3, hline_linewidth = 0.25,
                     vline_linewidth = 0.2)

  .check_complete_labels(data, c(variable_col, group_col, stat_col, pair_col))
  working <- cb_add_stat_pair(as.data.frame(data), stat_col, pair_col, stats)
  incomplete <- .count_incomplete(working, std_diff_col)

  if (is.null(var_levels))
    var_levels <- unique(as.character(working[[variable_col]]))

  working[["cb_index"]] <- as.integer(
    factor(working[[variable_col]], levels = var_levels)
  )

  pairs <- if (is.null(pair_col)) character(0) else levels(working[["pair"]])

  new_hv_data(
    data = working,
    meta = list(
      variable_col     = variable_col,
      group_col        = group_col,
      std_diff_col     = std_diff_col,
      var_levels       = var_levels,
      threshold        = threshold,
      n_vars           = length(var_levels),
      n_missing        = incomplete$n_missing,
      n_groups         = length(unique(working[[group_col]])),
      stats            = stats,
      pairs            = pairs,
      n_imputations    = n_imputations,
      vr_threshold     = vr_threshold,
      ks_threshold     = ks_threshold,
      suggested_height = hv_balance_height(length(var_levels),
                                           n_pairs = max(1L, length(pairs)))
    ),
    tables   = list(),
    subclass = "hv_balance"
  )
}
```

Note: `.count_incomplete()` now runs on `working` (after the stat filter), so rows of unrequested
stats never count as missing.

In `print.hv_balance()`, after the `Threshold` line add:

```r
  cat(sprintf("  Stats       : %s\n", paste(m$stats, collapse = ", ")))
  if (length(m$pairs))
    cat(sprintf("  Pairs       : %s\n", paste(m$pairs, collapse = ", ")))
  if (isTRUE(m$n_imputations > 1L))
    cat(sprintf("  Imputations : %d (mean)\n", m$n_imputations))
  cat(sprintf("  Height      : %.1f in at 12 pt (see hv_balance_height())\n",
              m$suggested_height))
```

Update the roxygen block of `hv_balance()`: add `@param` for `stat_col`, `pair_col`, `stats`,
`vr_threshold`, `ks_threshold` and `group_labels` (text from the spec's argument table), and extend
the `$data` / `$meta` items under `@return` with the new columns and elements.

- [ ] **Step 4: Run the tests**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'` and
`Rscript -e 'devtools::test(filter = "missing_data_contract")'`
Expected: PASS for both, including all 30 pre-existing tests.

- [ ] **Step 5: Commit**

```bash
git add R/covariate-balance.R tests/testthat/test_covariate_balance.R
git commit -m "feat: hv_balance() carries stat and pair columns and new panel arguments (#219)"
```

---

### Task 3: Plot facets and per-stat reference lines

**Files:**
- Modify: `R/covariate-balance.R` (`cb_build_plot()` lines 24-74; `plot.hv_balance()` lines 246-270 and its roxygen)
- Test: `tests/testthat/test_covariate_balance.R` (append)

**Interfaces:**
- Consumes: `$data$stat`, `$data$pair`, `$meta$stats`, `$meta$pairs`, `$meta$vr_threshold`,
  `$meta$ks_threshold`, `cb_stat_labels` (Task 2).
- Produces: `cb_build_plot(data, std_diff_col, group_col, var_levels, threshold, stats, pairs,
  vr_threshold, ks_threshold, point_size, alpha, hline_linetype, hline_linewidth, vline_linewidth,
  threshold_linetype)`.

- [ ] **Step 1: Write the failing tests** (append; reuses `cb_long_df()` from Task 2)

```r
# ---------------------------------------------------------------------------
# plot(hv_balance): facets and reference lines
# ---------------------------------------------------------------------------

cb_vline_by_panel <- function(p) {
  built <- ggplot2::ggplot_build(p)
  idx   <- which(vapply(p$layers, function(l) inherits(l$geom, "GeomVline"), logical(1)))
  do.call(rbind, lapply(idx, function(i) built$data[[i]][, c("PANEL", "xintercept")]))
}

test_that("plain two-group plot keeps FacetNull and its reference lines", {
  p <- plot(hv_balance(sample_covariate_balance_data()))
  expect_s3_class(p$facet, "FacetNull")
  expect_plot_has_data(p, geoms = c("GeomPoint", "GeomVline", "GeomHline"))
  expect_setequal(cb_vline_by_panel(p)$xintercept, c(0, -10, 10))
})

test_that("two stats facet by stat with free x and labelled strips", {
  p <- plot(hv_balance(cb_long_df(), stat_col = "stat", stats = c("smd", "ks")))
  expect_s3_class(p$facet, "FacetGrid")
  expect_plot_has_data(p, min_groups = 2)
  layout <- ggplot2::ggplot_build(p)$layout$layout
  expect_equal(nrow(layout), 2L)
  expect_equal(as.character(layout$stat), c("smd", "ks"))
})

test_that("reference lines land only in their own stat panel", {
  d <- rbind(cb_long_df(),
             transform(sample_covariate_balance_data(n_vars = 4), stat = "variance_ratio",
                       std_diff = 1))
  p <- plot(hv_balance(d, stat_col = "stat", stats = c("smd", "variance_ratio", "ks"),
                       ks_threshold = 0.1))
  v <- cb_vline_by_panel(p)
  expect_setequal(v$xintercept[v$PANEL == 1], c(0, -10, 10))
  expect_setequal(v$xintercept[v$PANEL == 2], c(1, 0.5, 2))
  expect_setequal(v$xintercept[v$PANEL == 3], c(0, 0.1))
})

test_that("no dotted KS line is drawn when ks_threshold is NULL", {
  p <- plot(hv_balance(cb_long_df(), stat_col = "stat", stats = c("smd", "ks")))
  v <- cb_vline_by_panel(p)
  expect_setequal(v$xintercept[v$PANEL == 2], 0)
})

test_that("pairs facet by row, one panel per pair, data in every panel", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"),
             transform(d, cmp = "C vs. B"))
  p <- plot(hv_balance(d, pair_col = "cmp"))
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$layout$layout), 3L)
  pts <- built$data[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))]]
  expect_setequal(unique(as.integer(pts$PANEL)), 1:3)
})
```

- [ ] **Step 2: Run to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: the new facet tests FAIL (`FacetNull` where `FacetGrid` expected; one panel, not 2 or 3).
The first new test may already pass, and that is fine.

- [ ] **Step 3: Implement**

Replace `cb_build_plot()` with:

```r
# Solid and dotted reference lines, one row per line, tagged with `stat` so
# each lands only in its own facet. With no stat facet the extra column is
# ignored.
cb_ref_lines <- function(stats, threshold, vr_threshold, ks_threshold) {
  solid_x <- c(smd = 0, variance_ratio = 1, ks = 0)
  dotted  <- list(smd = c(-threshold, threshold), variance_ratio = vr_threshold,
                  ks = ks_threshold)
  lvl <- function(s) factor(s, levels = stats)
  list(
    solid  = data.frame(stat = lvl(stats), x = unname(solid_x[stats])),
    dotted = do.call(rbind, lapply(stats, function(s)
      if (length(dotted[[s]])) data.frame(stat = lvl(s), x = dotted[[s]])))
  )
}

#' @importFrom rlang .data
#' @importFrom ggplot2 ggplot aes geom_vline geom_hline geom_point scale_y_continuous
cb_build_plot <- function(data, std_diff_col, group_col, var_levels,
                          threshold, stats, pairs, vr_threshold, ks_threshold,
                          point_size, alpha,
                          hline_linetype, hline_linewidth,
                          vline_linewidth, threshold_linetype) {
  n_vars <- length(var_levels)
  # Extra vertical space (in "covariate rows") above the top row to ensure
  # room for point glyphs and potential multi-line labels/annotations.
  y_padding <- 1.75
  refs <- cb_ref_lines(stats, threshold, vr_threshold, ks_threshold)

  p <- ggplot2::ggplot(data) +
    # Solid center reference: 0 for SMD and KS, 1 for the variance ratio
    ggplot2::geom_vline(
      data = refs$solid, ggplot2::aes(xintercept = .data[["x"]]),
      linewidth = vline_linewidth, color = "black"
    )
  if (!is.null(refs$dotted))
    # Dotted threshold reference lines
    p <- p + ggplot2::geom_vline(
      data = refs$dotted, ggplot2::aes(xintercept = .data[["x"]]),
      linetype = threshold_linetype, color = "black"
    )

  p <- p +
    # Dashed horizontal guides, one per covariate row
    ggplot2::geom_hline(
      yintercept = seq_len(n_vars),
      linetype   = hline_linetype,
      linewidth  = hline_linewidth,
      color      = "black"
    ) +
    # Points: shape and color mapped to group; no defaults applied
    ggplot2::geom_point(
      ggplot2::aes(
        x      = .data[[std_diff_col]],
        y      = .data[["cb_index"]],
        shape  = .data[[group_col]],
        color  = .data[[group_col]]
      ),
      size  = point_size,
      alpha = alpha
    ) +
    # Y-axis: integer positions labeled with covariate names
    ggplot2::scale_y_continuous(
      limits = c(0, n_vars + y_padding),
      breaks = seq_len(n_vars),
      labels = var_levels
    )

  # Named vars() keep the facet variable called `stat`, which the labeller
  # looks up by name.
  facet_rows <- if (length(pairs) > 1L) ggplot2::vars(pair = .data[["pair"]])
  facet_cols <- if (length(stats) > 1L) ggplot2::vars(stat = .data[["stat"]])
  if (!is.null(facet_rows) || !is.null(facet_cols))
    p <- p + ggplot2::facet_grid(
      rows     = facet_rows,
      cols     = facet_cols,
      scales   = "free_x",
      labeller = ggplot2::labeller(stat = ggplot2::as_labeller(cb_stat_labels))
    )
  p
}
```

Add this assertion to the "two stats facet" test so the strip labels are checked, not assumed:

```r
  lab <- p$facet$params$labeller(data.frame(stat = c("smd", "ks")))[[1]]
  expect_equal(lab, c("Standardized difference (%)", "KS statistic"))
```

If the installed ggplot2 stores the labeller elsewhere, render once with `ggplot2::ggplot_gtable()`
and assert the strip text contains "Standardized difference" instead.

Single-pair case: a `pair_col` with one level gives `length(pairs) == 1`, so no row facet. That is
intentional; the strip would add nothing.

In `plot.hv_balance()`, pass the new arguments through:

```r
  cb_build_plot(
    data               = x$data,
    std_diff_col       = x$meta$std_diff_col,
    group_col          = x$meta$group_col,
    var_levels         = x$meta$var_levels,
    threshold          = x$meta$threshold,
    stats              = x$meta$stats,
    pairs              = x$meta$pairs,
    vr_threshold       = x$meta$vr_threshold,
    ks_threshold       = x$meta$ks_threshold,
    point_size         = point_size,
    alpha              = alpha,
    hline_linetype     = hline_linetype,
    hline_linewidth    = hline_linewidth,
    vline_linewidth    = vline_linewidth,
    threshold_linetype = threshold_linetype
  )
```

Add `@importFrom ggplot2 facet_grid vars labeller as_labeller` to the `cb_build_plot` block. Extend the
`plot.hv_balance()` `@description` with one paragraph: with more than one stat, panels sit side by side
(free x scales, labelled strips); with more than one pair, each pair gets a facet row; the variance
ratio panel has a solid line at 1 and dotted lines at `vr_threshold`, and the KS panel has a solid line
at 0 plus `ks_threshold` when given.

- [ ] **Step 4: Run the tests**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: PASS, including the 30 pre-existing tests (the old "threshold vlines appear" test now finds
±15 in the single dotted layer).

- [ ] **Step 5: Commit**

```bash
git add R/covariate-balance.R tests/testthat/test_covariate_balance.R
git commit -m "feat: plot.hv_balance() facets by stat and pair with per-panel reference lines (#219)"
```

---

### Task 4: `bal.tab` and `bal.tab.multi` adapter

**Files:**
- Create: `R/covariate-balance-input.R`
- Create: `tests/testthat/helper-balance-fixtures.R`
- Modify: `R/covariate-balance.R` (the `long <- NULL` line from Task 2)
- Modify: `DESCRIPTION` (Suggests, Remotes)
- Test: `tests/testthat/test_covariate_balance.R` (append)

**Interfaces:**
- Consumes: `cb_stat_labels` (Task 2), the canonical-column branch in `hv_balance()` (Task 2).
- Produces:
  - `.cb_from_baltab(x, stats, group_labels)` returns a data frame with columns `variable`, `group`,
    `stat`, `pair`, `std_diff` (character, character, character, character, numeric).
  - `.cb_is_source(x)` returns a logical scalar.
  - `.cb_as_long(x, stats, group_labels)` returns `NULL` (not an adapter input) or
    `list(data = <data frame>, n_imputations = <integer>)`. Task 5 adds the `ps_data` branch; Task 6
    adds lists.

- [ ] **Step 1: Add the dependencies**

In `DESCRIPTION`, add to `Suggests:` (keep the existing order, append at the end):

```
    cobalt (>= 4.5.0),
    hvtiRpropensity
```

and to `Remotes:` add a line `    ehrlinger/hvtiRpropensity` after `davidsjoberg/ggsankey` (comma-separate
the entries).

- [ ] **Step 2: Write the fixtures** (`tests/testthat/helper-balance-fixtures.R`)

```r
# Fixtures for hv_balance() input adapters. Each builder needs cobalt and/or
# hvtiRpropensity; callers guard with skip_if_not_installed().

# Simulated cohort with `n_terms` covariates (alternating continuous and
# binary) and a treatment driven by the first few.
balance_cohort <- function(n_terms = 38, n = 400, seed = 1) {
  withr::local_seed(seed)
  x <- lapply(seq_len(n_terms), function(j)
    if (j %% 2) stats::rnorm(n) else stats::rbinom(n, 1, 0.4))
  names(x) <- sprintf("x%02d", seq_len(n_terms))
  d <- as.data.frame(x)
  lp <- 0.8 * d$x01 + 0.6 * d$x03 - 0.5 * d$x02
  d$treat <- stats::rbinom(n, 1, stats::plogis(lp))
  d
}

# bal.tab of a cohort with SMD, variance ratio and KS, unadjusted and weighted.
balance_baltab <- function(d, binary = "std") {
  covs <- setdiff(names(d), "treat")
  ps   <- stats::fitted(stats::glm(treat ~ ., data = d, family = stats::binomial()))
  w    <- ifelse(d$treat == 1, 1 / ps, 1 / (1 - ps))
  cobalt::bal.tab(d[covs], treat = d$treat, weights = w, binary = binary,
                  s.d.denom = "pooled", stats = c("m", "v", "ks"), un = TRUE)
}

# Three-group bal.tab.multi with all pairwise comparisons, unadjusted.
balance_baltab_multi <- function(n = 600, seed = 2) {
  withr::local_seed(seed)
  d <- data.frame(age = stats::rnorm(n, 70, 8), female = stats::rbinom(n, 1, 0.4))
  d$grp <- sample(c("A", "B", "C"), n, replace = TRUE)
  cobalt::bal.tab(d[c("age", "female")], treat = d$grp, binary = "std",
                  s.d.denom = "pooled", stats = c("m", "v", "ks"),
                  which.treat = cobalt::.all)
}

# Exact mean balance with a distributional gap: both groups have mean 0
# exactly, but treated values sit at +/-1.5 while controls are normal. Every
# SMD is 0; the KS statistic is large.
balance_exact_mean <- function(n = 400, seed = 3) {
  withr::local_seed(seed)
  ctl <- stats::rnorm(n)
  trt <- sample(c(-1.5, 1.5), n, replace = TRUE) + stats::rnorm(n, sd = 0.1)
  d <- data.frame(treat = rep(0:1, each = n),
                  year  = c(ctl - mean(ctl), trt - mean(trt)),
                  age   = stats::rnorm(2 * n))
  d$age <- d$age - stats::ave(d$age, d$treat)
  cobalt::bal.tab(d[c("year", "age")], treat = d$treat, binary = "std",
                  s.d.denom = "pooled", stats = c("m", "v", "ks"))
}
```

Before relying on them, check in a console that `balance_baltab(balance_cohort())$Balance` has the six
`Diff`/`V.Ratio`/`KS` `.Un`/`.Adj` columns, that `names(balance_baltab_multi()$Pair.Balance)` is
three pairs, and that `balance_exact_mean()$Balance["year", "KS.Un"]` exceeds 0.2 while
`Diff.Un` is within `1e-8` of 0. If `cobalt::.all` is not exported in 5.0.0, use
`which.treat = .all` after `library(cobalt)` inside the builder, or `which.treat = c("A", "B", "C")`
per `?cobalt::bal.tab.multi`.

- [ ] **Step 3: Write the failing tests** (append)

```r
# ---------------------------------------------------------------------------
# hv_balance: bal.tab input
# ---------------------------------------------------------------------------

test_that("hv_balance reads a bal.tab: SMD x 100, VR and KS unscaled", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 6))
  cb <- hv_balance(bt, stats = c("smd", "variance_ratio", "ks"))
  b  <- bt$Balance
  smd_after <- cb$data[cb$data$stat == "smd" & cb$data$group == "After", ]
  expect_equal(smd_after$std_diff, b$Diff.Adj * 100)
  ks_before <- cb$data[cb$data$stat == "ks" & cb$data$group == "Before", ]
  expect_equal(ks_before$std_diff, b$KS.Un)
  expect_equal(cb$meta$group_col, "group")
  expect_setequal(unique(cb$data$group), c("Before", "After"))
})

test_that("hv_balance drops undefined variance ratios for binary covariates", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 6))
  cb <- expect_no_warning(hv_balance(bt, stats = c("smd", "variance_ratio")))
  vr <- cb$data[cb$data$stat == "variance_ratio", ]
  expect_setequal(unique(vr$variable), rownames(bt$Balance)[bt$Balance$Type != "Binary"])
  expect_equal(cb$meta$n_missing, 0L)
})

test_that("hv_balance applies group_labels to bal.tab input", {
  skip_if_not_installed("cobalt")
  cb <- hv_balance(balance_baltab(balance_cohort(n_terms = 4)),
                   group_labels = c("Unweighted", "Weighted"))
  expect_setequal(unique(cb$data$group), c("Unweighted", "Weighted"))
})

test_that("hv_balance refuses raw binary differences from bal.tab", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 4), binary = "raw")
  expect_error(hv_balance(bt), 'binary = "std"')
})

test_that("hv_balance names the missing stat when bal.tab lacks it", {
  skip_if_not_installed("cobalt")
  d  <- balance_cohort(n_terms = 4)
  bt <- cobalt::bal.tab(d[setdiff(names(d), "treat")], treat = d$treat,
                        binary = "std", s.d.denom = "pooled")
  expect_error(hv_balance(bt, stats = c("smd", "ks")), 'stats = c\\("m", "v", "ks"\\)')
})

test_that("hv_balance facets a three-group bal.tab.multi by pair", {
  skip_if_not_installed("cobalt")
  bm <- balance_baltab_multi()
  cb <- hv_balance(bm)
  expect_equal(cb$meta$pairs, names(bm$Pair.Balance))
  p <- plot(cb)
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$layout$layout), 3L)
  expect_plot_has_data(p)
  pts <- built$data[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))]]
  expect_setequal(unique(as.integer(pts$PANEL)), 1:3)
})

test_that("the KS panel shows what exact mean balance hides", {
  skip_if_not_installed("cobalt")
  cb <- hv_balance(balance_exact_mean(), stats = c("smd", "ks"))
  smd <- cb$data[cb$data$stat == "smd", "std_diff"]
  ks  <- cb$data[cb$data$stat == "ks" & cb$data$variable == "year", "std_diff"]
  expect_true(all(abs(smd) < 1e-6))
  expect_gt(ks, 0.2)
  p <- plot(cb)
  expect_plot_has_data(p)
  built <- ggplot2::ggplot_build(p)
  pts <- built$data[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))]]
  expect_gt(max(pts$x[pts$PANEL == 2]), 0.2)
  expect_lt(max(abs(pts$x[pts$PANEL == 1])), 1e-6)
})
```

- [ ] **Step 4: Run to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: FAIL with the existing `"data.frame"` error from `.check_df()` (the adapter is not wired).

- [ ] **Step 5: Implement `R/covariate-balance-input.R`**

```r
###############################################################################
## Input adapters for hv_balance(): turn a cobalt::bal.tab() result, an
## hvtiRpropensity ps_* object, or a list of either (one per imputation) into
## the long data frame hv_balance() plots. Structure is read directly; no
## cobalt or hvtiRpropensity functions are called.
###############################################################################

# bal.tab column stem for each stat, and the stats = argument that requests it.
.cb_baltab_cols <- c(smd = "Diff", variance_ratio = "V.Ratio", ks = "KS")
.cb_baltab_flag <- c(smd = "m", variance_ratio = "v", ks = "ks")

.cb_from_baltab <- function(x, stats, group_labels) {
  if (!identical(attr(x, "print.options")$binary, "std"))
    stop(paste(
      "`bal.tab()` reported raw differences for binary covariates, which cannot",
      "share an axis with standardized differences. Re-run `bal.tab()` with",
      "binary = \"std\"."), call. = FALSE)

  if (inherits(x, "bal.tab.multi")) {
    parts <- lapply(names(x$Pair.Balance), function(nm) {
      el <- x$Pair.Balance[[nm]]
      attr(el, "print.options") <- attr(x, "print.options")
      d <- .cb_from_baltab(el, stats, group_labels)
      d$pair <- nm
      d
    })
    return(do.call(rbind, parts))
  }

  bal <- x$Balance
  if (!is.data.frame(bal))
    stop(paste(
      "This `bal.tab` variant has no `$Balance` table. For multiply imputed",
      "data, pass a list of per-imputation `bal.tab()` results."), call. = FALSE)

  groups <- c(Un = group_labels[1], Adj = group_labels[2])
  out <- list()
  for (s in stats) {
    for (sfx in names(groups)) {
      cn <- paste0(.cb_baltab_cols[[s]], ".", sfx)
      if (!cn %in% names(bal) || all(is.na(bal[[cn]]))) next
      # The variance ratio is undefined for binary covariates, not missing.
      keep <- if (s == "variance_ratio") bal$Type != "Binary" else rep(TRUE, nrow(bal))
      out[[length(out) + 1L]] <- data.frame(
        variable = rownames(bal)[keep],
        group    = groups[[sfx]],
        stat     = s,
        pair     = NA_character_,
        std_diff = bal[[cn]][keep] * if (s == "smd") 100 else 1,
        stringsAsFactors = FALSE
      )
    }
    if (!any(vapply(out, function(d) identical(d$stat[1], s), logical(1))))
      stop(sprintf(paste(
        "The `bal.tab()` result carries no %s. Re-run it with",
        "stats = c(\"m\", \"v\", \"ks\") (needs \"%s\")."),
        cb_stat_labels[[s]], .cb_baltab_flag[[s]]), call. = FALSE)
  }
  do.call(rbind, out)
}

.cb_is_source <- function(x) inherits(x, "bal.tab") || inherits(x, "ps_data")

.cb_one <- function(x, stats, group_labels) {
  .cb_from_baltab(x, stats, group_labels)
}

# NULL when `x` is not an adapter input, so the data-frame path (and its
# existing error messages) handles it unchanged.
.cb_as_long <- function(x, stats, group_labels) {
  if (.cb_is_source(x))
    return(list(data = .cb_one(x, stats, group_labels), n_imputations = 1L))
  NULL
}
```

In `hv_balance()` replace `long <- NULL` with `long <- .cb_as_long(data, stats, group_labels)`.

Add a roxygen paragraph to `hv_balance()`'s `@description` (markdown) and a sentence to `@param data`:
`data` may also be a `cobalt::bal.tab()` result built with `binary = "std"`, a multi-category
`bal.tab` (one facet row per pair), an hvtiRpropensity `ps_match()` / `ps_weight()` object, or a list of
any one of those, one per imputation, averaged. In those cases the SMD is multiplied by 100 and the
`*_col` arguments are ignored. Add a `\donttest{}`-free example guarded by
`if (requireNamespace("cobalt", quietly = TRUE)) { ... }` that builds a `bal.tab` on `cobalt::lalonde`
with `binary = "std", stats = c("m", "v", "ks")` and plots `stats = c("smd", "variance_ratio", "ks")`.

- [ ] **Step 6: Run the tests**

Run: `Rscript -e 'devtools::document()' && Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add R/covariate-balance-input.R R/covariate-balance.R DESCRIPTION tests/testthat/helper-balance-fixtures.R tests/testthat/test_covariate_balance.R man/hv_balance.Rd
git commit -m "feat: hv_balance() reads cobalt bal.tab and bal.tab.multi results (#219)"
```

---

### Task 5: `ps_match` / `ps_weight` adapter

**Files:**
- Modify: `R/covariate-balance-input.R`
- Test: `tests/testthat/test_covariate_balance.R` (append)

**Interfaces:**
- Consumes: `.cb_one()`, `.cb_as_long()` (Task 4).
- Produces: `.cb_from_ps(x, stats, group_labels)` with the same output columns as `.cb_from_baltab()`.

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---------------------------------------------------------------------------
# hv_balance: hvtiRpropensity ps_* input
# ---------------------------------------------------------------------------

ps_cov <- c("age", "female", "ef", "diabetes", "hypertension")

test_that("hv_balance reads ps_match SMDs x 100 as Before / After", {
  skip_if_not_installed("hvtiRpropensity")
  m  <- hvtiRpropensity::ps_match(hvtiRpropensity::sample_ps_data(),
                                  covariates = ps_cov, caliper = 0.05, seed = 1)
  cb <- hv_balance(m)
  after <- cb$data[cb$data$group == "After", ]
  expect_equal(after$std_diff, m$tables$smd_after$smd * 100)
  expect_equal(after$variable, as.character(m$tables$smd_after$variable))
  expect_plot_has_data(plot(cb), min_groups = 2)
})

test_that("hv_balance reads ps_weight unweighted / weighted SMDs", {
  skip_if_not_installed("hvtiRpropensity")
  w  <- hvtiRpropensity::ps_weight(hvtiRpropensity::sample_ps_data(), covariates = ps_cov)
  cb <- hv_balance(w)
  before <- cb$data[cb$data$group == "Before", ]
  expect_equal(before$std_diff, w$tables$smd_unweighted$smd * 100)
})

test_that("hv_balance points ps_* callers to bal.tab for VR and KS", {
  skip_if_not_installed("hvtiRpropensity")
  w <- hvtiRpropensity::ps_weight(hvtiRpropensity::sample_ps_data(), covariates = ps_cov)
  expect_error(hv_balance(w, stats = c("smd", "ks")), "bal.tab")
})
```

- [ ] **Step 2: Run to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: FAIL; a `ps_data` object reaches `.cb_from_baltab()` and errors on the binary check.

- [ ] **Step 3: Implement** (in `R/covariate-balance-input.R`)

Add above `.cb_is_source()`:

```r
# SMD tables written by ps_match() and ps_weight(): before/after pairs.
.cb_ps_tables <- list(c("smd_before", "smd_after"), c("smd_unweighted", "smd_weighted"))

.cb_from_ps <- function(x, stats, group_labels) {
  extra <- setdiff(stats, "smd")
  if (length(extra))
    stop(sprintf(paste(
      "A `%s` object carries standardized differences only, not %s. Build the",
      "balance table with cobalt::bal.tab(..., binary = \"std\",",
      "stats = c(\"m\", \"v\", \"ks\")) and pass that instead."),
      class(x)[1], paste(cb_stat_labels[extra], collapse = " or ")), call. = FALSE)

  hit <- Filter(function(nm) all(nm %in% names(x$tables)), .cb_ps_tables)
  if (!length(hit))
    stop(sprintf(paste(
      "The `%s` object has no SMD tables (expected smd_before/smd_after or",
      "smd_unweighted/smd_weighted in `$tables`)."), class(x)[1]), call. = FALSE)

  nm <- hit[[1]]
  do.call(rbind, lapply(1:2, function(i) {
    t <- x$tables[[nm[i]]]
    data.frame(
      variable = as.character(t$variable),
      group    = group_labels[i],
      stat     = "smd",
      pair     = NA_character_,
      std_diff = t$smd * 100,
      stringsAsFactors = FALSE
    )
  }))
}
```

Replace `.cb_one()` with:

```r
.cb_one <- function(x, stats, group_labels) {
  if (inherits(x, "bal.tab")) .cb_from_baltab(x, stats, group_labels)
  else .cb_from_ps(x, stats, group_labels)
}
```

- [ ] **Step 4: Run the tests**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/covariate-balance-input.R tests/testthat/test_covariate_balance.R
git commit -m "feat: hv_balance() reads hvtiRpropensity ps_match and ps_weight SMDs (#219)"
```

---

### Task 6: Imputation lists and pooling

**Files:**
- Modify: `R/covariate-balance-input.R`
- Test: `tests/testthat/test_covariate_balance.R` (append)

**Interfaces:**
- Consumes: `.cb_one()`, `.cb_is_source()` (Tasks 4-5), fixtures `balance_cohort()`, `balance_baltab()`.
- Produces: `.cb_pool(parts)` returning the first part's rows with `std_diff` replaced by the signed
  mean across parts; `.cb_as_long()` returning `n_imputations = length(x)` for lists.

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---------------------------------------------------------------------------
# hv_balance: imputation lists
# ---------------------------------------------------------------------------

test_that("hv_balance averages 5 imputations of a 38-term bal.tab", {
  skip_if_not_installed("cobalt")
  imps <- lapply(1:5, function(i) balance_baltab(balance_cohort(n_terms = 38, seed = i)))
  cb   <- hv_balance(imps)
  expect_equal(cb$meta$n_imputations, 5L)
  expect_equal(cb$meta$n_vars, 38L)
  hand <- rowMeans(sapply(imps, function(b) b$Balance$Diff.Adj)) * 100
  after <- cb$data[cb$data$group == "After", ]
  expect_equal(after$std_diff, unname(hand))
  expect_equal(round(cb$meta$suggested_height, 2), 7.96)
  expect_output(print(cb), "Imputations : 5")
})

test_that("hv_balance averages a list of ps_match objects", {
  skip_if_not_installed("hvtiRpropensity")
  d <- hvtiRpropensity::sample_ps_data()
  imps <- lapply(1:3, function(i) hvtiRpropensity::ps_match(
    d, covariates = c("age", "female", "ef"), caliper = 0.05, seed = i))
  cb <- hv_balance(imps)
  hand <- rowMeans(sapply(imps, function(m) m$tables$smd_after$smd)) * 100
  expect_equal(cb$data[cb$data$group == "After", "std_diff"], unname(hand))
})

test_that("hv_balance rejects an imputation list mixing classes", {
  skip_if_not_installed("cobalt")
  skip_if_not_installed("hvtiRpropensity")
  bt <- balance_baltab(balance_cohort(n_terms = 4))
  w  <- hvtiRpropensity::ps_weight(hvtiRpropensity::sample_ps_data(), covariates = "age")
  expect_error(hv_balance(list(bt, w)), "same kind")
})

test_that("hv_balance rejects imputations with different covariates", {
  skip_if_not_installed("cobalt")
  a <- balance_baltab(balance_cohort(n_terms = 4))
  b <- balance_baltab(balance_cohort(n_terms = 6))
  expect_error(hv_balance(list(a, b)), "differ")
})

test_that("hv_balance rejects an empty list and a partly-adapter list", {
  skip_if_not_installed("cobalt")
  expect_error(hv_balance(list()), "empty")
  bt <- balance_baltab(balance_cohort(n_terms = 4))
  expect_error(hv_balance(list(bt, data.frame())), "every element")
})
```

- [ ] **Step 2: Run to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: FAIL; lists fall through to `.check_df()` and error with "data.frame".

- [ ] **Step 3: Implement** (in `R/covariate-balance-input.R`)

Add above `.cb_as_long()`:

```r
# Signed mean of each covariate x group x stat x pair across imputations.
# Every imputation must carry the same rows; the first fixes the order.
.cb_pool <- function(parts) {
  key  <- function(d) paste(d$variable, d$group, d$stat, d$pair, sep = "\r")
  ref  <- sort(key(parts[[1]]))
  same <- vapply(parts, function(d) identical(sort(key(d)), ref), logical(1))
  if (!all(same))
    stop(sprintf(paste(
      "Imputation(s) %s differ from the first in their covariates, groups or",
      "statistics; every imputation must have the same balance table rows."),
      paste(which(!same), collapse = ", ")), call. = FALSE)

  all   <- do.call(rbind, parts)
  means <- tapply(all$std_diff, key(all), mean)
  out   <- parts[[1]]
  out$std_diff <- unname(means[key(out)])
  out
}
```

Replace `.cb_as_long()` with:

```r
# NULL when `x` is not an adapter input, so the data-frame path (and its
# existing error messages) handles it unchanged. A plain list such as
# list(variable = "x") is not an adapter input.
.cb_as_long <- function(x, stats, group_labels) {
  if (.cb_is_source(x))
    return(list(data = .cb_one(x, stats, group_labels), n_imputations = 1L))
  if (!is.list(x) || is.data.frame(x)) return(NULL)
  if (!length(x))
    stop("`data` is an empty list; pass one balance object per imputation.", call. = FALSE)

  is_src <- vapply(x, .cb_is_source, logical(1))
  if (!any(is_src)) return(NULL)
  if (!all(is_src))
    stop(paste(
      "When `data` is a list, every element must be a `bal.tab` or `ps_*`",
      "object (one per imputation)."), call. = FALSE)
  kinds <- unique(vapply(x, function(o) class(o)[1], character(1)))
  if (length(kinds) > 1L)
    stop(sprintf("Imputations must all be the same kind of object; got %s.",
                 paste(kinds, collapse = ", ")), call. = FALSE)

  parts <- lapply(x, .cb_one, stats = stats, group_labels = group_labels)
  list(data = .cb_pool(parts), n_imputations = length(x))
}
```

Note the existing test `hv_balance(list(variable = "x", group = "y", std_diff = 1))`: no element is a
source, so `.cb_as_long()` returns `NULL` and `.check_df()` raises its `"data.frame"` error as before.

- [ ] **Step 4: Run the tests**

Run: `Rscript -e 'devtools::test(filter = "covariate_balance")'`
Expected: PASS, including the pre-existing `"data.frame"` error test.

- [ ] **Step 5: Commit**

```bash
git add R/covariate-balance-input.R tests/testthat/test_covariate_balance.R
git commit -m "feat: hv_balance() averages a list of per-imputation balance objects (#219)"
```

---

### Task 7: Gates, news and PR

**Files:**
- Create: `news/feat-balance-panels.md`
- Modify: `man/`, `NAMESPACE` (regenerated)

- [ ] **Step 1: News fragment** (`news/feat-balance-panels.md`; bullets only, no heading)

```markdown
* `hv_balance()` now takes a `cobalt::bal.tab()` result (built with
  `binary = "std"`), a multi-category `bal.tab` (one facet row per pairwise
  comparison), an hvtiRpropensity `ps_match()` or `ps_weight()` object, or a
  list of any one of those, one per imputation, averaged. It multiplies SMDs
  by 100 itself (#219).
* `hv_balance(stats = c("smd", "variance_ratio", "ks"))` draws variance-ratio
  and KS panels beside the SMD panel, so distributional imbalance that exact
  mean balance hides is visible. Data frames select panels with `stat_col`
  and facet by comparison with `pair_col` (#219).
* New `hv_balance_height()` suggests a figure height for the number of
  covariate rows; `hv_balance()` stores it in `$meta$suggested_height` (#219).
```

- [ ] **Step 2: Regenerate docs and run the full suite**

Run: `Rscript -e 'devtools::document()' && Rscript -e 'devtools::test()'`
Expected: 0 failures. Report the pass/skip counts verbatim.

- [ ] **Step 3: Lint**

Run: `Rscript -e 'devtools::install(quick = TRUE, upgrade = "never"); print(lintr::lint_package())'`
Expected: no lints. (Reinstall first: `object_usage_linter` reads the installed namespace and reports
phantom lints on new internal helpers otherwise. Never `nolint` those.)

- [ ] **Step 4: Manual build** (`check-manual.yaml` does not run on PRs)

Run: `R CMD Rd2pdf --no-preview --force --output=/tmp/manual.pdf .`
Expected: exits 0. `pdfTeX warning (dest)` lines are known noise.

- [ ] **Step 5: Full check from a clean export**

```bash
rm -rf /tmp/hvbal && mkdir /tmp/hvbal && git archive HEAD | tar -x -C /tmp/hvbal
cd /tmp/hvbal && R CMD build . && LC_ALL=en_US.UTF-8 R CMD check --no-manual hvtiPlotR_*.tar.gz
```

Expected: `Status: OK` (0 errors, 0 warnings, 0 notes). Commit everything first so `git archive HEAD`
includes it.

- [ ] **Step 6: pkgdown reference check**

Run: `Rscript -e 'pkgdown::check_pkgdown()'`
Expected: no missing topics (`hv_balance_height` was added in Task 1).

- [ ] **Step 7: Commit, push, PR**

```bash
git add news/feat-balance-panels.md man NAMESPACE
git commit -m "docs: news fragment and regenerated docs for hv_balance panels (#219)"
git push -u origin feat/balance-panels
gh pr create --title "hv_balance(): bal.tab/ps_* input, pair facets, VR and KS panels, height helper" --body "Closes #219. ..."
```

The PR body lists: the four gaps and what closes each; the spec's two corrections to the issue
(`ps_*` tables are `smd_before`/`smd_after` and `smd_unweighted`/`smd_weighted`, SMD only; `bal.tab`
binary differences must be `"std"`); the reference-line layer change (three `vline` layers to two);
the gate results from Steps 2-6. End with the attribution line. Then address and resolve the Copilot
review threads before handing over.
