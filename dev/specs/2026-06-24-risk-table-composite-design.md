# Numbers-at-Risk Table Harness and Survival Curve / Table Composites

**Date:** 2026-06-24
**Author:** John Ehrlinger (with Claude)
**Status:** Draft for review
**Repo:** hvtiPlotR (branch `feat/risk-table-composite`)

## Problem

The survival-curve constructors render a curve but nothing renders the
numbers-at-risk table that accompanies it in a publication figure. `hv_survival()`
already computes `km$tables$risk` (a tidy `strata` x `report_time` x `n.risk`
data frame), but a caller who wants the canonical Kaplan-Meier-plus-risk-table
composite has to hand-build the table panel and align it under the curve. The
other survival-family constructors (`hv_nonparametric`, `hv_ordinal`, parametric
`hv_hazard`) do not even expose a risk table.

We want a small harness that (1) renders a numbers-at-risk table as a bare
`ggplot2` panel, and (2) composes a curve over that panel with aligned x-axes,
so the standard survival composite is a two-call operation that still fits the
package's two-step "constructor then `plot()` returns a bare ggplot you finish
with `+`" contract.

There is a SAS-template precedent for this figure: `tp.hp.dead.number_risk.R`
(survival + at-risk table), referenced in `R/hazard-plot.R`.

### Non-goals

- Not a new survival estimator. The at-risk count is the empirical number still
  under observation; the curves are unchanged.
- Not auto-matching the table's stratum-label colours to the curve's colour
  scale. Black labels in v1; colour matching is a later nicety (YAGNI).
- Not a one-call "give me everything" function. The renderer and composer stay
  separate so each is testable and the curve can be decorated before composing.
- No new sample-data generator; `sample_survival_data()` (already stratified)
  covers the examples and tests.

## Approach (agreed: A — shared empirical helper; KM auto-carries `$tables$risk`, others via the renderer's data path)

Three pieces: a shared count helper, risk-table sourcing (KM auto-populates;
the curve-data constructors are served through the renderer's input path), and
two exported functions (renderer + composer).

### 1. Data layer — shared count helper

New internal helper in a new file `R/at-risk-table.R`:

```r
.atrisk_table(time, status, group = NULL, report_times)
```

- For each group level and each `t` in `report_times`, `n.risk = sum(time >= t)`
  among that group's subjects — the empirical "still under observation at `t`"
  count. This definition is model-independent: given subject-level
  `(time, status)` data the count is the same whatever curve sits above it
  (Kaplan-Meier, nonparametric, ordinal, or parametric). The helper only needs
  the subjects; it never touches the curve estimator.
- Returns a tidy data frame with columns `strata`, `report_time`, `n.risk` —
  the exact shape `hv_survival$tables$risk` already uses, so nothing downstream
  needs a new format.
- `group = NULL` yields a single stratum labelled `"Overall"`.
- `status` is accepted for signature symmetry and future per-time event counts;
  v1 uses only `time` and `group` for the count. (It is wired now so the helper
  does not need a signature change later.)

`hv_survival` keeps its existing `km_risk_table()` **unchanged**. That function
reads the `n.risk` value `survfit()` carries at the last event/censor time at or
before each report time — the authoritative Kaplan-Meier convention, where a
subject with follow-up exactly at that time is still counted at risk.
`.atrisk_table()`'s `sum(time >= t)` convention drops such a subject once `t`
passes their time, so the two legitimately differ at report times that fall
between events. We therefore do **not** refactor `km_risk_table()` onto the
shared helper — preserving the exact, survfit-derived KM numbers takes priority
over a single code path. `.atrisk_table()` serves only the renderer's raw-data
input mode (the non-KM curves), which has no survfit object to defer to and uses
the standard at-risk-at-start-of-interval count. A test asserts the two agree on
a case with no events between report times (so the difference is understood and
bounded, not accidental).

### 2. Risk-table sourcing across the family

Only `hv_survival` receives subject-level patient data (it runs `survfit()`
internally); `hv_nonparametric`, `hv_ordinal`, and `hv_hazard` receive
**pre-summarized curve data** (time, estimate, CI/grade) and never see the
underlying subjects. They therefore cannot compute numbers-at-risk on their own.

So the count is sourced two ways, both through the same `.atrisk_table()`
helper:

| Constructor | Risk-table source |
|---|---|
| `hv_survival` | auto-populates `$tables$risk` at build time (refactor to shared helper; output unchanged) |
| `hv_nonparametric`, `hv_ordinal`, `hv_hazard` | **not modified.** The caller feeds the table to `hv_atrisk()` directly — either subject-level `(time, status, group)` data (computed via `.atrisk_table()`) or a precomputed `strata`/`time`/`n` table |

This keeps the three curve-data constructors untouched and still lets the
renderer + composer serve every family member: for the non-KM curves you supply
the at-risk data to `hv_atrisk()`, which is exactly the data-frame / raw-data
input path described next.

When `report_times` is not supplied on the raw-data path, the default is
**derived from the observed time range** — an even spread of round points
across `[min, max]` follow-up (roughly 5–6 ticks), so the report points always
fall inside the data. When `x` is an object that already carries `$tables$risk`
(e.g. `hv_survival`), its existing report points are used as-is.

### 3. Renderer — `hv_atrisk()`

```r
hv_atrisk(x, time = NULL, status = NULL, group = NULL,
          report_times = NULL, size = NULL, strata_labels = NULL, ...)
```

- `x` accepts **three input modes**:
  1. a survival-family `hv_data` object that carries `$tables$risk`
     (today: `hv_survival`) — reads it directly;
  2. a precomputed risk data frame with `strata` / `report_time` (or `time`) /
     `n.risk` (or `n`) columns — used as-is;
  3. a subject-level data frame plus the `time` / `status` / `group` column
     names — counts are computed via `.atrisk_table()`. This is the path for
     the non-KM curves (`hv_nonparametric`, `hv_ordinal`, `hv_hazard`), whose
     constructors do not carry a risk table.
- The mode is resolved by inspecting `x` and which of `time`/`status`/`group`
  are supplied; an unresolvable input errors with a message naming the three
  accepted forms.
- Returns a **bare `ggplot2` table panel**: one `geom_text` count per
  (stratum, report time), placed at `x = report_time`, `y = strata`. One row per
  stratum, ordered to match the curve legend top-to-bottom. x is a continuous
  time axis; strata are the y rows (labelled on the y-axis).
- Minimal, `theme_hv_*`-compatible styling: no panel grid, y-axis shows stratum
  labels, x-axis text/title blanked by default (redundant when stacked under a
  curve that carries the axis). Composable — a caller can still add `+ theme()`.
- Small argument surface: `report_times = NULL` (use the object's), `size`
  (text size), `strata_labels = NULL` (override row labels). Stratum text stays
  black in v1.

### 4. Composer — `hv_atrisk_compose()`

```r
hv_atrisk_compose(curve, table, heights = c(3, 1))
```

- Takes the two already-built (and possibly decorated) ggplots: the `curve`
  from `plot(km)` and the `table` from `hv_atrisk(km)`.
- Owns x-axis alignment: reads the curve's x scale (limits and breaks) and
  applies the same to the table panel, then stacks them with `patchwork`
  (`curve / table` plus `plot_layout(heights = heights)`), so the time ticks
  line up beneath the curve. Patchwork aligns the panel regions (including the
  y-axis-label gutter) on its own; only if a real example misaligns do we add
  an explicit gutter fix.
- Returns a `patchwork` object. Decorate further with patchwork's `&`
  (e.g. `& theme_hv_manuscript()`); the docs show this.
- `heights` sets the curve:table height ratio (default `c(3, 1)`).

## Components / files

| File | Change |
|---|---|
| `R/at-risk-table.R` (new) | `.atrisk_table()` helper; `hv_atrisk()`; `hv_atrisk_compose()`; their roxygen |
| `man/*.Rd` | regenerated (roxygen) for the two new exports |
| `NAMESPACE` | export `hv_atrisk`, `hv_atrisk_compose` |
| `tests/testthat/test_at_risk.R` (new) | tests (see below) |
| `vignettes/plot-functions.qmd` | worked KM + risk-table composite example |
| `vignettes/sas-migration-guide.qmd` | note mapping to `tp.hp.dead.number_risk.R` |
| `README.md` | gallery row for `hv_atrisk()` / `hv_atrisk_compose()` |
| `NEWS.md`, `DESCRIPTION` | new dev version (minor bump) |

Each unit has one job: `.atrisk_table()` is data-frame in / data-frame out;
`hv_atrisk()` is object-or-data-frame in / bare ggplot out (resolving its three
input modes); `hv_atrisk_compose()` is two ggplots in / aligned patchwork out.
Each is understandable and testable without the others.

## Testing

`test_at_risk.R` adds:

1. **Count correctness.** `.atrisk_table()` on a hand-built `(time, status,
   group)` case returns the known `n.risk` per (stratum, report time); counts
   are non-increasing in time; `group = NULL` yields a single `"Overall"`
   stratum.
2. **KM left untouched + conventions agree where they should.**
   `km_risk_table()` is unchanged. `.atrisk_table()` and `km_risk_table()`
   return the same `n.risk` on a constructed case with no events between report
   times (confirming the only difference is the documented at-the-time
   convention, not a bug).
3. **Raw-data path.** `hv_atrisk()` given a subject-level data frame plus
   `time` / `status` / `group` column names returns the same panel it would
   from the equivalent precomputed table (this is how the non-KM curves are
   served); an unresolvable `x` errors naming the three accepted forms.
4. **Renderer.** `hv_atrisk()` returns a ggplot with one text layer carrying
   `n_strata * n_report_times` labels, from a family object, a precomputed
   data frame, and the raw-data path; `strata_labels` overrides the row labels.
5. **Composer.** `hv_atrisk_compose(plot(km), hv_atrisk(km))` returns a
   `patchwork` object whose two panels share x-axis limits.

Survival-family tests already guard nothing extra here (base R + ggplot2 +
patchwork are all hard deps), so no `requireNamespace()` skips are needed.

## Verification / success criteria

1. `hv_atrisk_compose(plot(km), hv_atrisk(km))` on stratified
   `sample_survival_data()` renders a KM curve over an aligned numbers-at-risk
   table (ticks line up, one row per stratum).
2. `hv_survival$tables$risk` output is unchanged (`km_risk_table()` untouched).
3. `hv_atrisk()` renders a panel for a non-KM curve (e.g. `hv_nonparametric`)
   via its subject-level / precomputed-table input path.
4. `test_at_risk.R` passes; full suite green; `devtools::check()` 0/0/0.

## Release implications

hvtiPlotR is internal-only (no CRAN), but the house release gate still applies:
new exports mean a **minor** version bump (anticipated `2.5.0`); update
`DESCRIPTION` line 4 **and** `NEWS.md` top header to match; `\value`/`@return`
on both new exports; runnable examples; `R CMD check` to 0/0/0. Open a PR;
**John merges** (do not self-merge).

## Open questions

None outstanding. Decided during review: only `hv_survival` auto-carries
`$tables$risk` (the other three constructors take pre-summarized curve data and
are served through `hv_atrisk()`'s data/raw-data input path); default
`report_times` on the raw-data path is **derived from the observed time range**;
y-axis-gutter alignment is **left to patchwork**, with an explicit fix added
only if a real example misaligns.
