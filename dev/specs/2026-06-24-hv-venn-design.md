# hv_venn — Venn Diagram for Small Set Counts

**Date:** 2026-06-24
**Author:** John Ehrlinger (with Claude)
**Status:** Draft for review
**Repo:** hvtiPlotR (branch `feat/venn-diagram`)

## Problem

The package visualises set membership with `hv_upset()` (UpSet plots), which
reads a wide data frame of logical / 0-1 set-membership columns. UpSet is the
right tool for many sets, but for the common clinical case of **2-3 overlapping
groups** (e.g. "patients who had AV surgery, MV surgery, or CABG"), a classic
Venn diagram of overlapping circles is the familiar, publication-ready figure —
and the package has no Venn function. We add `hv_venn()` as the small-set-count
sibling of `hv_upset()`, reading the *same* input so callers can switch between
the two views without reshaping.

### Non-goals

- Not a high-set-count Venn. Legibility collapses past 3 sets (4 needs ellipses,
  5+ is unreadable — the reason UpSet exists). `hv_venn()` caps at 3 sets and
  points 4+ at `hv_upset()`.
- Not area-proportional (Euler). Proportional engines (`eulerr`, `VennDiagram`)
  are base/grid graphics that break the package's "`plot()` returns a bare
  ggplot you finish with `+`" contract. `hv_venn()` is schematic (equal circles)
  via `ggvenn`.
- Not a new sample-data generator. `sample_upset_data()` already produces logical
  set columns; examples pick 2-3 of them.
- No change to `hv_upset()`.

## Approach (agreed: A — constructor + region-count table)

Mirror the `hv_upset()` structure exactly: a constructor that validates the same
input and pre-computes a count table, plus a `plot()` method that returns a bare
ggplot via `ggvenn`.

### 1. Constructor `hv_venn(data, sets)`

- `data`: a data frame. `sets`: a character vector of **2-3** column names, each
  logical or 0-1 numeric (the `hv_upset` contract).
- Validation reuses the existing validators (`.check_df`, `.check_cols`) and
  `hv_upset`'s binary-column check, plus a `length(sets)` in `2:3` guard. A
  `length(sets) > 3` error names `hv_upset()` as the tool for more sets; a
  `length(sets) < 2` error states a Venn needs at least two sets.
- `sets` is the parallel to `hv_upset`'s `intersect`; named `sets` because it
  reads better for a Venn.
- Returns an object of class `c("hv_venn", "hv_data")` via `new_hv_data()`:
  - `$data`: the input data frame as-is (`plot.hv_venn` hands it to `ggvenn`).
  - `$meta`: `sets`, `n_patients`, `n_sets`.
  - `$tables$regions`: the region-count table (below).

### 2. Region-count table (`$tables$regions`)

`ggvenn` draws region counts but does not return them as data. The constructor
computes them so the numbers are available for a methods table even when only
the figure ships. For `k` sets it enumerates all `2^k - 1` non-empty regions:

- One logical column per set giving the membership pattern (in / out).
- A `region` label, e.g. `"AV only"`, `"AV & MV"`, `"AV & MV & CABG"` (set names
  joined by `" & "`, `"<set> only"` for single-set regions).
- `n`: the number of rows matching that exact in/out pattern. `NA` memberships
  are treated as `FALSE` (set not present), matching `hv_upset`.

2 sets → 3 rows; 3 sets → 7 rows. Built with a small internal helper
`.venn_regions(data, sets)` (data frame + columns → tidy region table), so it is
independently testable.

### 3. `plot.hv_venn()`

```r
plot.hv_venn(x, show_percentage = TRUE, show_counts = TRUE, fill = NULL,
             text_size = 4, set_name_size = 6, ...)
```

- Returns a bare ggplot from `ggvenn::ggvenn(x$data, columns = x$meta$sets, ...)`,
  mapping the exposed arguments to ggvenn's (`show_percentage`, `show_counts`,
  `fill_color`, `text_size`, `set_name_size`).
- `fill = NULL` uses ggvenn's default palette; a colour vector overrides it
  (mapped to `fill_color`).
- Extra `...` **forwards to `ggvenn::ggvenn()`**. This is a deliberate
  divergence from the other `plot.hv_*` methods (which ignore `...`): ggvenn
  bakes its labels into the geoms, so forwarding is the only way to reach its
  finer styling. Documented in the method.
- The result is still composable: `+ theme_hv_manuscript()`, `+ labs(title=)`,
  etc.

### 4. `print.hv_venn()`

Standard one-screen header matching the other `print.hv_*`: sets, patient count,
and region count.

## Components / files

| File | Change |
|---|---|
| `R/venn-plot.R` (new) | `.venn_regions()` helper; `hv_venn()`; `plot.hv_venn()`; `print.hv_venn()`; roxygen |
| `man/*.Rd` | generated (`hv_venn`, `plot.hv_venn`, `print.hv_venn`) |
| `NAMESPACE` | export `hv_venn`, `plot.hv_venn`, `print.hv_venn` |
| `DESCRIPTION` | add `ggvenn` to `Imports`; version bump |
| `_pkgdown.yml` | add the three topics to the "Exploratory Data Analysis" section (the index omission that broke an earlier PR's pkgdown build — do not repeat) |
| `tests/testthat/test_venn.R` (new) | tests (below) |
| `vignettes/plot-functions.qmd` | worked `hv_venn` example near the UpSet section |
| `README.md` | gallery row in the EDA / set-membership area |
| `NEWS.md` | entry under the new version |

`.venn_regions()` is data-frame-in / data-frame-out; `hv_venn()` validates and
builds the object; `plot.hv_venn()` renders. Each is understandable and testable
on its own.

## Testing

`test_venn.R`:

1. **Validation.** `hv_venn()` errors on `< 2` sets, on `> 3` sets (message names
   `hv_upset`), on a non-binary column, and on a missing column.
2. **Object shape.** Returns `c("hv_venn", "hv_data")`; `$meta$sets` and
   `$meta$n_sets` correct.
3. **Region table.** `.venn_regions()` on a hand-built 2-set frame returns 3 rows
   with known `n`; on a 3-set frame returns 7 rows; `NA` membership counts as
   absent; the `region` labels read as specified.
4. **Plot.** `plot(hv_venn(...))` returns a ggplot; composable with
   `theme_hv_manuscript()`; `show_percentage = FALSE` and a `fill` override both
   produce a ggplot (smoke tests through ggvenn).
5. **Print.** `print.hv_venn` emits a `<hv_venn>` header and returns `x`
   invisibly.

Run under `if (requireNamespace("ggvenn"))` is unnecessary — `ggvenn` is a hard
`Imports`, so no skip guard is needed (the binary-column and region-table tests
don't even touch ggvenn).

## Verification / success criteria

1. `plot(hv_venn(sample_upset_data(), sets = c("av_any","mv_any","cabg")))`
   renders a 3-circle Venn with region counts, composable with the hv themes.
2. `$tables$regions` counts match a `table()`-based hand computation on the
   sample data.
3. `hv_venn()` with 4 sets errors and names `hv_upset()`.
4. `test_venn.R` passes; `devtools::check()` clean; pkgdown reference index
   includes the three new topics.

## Release implications

hvtiPlotR is internal-only (no CRAN), but the house release gate applies: new
exports + a new dependency mean a **minor** version bump. With the numbers-at-risk
work (2.5.0) ahead in the merge queue, this lands as **2.6.0** (set the exact
number at implementation time from what is merged); bump `DESCRIPTION` line 4
**and** `NEWS.md`; `\value`/`@return` on the exports; runnable examples;
`R CMD check` to 0/0/0 **with the pkgdown topic index updated**. Open a PR;
**John merges** (do not self-merge).

## Open questions

None outstanding. `sets` vs `intersect` naming is settled (`sets`); engine is
settled (`ggvenn`, Imports); set-count cap is settled (2-3); `...` forwarding to
`ggvenn` is intentional and documented.
