# Changelog

## hvtiPlotR 2.0.0

First stable release of the `hv_*` API. This consolidates the
`2.0.0.9001`–`2.0.0.9013` dev cycle into a tagged release that internal
users can anchor against for bug reports and reproducibility. Future
development continues under `2.0.1.9xxx`.

### New features — fixed-panel geometry

The dominant theme of this release is making the **panel content area**
(the rectangular data region, excluding axes/titles/legend/margins) a
first-class target, so figures stay visually aligned across output
devices and across slides in a deck even when axis-label widths differ.

- `hv_ggsave_dims(plot, width, height, units = "in")`: compute
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  `width`/`height` that preserve a fixed panel content area regardless
  of axis labels, legend, title, or facet strips. Returns a named list
  shaped to splat into
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) via
  `do.call(ggsave, c(list(filename = ..., plot = p), dims))`. Units are
  length-only (`"in"`, `"cm"`, `"mm"`) since the sizing device is PDF.
- `hv_ph_location(plot, panel_width, panel_height, panel_left, panel_top, units = "in")`:
  compute
  [`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html)
  `width`/`height`/`left`/`top` values that anchor a ggplot’s panel to a
  fixed rectangle on a slide, regardless of axis-label width. Measures
  asymmetric chrome (left/right/top/bottom of the panel) via
  [`ggplotGrob()`](https://ggplot2.tidyverse.org/reference/ggplotGrob.html)
  and returns per-plot placement so the panel lands at the same slide
  coordinates on every slide. Warns if plot chrome extends past the left
  or top slide edge.
- `save_ppt(..., panel_box = list(width, height, left, top))`: new
  optional argument. When supplied, per-slide placement is computed via
  [`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)
  so every slide anchors the panel at the given rectangle — solving the
  “plot background box moves between slides” problem on dark PPT themes
  where the panel is visibly filled. When `panel_box = NULL` (default),
  the fixed `width`/`height`/`left`/`top` arguments are used (legacy
  behavior).

### New features — PPT theme polish

- `hv_theme_dark_ppt(bold = TRUE)` and
  `hv_theme_light_ppt(bold = TRUE)`: apply `face = "bold"` to axis text
  and axis titles.

### Behaviour changes — PPT themes

- [`hv_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md)
  and
  [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_light_ppt.md):
  - Legend is now hidden by default (`legend.position = "none"`).
    PowerPoint figures are typically annotated directly on the panel;
    override with `+ theme(legend.position = "right")` when needed.
  - Axis ticks now face **inside** the panel
    (`axis.ticks.length = -half_line/2 pt`) for the AATS-style inset
    look.
  - Axis-text and axis-title margins are now scaled from `base_size` via
    ggplot2’s `half_line = base_size / 2` convention, so spacing stays
    proportional when `base_size` changes. Previous unscaled defaults
    produced cramped labels at `base_size = 32`.
  - [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_light_ppt.md)
    gains explicit `axis.text`, `axis.line`, `panel.background` (fill
    `"white"`, colour `"black"`, linewidth 1), and `axis.ticks` elements
    so the light theme structurally mirrors the dark theme’s
    explicit-chrome approach (just with inverted colours).

### Build / infrastructure

- `.Rbuildignore` is now tracked in git (previously `.gitignored`).
  Three latent regex bugs fixed: anchored `.gitignore` pattern, stripped
  inline `# ...` comments from five patterns (which had silently never
  matched), and fixed `^vignettes/*_files$` → `^vignettes/.*_files$` so
  `_files/` output dirs actually get excluded from the build.
- `vignettes/_quarto.yml` now tracked with `embed-resources: false` at
  the project level, making the small-HTML / separate `_files/`
  rendering behaviour explicit and preventing accidental repo bloat.

### Dependency trim (from the merged `trends_plots` branch)

- Dropped `RColorBrewer` (inline Set1 hex in `cluster_sankey_plot()` and
  vignettes) and `gridExtra` (`marrangeGrob()` →
  [`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
  in the EDA multi-panel PDF pattern) from Suggests.
- Dropped `assertthat` from Imports
  ([`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  now uses base [`stop()`](https://rdrr.io/r/base/stop.html) with
  `call. = FALSE`).
- `vignettes/hvtiPlotR.qmd` now documents
  [`haven::read_xpt()`](https://haven.tidyverse.org/reference/read_xpt.html)
  (and
  [`haven::read_sas()`](https://haven.tidyverse.org/reference/read_sas.html))
  for importing SAS data, with a CSV-fallback path for users without SAS
  access.

## hvtiPlotR 2.0.0.9010

### Bug fixes

- `plot-functions.qmd`: UpSet plot chunks (`upset_data`, `upset_basic`,
  `upset_fill`, `upset_era`) now skip on Windows
  (`eval: !expr .Platform$OS.type != "windows"`). ComplexUpset’s
  patchwork rendering crashes the Rscript subprocess on the Windows CI
  runner (os error 232 / “pipe being closed”), so the examples are shown
  only on macOS and Linux where they render reliably.

## hvtiPlotR 2.0.0.9009

### Documentation

- `plot-functions.qmd`: updated both mirror-histogram decorated examples
  to follow standard ggplot2 mirror-plot conventions:
  - Added `scale_y_continuous(labels = abs)` so the y-axis displays
    absolute counts on both halves of the panel.
  - Replaced hard-coded y-coordinates in
    [`annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html)
    calls with `y = Inf`/`y = -Inf` plus `vjust`, anchoring each group
    label near the top/bottom panel edge regardless of dataset size.
  - Replaced hard-coded label strings (`"SAVR"`, `"TF-TAVR"`, etc.) with
    `mh$meta$group_labels[1]` / `[2]`, so the annotations always track
    the labels supplied to the constructor.

## hvtiPlotR 2.0.0.9008

### Documentation

- Vignettes: all `hv_theme("manuscript")` calls inside R code blocks
  replaced with `hv_theme("poster")` to demonstrate non-default theme
  options. Prose references (e.g. migration guide comparison table) are
  preserved unchanged. Theme-specific sections in `plot-decorators.qmd`
  (`## Manuscript`, `## Manuscript PDF`) continue to demonstrate
  `hv_theme("manuscript")`.
- `plot-functions.qmd`: added explicit **Bare plot** subsections to the
  six sections that previously chained directly from build to decoration
  — mirror-histogram (binary-match and IPTW), trends (cases/year),
  spaghetti, nonparametric temporal curve, nonparametric ordinal curve,
  and longitudinal participation counts. Each section now follows the
  three-step pattern:
  1.  build with `hv_*()`, (2) render bare ggplot with `p <- plot(obj)`,
  2.  decorate with `scale_*()` + `hv_theme("poster")`.
- `plot-functions.qmd`: UpSet section split into `## Bare plot` (showing
  `plot(hu)`) and `## Applying a theme` (showing
  `plot(hu) & hv_theme("poster")`), with an explanatory note that the
  patchwork `&` operator is required.

## hvtiPlotR 2.0.0.9007

### Breaking changes

- All exported functions, S3 methods, and class names have been renamed
  from the `hvti_` prefix to the shorter `hv_` prefix. No
  backward-compatible aliases are provided. Update all call sites:
  - `hvti_survival()` →
    [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)
  - `hvti_trends()` →
    [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md)
  - `hvti_mirror_hist()` →
    [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  - `hvti_spaghetti()` →
    [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md)
  - `hvti_balance()` →
    [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md)
  - `hvti_alluvial()` →
    [`hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md)
  - `hvti_sankey()` →
    [`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md)
  - `hvti_nonparametric()` →
    [`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md)
  - `hvti_ordinal()` →
    [`hv_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md)
  - `hvti_followup()` →
    [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
  - `hvti_longitudinal()` →
    [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md)
  - `hvti_stacked()` →
    [`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md)
  - `hvti_eda()` →
    [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md)
  - `hvti_hazard()` →
    [`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
  - `hvti_nnt()` →
    [`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md)
  - `hvti_upset()` →
    [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md)
  - `hvti_theme()` →
    [`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)
  - `hvti_survival_difference()` →
    [`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md)
  - `is_hvti_data()` →
    [`is_hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/is_hv_data.md)
  - Class strings `"hvti_*"` → `"hv_*"` (affects
    [`inherits()`](https://rdrr.io/r/base/class.html) checks)
  - The package name (`hvtiPlotR`) is unchanged.

## hvtiPlotR 2.0.0.9006

### Documentation

- [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  `$tables$diagnostics`: corrected return documentation from “a data
  frame of matched/unmatched counts per group” to accurately describe
  the actual type — a named list of diagnostic summaries whose contents
  vary by mode (binary-match vs weighted IPTW). All keys are now
  enumerated in the `@return` block.
- `$meta` keys in
  [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  return docs updated to include all keys actually stored (`score_col`,
  `group_col`, `match_col` were missing).
- Added `@family Propensity Score & Matching` to
  [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  and
  [`plot.hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_mirror_hist.md),
  creating automatic bi-directional “See also” cross-links consistent
  with all other `hv_*` constructor/plot pairs.
- [`plot.hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_mirror_hist.md)
  `@return` now describes composability with `+` (scales, limits,
  labels, `hv_theme`), matching the pattern used in all other updated
  plot methods.
- [`plot.hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_mirror_hist.md)
  `@seealso` expanded with descriptive text for each linked function,
  matching the richer pattern used elsewhere.

## hvtiPlotR 2.0.0.9005

### Tests

- Added `test_trends_plot.R` (37 tests): `$meta` slot keys and values,
  `$tables$summary` structure and row counts, factor level order
  preservation, `print.hv_trends` output and invisible return, and full
  parameter coverage for `plot.hv_trends` (`se`, `span`, `point_size`,
  `point_shape`, `alpha`, `smoother`, grouped vs ungrouped mapping,
  composability with `hv_theme`).
- Added `test_spaghetti_plot.R` (25 tests): `$meta` slot keys and
  values, `id_col`/`y_col` absent error cases, `print.hv_spaghetti`
  output with and without `colour_col` branch and invisible return, and
  full parameter coverage for `plot.hv_spaghetti` (`add_smooth`,
  `smooth_se`, `line_colour`, `line_width`, `alpha` boundaries,
  `y_labels` error cases, `smooth_method`, grouped vs ungrouped mapping,
  composability with `hv_theme`).
- Added `test_hv_data.R` (27 tests):
  [`new_hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/new_hv_data.md)
  structure contract, input validation errors,
  [`is_hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/is_hv_data.md)
  TRUE/FALSE for all relevant types, `print.hv_data` base-class output
  and invisible return, subclass dispatch (verifying
  `print.hv_spaghetti` overrides `print.hv_data`), and `plot.hv_data`
  fallback error with subclass name in message.

## hvtiPlotR 2.0.0.9004

### Breaking changes

- `hv_mirror()` renamed to
  [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  for naming consistency with the underlying plot type. The old name is
  registered as an `@aliases` entry so `?hv_mirror` still resolves to
  the correct help page.

### New features

- [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  is now searchable via `?mirror_histogram`, `?hv_mirror`,
  `??propensity`, `??IPTW`, and `??matching` through `@aliases` and
  `@concept` tags in its documentation.

### Documentation

- All `hv_*` constructors and `plot.hv_*` methods now carry `@family`
  tags, creating automatic bi-directional “See also” cross-links between
  each constructor and its plot method in the help system and pkgdown
  reference.
- `@return` on every constructor now explicitly says “call
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) to render”
  and links to the corresponding `plot.hv_*` method.
- `@seealso` entries across all constructors and plot methods now
  include descriptive text explaining the role of each linked function.
- `@examples` in all main plot methods include a `\dontrun{}` block
  demonstrating `ggplot2::theme_set(hv_theme_manuscript())` for applying
  the publication theme globally,
  [`scale_colour_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html)
  /
  [`scale_fill_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html)
  for multi-group colour palettes, and a pointer to
  [`vignette("plot-decorators", package = "hvtiPlotR")`](https://ehrlinger.github.io/hvtiPlotR/articles/plot-decorators.md).

## hvtiPlotR 2.0.0.9001

## hvtiPlotR 2.0.0

### Breaking changes — new S3 constructor API

All plot functions have been replaced by a two-step S3 workflow:

``` r
# Step 1: construct & validate
obj <- hv_*(data, ...)          # returns c("hv_<concept>", "hv_data")

# Step 2: render
plot(obj, ...) +                  # bare ggplot — no scales, labels, or theme
  scale_colour_manual(...) +
  labs(...) +
  hv_theme("manuscript")
```

The old single-call functions (`mirror_histogram()`, `survival_curve()`,
etc.) are **removed**. This is a clean break; no deprecated wrappers.

#### Constructor → old function mapping

| New constructor                                                                             | Removed function(s)                                          |
|---------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)     | `mirror_histogram()`                                         |
| [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md)             | `covariate_balance()`                                        |
| [`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md)             | `stacked_histogram()`                                        |
| [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)           | `survival_curve()`                                           |
| [`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md) | `nonparametric_curve_plot()`                                 |
| [`hv_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md)             | `nonparametric_ordinal_plot()`                               |
| [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)           | `goodness_followup()` + `goodness_event_plot()`              |
| [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md)               | `trends_plot()`                                              |
| [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md)         | `spaghetti_plot()`                                           |
| [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md)   | `longitudinal_counts_plot()` + `longitudinal_counts_table()` |
| [`hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md)           | `alluvial_plot()`                                            |
| [`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md)               | `cluster_sankey_plot()`                                      |
| [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md)                     | `eda_plot()`                                                 |
| [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md)                 | `upset_plot()`                                               |

[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
\|
[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)
\|  
[`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md)
\|
[`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md)
\|  
[`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md)
\|
[`nnt_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nnt_plot.md)
\|

The legacy hazard helpers
([`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md),
[`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md),
[`nnt_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nnt_plot.md))
remain exported but are marked **Superseded** — use the S3 constructors
above instead.

#### Multi-type constructors

Two constructors replace *pairs* of old functions via a `type =`
argument on [`plot()`](https://rdrr.io/r/graphics/plot.default.html):

- `hv_longitudinal` — `plot(x, type = "plot")` (bar chart, was
  `longitudinal_counts_plot()`) or `plot(x, type = "table")` (text
  panel, was `longitudinal_counts_table()`).
- `hv_followup` — `plot(x, type = "followup")` (death panel, was
  `goodness_followup()`) or `plot(x, type = "event")` (non-fatal event
  panel, was `goodness_event_plot()`).

### New base class

- Added `hv_data` S3 base class (`R/hvti-data.R`). Every `hv_*`
  constructor returns `list(data=, meta=, tables=)` with class
  `c("hv_<concept>", "hv_data")`.
- [`new_hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/new_hv_data.md)
  — internal constructor; validates `data` (data.frame), `meta` (named
  list), `tables` (list), `subclass` (character).
- [`print.hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_data.md)
  — fallback print method; shows class, dimensions, and slot names.
- [`plot.hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_data.md)
  — fallback plot method; stops with a helpful message if no concrete
  `plot.hv_*()` is registered.
- [`is_hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/is_hv_data.md)
  — exported predicate.

### Documentation

- Rewrote `help.R` package-level documentation to describe the new
  two-step constructor +
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) workflow and
  list all `hv_*()` constructors.
- Updated `_pkgdown.yml` reference index: grouped by constructor family,
  with `plot.*` and `print.*` S3 methods explicitly listed.
- Updated all vignettes (`plot-functions.qmd`,
  `sas-migration-guide.qmd`, `plot-decorators.qmd`) to use the new API
  throughout.
- Updated `sas-migration-guide.qmd` key-concepts section and template
  reference table.
- Fixed all stale `@seealso` cross-references and orphaned old-API
  docblocks in every migrated R source file.

### Tests

- Added `tests/testthat/test_hazard_plot.R` — full validation suite for
  `sample_hazard_data`, `sample_hazard_empirical`, `sample_life_table`,
  `hv_hazard`, `hv_survival_difference`, and `hv_nnt` (column checks, CI
  bounds, layer structure, multi-group, non-default column names, input
  validation, print output, empirical/reference validation).
- Added `tests/testthat/test_nonparametric_plots.R` — full suite for
  `sample_nonparametric_curve_data`,
  `sample_nonparametric_curve_points`, `nonparametric_curve_plot`,
  `sample_nonparametric_ordinal_data`,
  `sample_nonparametric_ordinal_points`, and
  `nonparametric_ordinal_plot`. Includes probability-sum-to-1 invariant
  test for ordinal grades.
- Added `tests/testthat/test_survival_derived.R` — full suite for
  `sample_survival_difference_data`, `sample_nnt_data`, and legacy
  `survival_difference_plot` / `nnt_plot`. Covers NA-NNT at t≈0 edge
  case and cross-function time-grid consistency.
- Added `tests/testthat/test_cluster_sankey.R` — full suite for
  `sample_cluster_sankey_data` and `cluster_sankey_plot`. Validates the
  hierarchical merge tree (C9=A → C2=A) and that each Ck has exactly k
  levels.
- Added `tests/testthat/test_pipeline.R` — end-to-end pipeline tests
  covering `survival_curve → hv_theme → save_ppt`, multi-slide list
  pipelines, built-in dataset usability, `eda_classify_var` edge cases
  (logical vector, all-NA, length-1), and composed multi-layer plots.
- Added snapshot test to `test_kaplan_meier.R` for `survival_curve`
  `report_table` at fixed seed; added all-censored and
  single-observation edge-case tests.
- Added snapshot test to `test_mirror_histogram.R` for diagnostics at
  fixed seed.
- Added `slide_titles` length-mismatch test to `test_save_ppt.R`.
- Added `make_footnote` prefix-parameter tests to `test_footnote.R`.

### Documentation

- Fixed
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  argument names throughout all vignettes: `plot =` → `object =`,
  `filename =` → `powerpoint =`. Also added correct `template =` and
  `slide_titles =` arguments where missing.
- Fixed critical roxygen bug in
  [`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md):
  doc block used `##'` (silently ignored by roxygen2) instead of `#'`,
  so the function had no generated `.Rd` file. Converted all `##'` →
  `#'`, modernised `\code{}` → backtick syntax, and added `@examples`.
- Added `@examples` to all five theme functions:
  [`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md),
  [`hv_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_manuscript.md),
  [`hv_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md),
  [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_light_ppt.md),
  and
  [`hv_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_poster.md).
- Expanded thin (2-line) `@examples` blocks for four sample-data
  helpers:
  [`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md),
  [`sample_nonparametric_curve_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_points.md),
  [`sample_nonparametric_ordinal_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_points.md),
  and
  [`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md).
- Fixed `km$survival_plot` and `km$risk_table` accessor patterns in
  `vignettes/plot-decorators.qmd`: `survival_curve()` returns a ggplot
  with *attributes*, not a named list. Replaced with `km` (the returned
  object IS the survival plot) and `attr(km, "risk_table")`.
- Fixed patchwork operator-precedence bug in
  `vignettes/plot-decorators.qmd`: `p_ms | p_km_ms + plot_layout(...)` →
  `(p_ms | p_km_ms) + plot_layout(...)`.
- Added `patchwork` to `Suggests` in `DESCRIPTION` (required by
  `vignettes/plot-decorators.qmd`).
- Rewrote package-level help page (`help.R` /
  [`?hvtiPlotR`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md))
  to document all 57 exported functions, organised by category.
- Expanded “Saving figures” section in
  `vignettes/sas-migration-guide.qmd` with correct
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  single- and multi-slide examples.
- Added `ggplot2::geom_line(..., linewidth = 1.5)` (replacing deprecated
  `size =`) and updated `remotes::install_github()` (replacing
  [`devtools::install_github()`](https://devtools.r-lib.org/reference/install-deprecated.html))
  in `vignettes/hvtiPlotR.qmd`.

### Input validation improvements

- **`upset_plot()`** — added binary-column type check. ComplexUpset
  silently produces broken plots when `intersect` columns contain
  non-binary values; the function now errors with a clear message
  listing the offending columns before handing off to ComplexUpset.
- **[`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md)**
  — added `start_year` validation (previously `n_years` and
  `n_categories` were checked but `start_year` was not; a non-integer or
  non-finite value produced silently nonsensical output).
- **`trends_plot()`** — moved `match.arg(summary_fn)` to after the
  data-frame and column checks, so users see a clear `data` / column
  error rather than an opaque `'arg' should be one of...` message when
  both `data` and `summary_fn` are wrong.
- **`validators.R`** — added two scalar-parameter helpers:
  `.check_scalar_positive()` (finite, positive) and
  `.check_scalar_nonneg()` (finite, non-negative).
  `cb_validate_params()` in `covariate-balance.R` now delegates all four
  parameter checks to these helpers, eliminating 28 lines of bespoke
  validation code.

### Architecture

- **`.NP_SIM` constant list** (`nonparametric-curve-plot.R`) — lifted
  the seven simulation tuning constants (`eta_intercept`, `logit_shift`,
  `cont_baseline`, `cont_scale`, `cont_sigma`, `eff_frac_prob`,
  `eff_frac_cont`) from local variables in
  [`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md)
  and from hard-coded defaults in `.np_sample_bins()` into a single
  file-level private list. Both functions now reference `.NP_SIM$*` —
  change once, updates all simulation paths.

### Bug fixes / API consistency

- **Standardised `alpha` range to `[0, 1]`** across all plot functions.
  Previously `survival_curve()`, `covariate_balance()`,
  `mirror_histogram()`, `spaghetti_plot()`, and
  `goodness_followup_death_plot()` / `goodness_followup_event_plot()`
  used `(0, 1]` (rejecting `alpha = 0`), while `alluvial_plot()` used
  `[0, 1]`. All functions now accept `[0, 1]` — `alpha = 0` (fully
  transparent) is a valid ggplot2 value and should not be an error.
- **Added `.check_alpha()` shared validator** in `R/validators.R`.
  Enforces `alpha ∈ [0, 1]` with `call. = FALSE` and is called from
  every plot function that accepts an `alpha` argument.
- **`call. = FALSE` sweep** — every
  [`stop()`](https://rdrr.io/r/base/stop.html) call in the package now
  includes `call. = FALSE` so error messages never expose internal
  function names to callers.
- **Expanded shared validators** (`R/validators.R`) to 11 files (up from
  3). All of `alluvial-plot.R`, `covariate-balance.R`, `eda-plots.R`,
  `goodness-followup.R`, `hazard-plot.R`, `kaplan-meier.R`,
  `longitudinal-counts-plot.R`, `mirror-histogram.R`,
  `nonparametric-curve-plot.R`, `nonparametric-ordinal-plot.R`,
  `spaghetti-plot.R`, `stacked-histogram.R`, `trends-plot.R`, and
  `upset-plot.R` now delegate `data.frame`, column-presence,
  numeric-column, and alpha checks to `.check_df()`, `.check_cols()`,
  `.check_col()`, `.check_numeric_col()`, and `.check_alpha()`. Error
  wording is now consistent across all entry points.

### Code quality

- Named all simulation tuning constants in
  [`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md)
  and the internal helper `.np_sample_bins()`: `eta_intercept`,
  `logit_shift`, `cont_baseline`, `cont_scale`, `cont_sigma`,
  `eff_frac_prob`, `eff_frac_cont`. Magic numbers replaced throughout
  single-curve, multi-group, and binned-data-summary code paths.
- Named all simulation tuning constants in
  [`sample_nonparametric_ordinal_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_data.md)
  and
  [`sample_nonparametric_ordinal_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_points.md):
  `a_first`, `a_step`, `eta_intercept`. Every occurrence of `-0.2`,
  `0.5`, and `1.2` replaced by the named constant.
- Extended edge-case test coverage:
  - `test_kaplan_meier.R`: added five `survival_curve` error tests for
    non-numeric `time_col`, invalid `event_col` values (character
    instead of 0/1/logical), and `alpha` at 0, \> 1, and \< 0.
  - `test_hazard_plot.R`: added graceful-handling test for an empty data
    frame (correct columns, zero rows) — confirms ggplot renders without
    error.
  - `test_mirror_histogram.R`: added error test for non-numeric
    `score_col`.

## hvtiPlotR 2.0.0.9000

- Added `eda_plot()` — exploratory barplot/scatterplot for a single
  variable. Auto-detects variable type (`"Cont"`, `"Cat_Num"`,
  `"Cat_Char"`) and dispatches to scatter + LOESS + rug (continuous) or
  stacked/filled bar (categorical). `NA` values are shown as an explicit
  `"(Missing)"` fill level. Returns a bare ggplot object for composition
  with `scale_fill_*`, `scale_colour_*`,
  [`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
  [`annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html),
  and \[hv_theme()\]. Ports `Function_DataPlotting()` from
  `tp.dp.EDA_barplots_scatterplots.R`.
- Added
  [`eda_classify_var()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_classify_var.md)
  — replicates the `UniqueLimit` type-detection logic from
  `Barplot_Scatterplot_Function.R`: classifies a vector as `"Cont"`,
  `"Cat_Num"`, or `"Cat_Char"`.
- Added
  [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md)
  — subsets and reorders a data frame by a character vector or
  space-separated string of column names. Replaces `Order_Variables()`
  and the `Mod_Data <- dta[, Order_Var]` pattern from
  `tp.dp.EDA_barplots_scatterplots_varnames.R`.
- Added
  [`sample_eda_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_eda_data.md)
  — mixed-type cardiac-surgery registry simulation (binary, ordinal,
  character-categorical, and continuous variables) for demonstrating
  `eda_plot()` and
  [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md).
- Reorganised `inst/`: moved `par_cst.xpt` and `npar_cst.xpt` to
  `inst/extdata/` (standard R package location for bundled data files);
  removed unreferenced presentation and test artefacts (`*.pptx`,
  `*.pdf`, `*.sas` scratch files).
- Extended `nonparametric_curve_plot()` examples: added dual-Y-axis
  example (Example 10, `\dontrun`) using
  `scale_y_continuous(sec.axis = ...)`; noted `cll_p95`/`clu_p95` column
  availability for 95 % CI (Example 2) and per-group shape mapping via
  [`scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
  (Example 4).
- Extended `nonparametric_ordinal_plot()` examples: added pre-operative
  severity comparison example grouping combined Mild/Moderate/Severe
  cohorts through `nonparametric_curve_plot()`.
- Split vignette into three: `hvtiPlotR.qmd` (SAS migration guide),
  `plot-functions.qmd` (per-function reference with worked examples),
  `plot-decorators.qmd` (composition grammar: `scale_*`,
  [`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), themes,
  and saving to manuscript PDF, poster PDF, and editable PowerPoint via
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)).

## hvtiPlotR 1.1.0

- Added `survival_curve()` — Kaplan-Meier and Nelson-Aalen survival
  analysis returning five plot types (survival, cumulative hazard,
  hazard, log-log, life/RMST) plus risk and report tables. Ports the SAS
  `%kaplan` and `%nelsont` macros from `tp.ac.dead.sas`.
- Added
  [`sample_survival_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_data.md)
  — realistic exponential survival simulation with administrative
  censoring and optional treatment strata.
- Added `goodness_followup()` — goodness-of-follow-up scatter plot
  showing actual vs. potential follow-up per operation year, with
  optional non-fatal event panel.
- Added
  [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)
  — simulates an operative cohort with operation dates, follow-up times,
  competing events, and death.
- Added `covariate_balance()` — standardised mean difference dot-plot
  for propensity-score matching or weighting diagnostics.
- Added
  [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)
  — patient-level logistic simulation with greedy 1:1 caliper matching;
  SMDs computed before and after matching.
- Added `stacked_histogram()` and
  [`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md)
  — stacked or filled histogram of a numeric variable by group.
- Improved `mirror_histogram()` sample data
  ([`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md))
  to use a realistic logistic propensity-score model with greedy 1:1
  caliper matching and optional ATE IPTW weights; extreme-PS patients
  naturally go unmatched.
- Added `hv_plot()` dispatcher supporting `"mirror_histogram"`,
  `"stacked_histogram"`, and `"covariate_balance"` plot types.
- Added
  [`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)
  dispatcher for `"manuscript"`, `"ppt"`, `"dark_ppt"`, and `"poster"`
  themes.
- Enabled roxygen Markdown (`Roxygen: list(markdown = TRUE)`) so
  `**bold**`, backtick code spans, and `[pkg::fn()]` cross-references
  render correctly in Rd help pages.
- Added `survival` to package `Imports`.
- Updated package-level documentation (`help.R`) to reflect all current
  exported functions and sample-data generators.

## hvtiPlotR 0.2.2

- Fixed deprecated ggplot2 syntax (`size` -\> `linewidth` in
  `element_line` and `element_rect`).
- Removed empty `save.hvtiplotr` function.
- Fixed `theme_dark_ppt` to pass all parameters to `theme_grey`.
- Updated documentation for data objects.
- Updated README to reference `officer` package instead of deprecated
  `ReporteRs`.

## hvtiPlotR 0.2.0

- Initial CRAN submission.
