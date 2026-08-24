# Changelog

## hvtiPlotR 2.7.9

### Lint debt

Work on [\#89](https://github.com/ehrlinger/hvtiPlotR/issues/89).
Nothing here changes what any function does; the suite is unchanged at
1629 passing tests.

- Whitespace, commas, semicolons, braces and one over-long `@importFrom`
  line brought into line with `.lintr`. The two multi-line anonymous
  functions in
  [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md)
  and
  [`hv_venn()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_venn.md)
  are now written as a single-line predicate passed to
  [`vapply()`](https://rdrr.io/r/base/lapply.html), which reads better
  than the braces lintr wanted.
- [`plot.hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_eda.md)
  no longer assigns `y_col_name`, which nothing read. The y label comes
  from `meta$y_label`.
- Tests that build a plot inside a helper function now use the `.data`
  pronoun in
  [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html), so the
  linter can see the column references.
- Two false positives are marked with `# nolint` and a note saying why:
  [`hv_consort_start()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_start.md)
  takes a bare column name by design, and the survival times in
  `.hp_km_binned()` are read inside a formula, which
  [`codetools::checkUsage()`](https://rdrr.io/pkg/codetools/man/checkUsage.html)
  does not walk.
- The naming lints are cleared and **the lint workflow now gates**:
  `LINTR_ERROR_ON_LINT` is `true`, so
  [`lintr::lint_package()`](https://lintr.r-lib.org/reference/lint.html)
  must return zero before a push. `.lintr` states its three deviations
  from lintr’s defaults and the reason for each: line length 120,
  `object_length` 35 because six exported `sample_*` generators are
  longer than 30 and renaming an export is a breaking change, and
  `SNAKE_CASE` accepted alongside `snake_case` for the score-scale
  constants.
- The design-matrix locals in
  [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)
  are now `x_mat` / `x_mc` / `x_mt`, and one vignette variable is
  `ccf_ppt_plot`.
  [`makeFootnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md)
  and its `footnoteText` argument keep their camelCase, being the public
  API of the release before the rename.

## hvtiPlotR 2.7.8

### Behaviour change

- [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  now sets `legend.position = "none"`, matching
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  and
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).
  It previously inherited
  [`theme_grey()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)’s
  `"right"`, which made it the one theme in the family that drew a key.
  House style names a series by annotation on every output target, so
  the poster theme was the outlier, not the rule, and the docs had been
  describing four themes as though they all behaved this way. **A poster
  figure that relied on the automatic legend will now render without
  one**; pass `legend.position = "right"` through `...`, or chain
  `+ theme(legend.position = "right")`, to restore it.

- A test now asserts the property across the theme family as a set
  rather than one theme at a time, discovering the exported
  `theme_hv_*()` functions rather than listing them. A hard-coded list
  reads as a set-wide contract while only checking the themes that
  existed when it was written, which is the gap that let the poster
  theme drift; a fifth theme is now covered without anyone remembering
  to add it.

### Documentation

- Corrected two overstatements introduced in 2.7.7, both of the same
  shape: a claim that held for most cases stated as though it held for
  all.

- [`hv_ppt_series()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_series.md)
  and `vignettes/plot-decorators.qmd` said every `theme_hv_*()` sets
  `legend.position = "none"`. Three do:
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  and
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).
  [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  never set it and inherited ggplot2’s `"right"`. The docs were
  corrected first to describe that, and the theme has since been changed
  to match the other three (see **Behaviour change** above), which makes
  the original “every `theme_hv_*()`” wording true rather than merely
  accurate about an inconsistency.

- [`hv_ppt_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_palette.md)
  said the reordering puts the strongest contrast first. That is true of
  the first entry in the dark ordering only. Measured against each
  ordering’s own background, neither ordering is monotonic in contrast
  ratio, and black is deliberately **last** in the light ordering while
  carrying the highest ratio of any colour here (21:1 on white). The
  `@details` now say what the ordering actually guarantees, which is
  that each ordering leads with its highest-contrast hue, and give the
  real reason black is last: house style draws annotation in the theme’s
  ink, so a black series would be confusable with the label naming it.

## hvtiPlotR 2.7.7

### New features

- [`hv_ppt_series()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_series.md)
  bundles a PowerPoint theme with matching colour and shape scales into
  one object you add to every plot in a deck, so the per-slide finishing
  step is defined once instead of copied per figure. A
  [`theme()`](https://ggplot2.tidyverse.org/reference/theme.html) cannot
  do this on its own: it governs the non-data ink and nothing that draws
  from the data, so no theme element sets a series colour, and passing a
  layer to a `theme_hv_*()` call errors rather than styling anything,
  since that `...` is forwarded straight to
  [`theme()`](https://ggplot2.tidyverse.org/reference/theme.html).
  Colours and shapes belong to the scales. The return value is a plain
  list, and ggplot2’s `+` unrolls it, so it composes exactly like a
  theme. Colour and shape both map the grouping column, since a
  projector flattens colour differences that read cleanly on a monitor.
  The house-style `legend.position = "none"` is left alone; pass
  `legend.position` through `...` when a draft wants a key.

- [`hv_ppt_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_palette.md)
  returns those colours as a character vector, so a figure that needs
  them outside the decorator reaches for the one definition instead of
  pasted hex codes. Six Okabe-Ito colourblind-safe hues, reordered per
  background: high-luminance first on a dark slide, darker first on a
  light one. Annotation is not one of these uses; a label takes the
  theme’s ink to match the axis, white on a slide and black in a
  manuscript.

### Bug fixes

- The Arial fallback in
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  /
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  now covers text geoms as well as theme elements. ggplot2 4.0 resolves
  a text geom’s `family` through the theme’s `geom` element, which
  [`theme_grey()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  seeds from `base_family` alongside `text`, so patching `text` alone
  left
  [`geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
  and `annotate("text", ...)` still asking the device for Arial. On
  [`postscript()`](https://rdrr.io/r/grDevices/postscript.html) /
  [`pdf()`](https://rdrr.io/r/grDevices/pdf.html) that is fatal
  (“invalid font type”), not merely a substituted glyph, so a PPT-themed
  plot carrying an annotation could not be drawn on those devices at
  all. House style names series by annotation rather than by a legend,
  which makes this the common case; no existing example or test drew a
  text geom on a PPT theme, which is why it went unseen.

## hvtiPlotR 2.7.6

### Bug fixes

- [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)
  and
  [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
  no longer report a cohort size that differs from the one actually
  analysed. Both silently dropped incomplete rows – `survfit()` omits
  them, and
  [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
  filtered with
  [`complete.cases()`](https://rdrr.io/r/stats/complete.cases.html) –
  while `$meta` and [`print()`](https://rdrr.io/r/base/print.html) kept
  reporting `nrow(data)`. A 20-row input with two missing follow-up
  times fitted 18 patients but reported 20. Both now exclude incomplete
  rows explicitly, warn once naming the columns responsible, and report
  `n_obs` / `n_patients` as the analysed cohort alongside `n_input` and
  `n_excluded`. [`print()`](https://rdrr.io/r/base/print.html) shows the
  split whenever anything was excluded. The event panel requires more
  columns than the death panel, so the two can hold different cohorts;
  each is filtered and warned about separately, and the event panel’s
  counts are reported as `n_event_patients` / `n_event_excluded`.

- The
  [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
  event panel no longer misclassifies death-before-event as a non-fatal
  event. The state was taken from the event flag alone, and
  `gf_build_event_frame()` never received the death time, so it
  structurally could not order the two: a patient dying at year 1 with
  an event recorded at year 2 was labelled “Non-fatal event”,
  contradicting the documented “death before non-fatal event” state. The
  event time is now compared against `death_time_col`, and a flagged
  event only counts as non-fatal when it strictly precedes death. Ties
  go to death.

- The missing-data contract is now package-wide, in two deliberately
  different shapes. **Analysis** constructors
  ([`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md),
  [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md))
  *exclude* incomplete rows, because the fit they wrap already has —
  reporting a cohort the fit never saw is simply wrong. **Plot**
  constructors
  ([`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md),
  [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md),
  [`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md),
  [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md),
  [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md))
  *account* for them instead: they warn once, record `n_missing` in
  `$meta`, and [`print()`](https://rdrr.io/r/base/print.html) shows the
  count — but they do not filter. Pre-filtering there would also swallow
  ggplot2’s own “Removed n rows” warning, which legitimately fires for
  values outside a zoomed scale range and not only for missing ones.
  [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  already reported `n_dropped` and keeps its existing diagnostics table.

- Grouping and label columns are treated as a third case: they must be
  complete, and a missing value there is now an error. Such a value does
  not drop the row — it silently merges it into an `"NA"` group that
  reads as a real series in the legend, or, for
  [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md)’s
  `id_col`, fuses unrelated subjects into a single trajectory. Affects
  `group_col` in
  [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md)/[`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md),
  `id_col` and `colour_col` in
  [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md),
  and `variable_col`/`group_col` in
  [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md);
  [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md)
  already behaved this way.

- [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md)
  now rejects negative and non-finite counts, which previously rendered
  as downward bars without warning, and rejects missing time or series
  labels, which collapsed into an `NA` category that read as a real
  group on the axis and in the legend.

- [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md)
  no longer loses non-numeric time points. Summary positions came from
  `as.numeric(names(tapply(...)))`, so factor labels and dates became
  `NA` and their summary points vanished from the plot. The original x
  type is now preserved through aggregation.

- [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)
  and
  [`hv_atrisk()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk.md)
  now reject `report_times` containing `NA`, `NaN`, `Inf`, or negative
  values. Previously these were accepted and survived into the risk and
  report tables as plausible-looking rows rather than failing: `NA` and
  a negative time each reported 100% survival, and `Inf` reported the
  final survival estimate at time `Inf`. The failure was silent, so the
  table was misleading rather than obviously wrong. Both functions now
  share a `.check_report_times()` validator. The check applies on every
  entry point, including
  [`hv_atrisk()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk.md)
  called with an `hv_data` object or a precomputed risk table – those
  route through `.select_report_times()`, where bad values were
  previously dropped with an “ignored” warning instead of erroring.
  `report_times = NULL` still means “every time already in the table”.

- [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md)
  and
  [`hv_venn()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_venn.md)
  now reject duplicated entries in `intersect` and `sets`. A repeated
  name mangled the column to `A.1`, producing two contradictory “A only”
  regions and a nonsense “A & A” self-intersection.

### Documentation

- The SAS migration guide had four factual errors beyond the follow-up
  section, all now corrected against the functions they describe: the
  UpSet section still named `ComplexUpset` as the backend (it has been
  `ggupset` since 2.2.0); the alluvial section credited an internal
  `to_lodes_form()` reshape that
  [`hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md)
  does not perform; the covariate-balance section described the wide SAS
  export as “one column per time-point” when the columns are comparisons
  (`Before match` / `After match`); and the longitudinal section claimed
  [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md)
  accepts a patient-level frame when it takes pre-aggregated counts. The
  survival section also conflated five plot types with four SAS output
  flags, and now names which is which.

### Packaging

- `.Rbuildignore` now excludes `vignettes/.quarto/`, rendered vignette
  `.html`, and the `.superpowers/` tool-state directory. These added 230
  paths to the source tarball and triggered an `R CMD check` warning
  about rendered artifacts in `vignettes/`.

- `.Rbuildignore` also excludes `.lintr`. It is a development-time lint
  configuration, not part of the installed package, and shipping it drew
  an `R CMD check` NOTE about hidden files. It stays tracked in git.

- The `Authors@R` email now matches the `Maintainer` field
  (`john.ehrlinger@gmail.com`). The two had disagreed, which
  `R CMD check` reports as a DESCRIPTION meta-information NOTE.

- Three `\donttest` examples wrote PDFs into the working directory
  (`survival.pdf`, `trends.pdf`, `fig.pdf`). `--as-cran` executes those
  blocks, so the files landed in the check directory and were reported
  as non-standard. They now write to
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html), which is what
  CRAN policy requires of examples regardless of the NOTE.

## hvtiPlotR 2.7.5

### Bug fixes

- [`plot.hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup.md)
  no longer draws a vertical stem below each patient’s point. The stem
  was a carryover from the legacy `tp.dp.gfup.R` SAS template; at
  realistic cohort sizes it smears the point cloud and, because it
  shares the `colour` aesthetic with the points, it also struck a line
  through every glyph in the legend key.
  [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
  now defaults `segment_drop = 0` and the segment layer is omitted
  entirely when the drop is zero, so both the panel and the legend show
  bare shapes. Pass `segment_drop = 0.2` to restore the previous
  appearance.

## hvtiPlotR 2.7.4

### Bug fixes

- [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  /
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  no longer error on a graphics device that can’t resolve the default
  `base_family = "Arial"`
  (e.g. [`postscript()`](https://rdrr.io/r/grDevices/postscript.html)/[`pdf()`](https://rdrr.io/r/grDevices/pdf.html)
  on Linux, which is what `R CMD check --run-donttest` renders examples
  with). The active device is checked at draw time – immediately before
  [`print()`](https://rdrr.io/r/base/print.html)/`grid.draw()` hand off
  to ggplot2 – and falls back to `"Helvetica"` (metrically compatible)
  only when Arial genuinely can’t be resolved there, with a one-time
  session message explaining why. Devices that resolve system fonts
  directly (quartz, cairo, RStudio’s graphics device) are unaffected and
  continue to render real Arial. No global font registry is modified.

### Documentation

- Documentation now follows the composed house style. The package-level
  documentation moved from `R/help.R` to `R/hvtiPlotR-package.R`, and
  the stale root `writing-voice.md` was replaced by the generated
  `.claude/house-style.md`. No user-facing behaviour changed.

## hvtiPlotR 2.7.3

### New features

- [`save_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_manuscript.md)
  gains `draft_file`/`draft_dpi` arguments: write an additional raster
  (typically PNG) copy alongside the primary publisher file in one call.
  Use this to keep a small, portable draft figure for dragging into a
  Word manuscript while `file` stays the publisher deliverable (vector
  PDF/EPS, or raster TIFF) actually submitted to the journal.

## hvtiPlotR 2.7.2

### New features

- [`hv_legend_inside()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_legend_inside.md)
  gains a `prefer` argument: name a corner
  (`"topright"`/`"topleft"`/`"bottomright"`/`"bottomleft"`) and the
  legend goes there when that corner is clear, even if another corner is
  emptier. When the preferred corner is occupied it falls back to the
  emptiest-corner logic, so the occlusion guard is never given up.

## hvtiPlotR 2.7.1

### New features

- [`hv_legend_inside()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_legend_inside.md):
  place a plot’s legend in the emptiest panel corner automatically,
  falling back to an outside position when no corner is clear
  (e.g. dense multi-curve panels). Coordinates come from the coord’s own
  transform, so
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html)
  is handled correctly. Apply it after the house theme. See the
  recipes-book legends chapter.

### Dependencies

- Minimum `ggplot2` raised to `>= 3.5.0` (the version that introduced
  the inside-legend API
  [`hv_legend_inside()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_legend_inside.md)
  uses: `legend.position = "inside"` with `legend.position.inside` /
  `legend.justification.inside`).

## hvtiPlotR 2.7.0

### New features

- [`save_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_manuscript.md):
  save a ggplot at the house manuscript figure size (6 x 4 inches) in
  one call — the manuscript counterpart of
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md).
  Pair it with
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  for the 12 pt typography; like
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
  it fixes the output geometry, not the theme. Pass
  `device = grDevices::cairo_pdf` to embed fonts in a PDF where cairo is
  available.

### Documentation

- Cross-reference the companion **HVTI ggplot graphics recipes** book
  (<https://ehrlinger.github.io/hvti_graphics/>) from the package help
  page, the `DESCRIPTION` `URL` field, the README, and the pkgdown
  navbar.

## hvtiPlotR 2.6.1

### Bug fixes

- [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
  the `paper` argument now controls the figure background
  (`plot.background` fill). It was hard-coded to `"transparent"`, so
  passing `paper` had no effect. The PPT themes still default to
  transparent (the slide background shows through);
  [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  now honours its `"white"` default.

### Documentation

- [`plot.hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_alluvial.md):
  clarify that `show_yaxis = FALSE` is a
  [`theme()`](https://ggplot2.tidyverse.org/reference/theme.html) layer,
  so a complete theme added afterward
  (e.g. [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md))
  re-asserts the axis it styles.
- [`plot.hv_venn()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_venn.md):
  note the diagram is coordinate-free — do not add an axis-bearing house
  theme, which pastes spurious axes onto it. Example updated.

## hvtiPlotR 2.6.0

### New features

- [`hv_venn()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_venn.md)
  draws a 2-3 set Venn diagram of overlapping set memberships — the
  small-set-count companion to
  [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md),
  reading the same logical / 0-1 set-membership columns. It returns an
  object carrying a `$tables$regions` count table (one row per Venn
  region), and [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  renders a bare ggplot via ggvenn that you finish with `+ theme_hv_*`.
  For more than three sets, use
  [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md).

**Dependency:** `ggvenn` added to `Imports`.

## hvtiPlotR 2.5.0

### New features

- [`hv_atrisk()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk.md)
  renders a numbers-at-risk table as a bare ggplot panel. It takes a
  survival-family object that carries `$tables$risk` (e.g.
  [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)),
  a precomputed `strata`/`time`/`n` table, or a subject-level data frame
  plus `time`/`status`/`group` column names (the path for the curve-data
  constructors `hv_nonparametric`, `hv_ordinal`, `hv_hazard`, which
  carry no risk table). Missing `report_times` are derived from the
  observed time range.
- [`hv_atrisk_compose()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk_compose.md)
  stacks a survival curve over an
  [`hv_atrisk()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk.md)
  panel, aligning the table’s x-range to the curve’s and composing them
  with patchwork. Decorate both panels with patchwork’s `&`.

## hvtiPlotR 2.4.0

### New features

- [`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md):
  with `node_levels = NULL` (default), the node order is now derived
  from the data instead of the first column’s factor levels. It spans
  every label in any `cluster_cols` column and seats each child next to
  its parent (the coarser-K cluster holding most of its members), so
  flows stay uncrossed and the spurious grey `NA` boxes are gone. An
  explicit `node_levels` is still used as given but must cover every
  observed label.
- [`plot.hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_sankey.md):
  `alpha` is split into `flow_alpha` (default `0.5`) for the flows and
  column guides and `label_alpha` (default `0.3`) for the label fill,
  matching the publication look. `alpha` is deprecated; if given, it
  sets both and emits a message.
- [`plot.hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_sankey.md):
  new `group_labels`, a named vector mapping a `cluster_cols` value to a
  milestone label (e.g. `c(C7 = "5 groups")`). That column’s x-axis tick
  reads `"<col>\n<label>"`; unlisted columns stay bare.
- [`plot.hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_sankey.md):
  default `node_colours` map labels to Set1 in node order, recycling
  with a warning when labels outnumber colours.
- [`plot.hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_alluvial.md):
  new `show_yaxis` (default `TRUE`). Set `FALSE` to blank the y-axis
  title, text, ticks, and line for a clean patient-flow look; the
  geometry is untouched and you can still add your own
  [`theme()`](https://ggplot2.tidyverse.org/reference/theme.html) after.

## hvtiPlotR 2.3.4

### Bug fixes

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md):
  corrected `panel_box` defaults to
  `list(width = 8.79, height = 4.422, left = 2.67, top = 1.29)`.

## hvtiPlotR 2.3.3

### Bug fixes

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md):
  the white box behind plots is gone again. The earlier fix only cleared
  the officer placeholder’s fill;
  [`rvg::dml()`](https://davidgohel.github.io/rvg/reference/dml.html)
  still defaults to `bg = "white"`, so the DrawingML graphic painted its
  own opaque white canvas rectangle behind the (transparent) plot. Both
  `dml()` calls (plots and consort diagrams) now pass
  `bg = "transparent"`, so the slide-template background shows through
  cleanly on dark/blue decks.
- [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  and
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  now default to `base_family = "Arial"`, `base_size = 32`, with **Arial
  32 Bold** axis tick labels and **Arial 40 Bold** axis titles —
  matching the canonical CORR deck (driveline-infections, slide 6). Axis
  titles scale at `base_size * 1.25`. (Slide-title fonts are controlled
  by the PowerPoint template, not the theme.) Override at the call site
  as usual, e.g. `theme_hv_ppt_dark(base_size = 28)`.

### Changes

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  now defaults `panel_box` to the standard CORR fixed-panel rectangle
  `list(width = 8.88, height = 4.51, left = 2.58, top = 1.63)`, so every
  deck anchors the plot panel at the same slide coordinates by default
  (AATS-style placement). Pass `panel_box = NULL` to restore the legacy
  fixed-`width`/`height`/`left`/`top` placement. Because the default now
  routes plots through
  [`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md),
  save_ppt suppresses the benign “font family ‘Arial’ not found in
  PostScript font database” warning from the grob-measurement device
  (the slide graphic still embeds Arial via systemfonts).

### Documentation

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  examples now show the recommended preview-light / save-dark workflow
  (build with
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  for the IDE viewer, swap to
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  before saving) and add a no-y-axis-label slide (`labs(y = NULL)`).
- Dropped the `family = "mono"` snippet from the theme docs and switched
  the executed Kaplan–Meier examples off the Arial PPT themes (to
  [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)),
  so `R CMD check` examples stay warning-free on hosts without Arial
  installed (a cause of the failing CI run).
- Declared `xml2` in `Suggests` (used by the save_ppt white-box test),
  fixing the “unstated dependencies in ‘tests’” check WARNING.
- Added a small (~16 KB) dark-background test template at
  `inst/extdata/hv_ppt_template.pptx`, derived from the canonical CORR
  deck (master, layouts, and theme only — content slides, notes,
  comments, media, and document metadata stripped). Reach it with
  `system.file("extdata", "hv_ppt_template.pptx", package = "hvtiPlotR")`
  to try
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  against an authentic dark slide master.

## hvtiPlotR 2.3.2

### Documentation ([\#70](https://github.com/ehrlinger/hvtiPlotR/issues/70))

- Vignette clarity pass: added structural grounding to all five
  vignettes — two to four sentences before every code chunk on what the
  recipe does, when to reach for it, and (for bare/raw plots) what to
  look for. Applied the `memory/vignette-clarity-pass.md` workflow
  developed for TemporalHazard 1.0.3.
- Corrected four factual claims surfaced by review: the dashed-threshold
  recommendation in the SAS migration guide
  ([`geom_hline()`](https://ggplot2.tidyverse.org/reference/geom_abline.html),
  not `annotate("hline")`); the
  [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  font claim (the theme does not enforce a sans-serif face); the
  `theme(legend.position = "none")` layout-space claim (no space is
  reserved); and the
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  “no title” claim (the theme does not blank `plot.title`).

## hvtiPlotR 2.3.1

### Documentation ([\#69](https://github.com/ehrlinger/hvtiPlotR/issues/69))

- Package-wide voice rewrite of every prose surface — README, vignettes,
  NEWS, slide deck, roxygen, DESCRIPTION `Title:` — against the
  `writing-voice.md` spec. Prose only; no API or behavioural change.
- Fixed stale `hv_theme()` string-key references (`"dark_ppt"`, `"ppt"`,
  `"light_ppt"`, `"manuscript"`, `"poster"`) in the main tutorial and
  SAS-migration vignettes. That dispatcher was removed in 2.1.0; the
  vignettes now name the actual `theme_hv_*()` functions.
- Fixed missing “to” in the main tutorial’s introduction (“is simplify”
  → “is to simplify”).
- README now lists all five vignettes (`sas-migration-guide` was
  missing) and the “Migrating from plot.sas” section points at the
  dedicated migration vignette.
- Synced a copy of `writing-voice.md` into the repo root for future
  documentation work.

## hvtiPlotR 2.3.0

### CONSORT patient flow tracking and diagram ([\#67](https://github.com/ehrlinger/hvtiPlotR/issues/67))

Two-class API for CONSORT flow diagrams built from patient-level data.

**Tracker lifecycle:**

- `hv_consort_start(data, patient_id, label, pass_col)` — initialises a
  tracker with one row per patient; all patients begin as screened.
- `hv_consort_exclude(tracker, label, col, ..., excl_label, pass_col)` —
  adds an exclusion stage via formula rules
  (`condition ~ "Reason string"`). First-matching formula wins; gating
  on the prior stage is automatic.
- `hv_consort_summary(tracker)` — returns a data frame with N included
  and N excluded per stage; suitable for methods-section tables.
- `hv_consort_patients(tracker, stage, reason)` — returns patient IDs at
  any stage, or the subset excluded for a specific reason.

**Diagram:**

- `hv_consort(tracker, side_box, cex, width, height)` — auto-derives
  `orders` and `side_box` from tracker metadata and calls
  [`consort::consort_plot()`](https://rdrr.io/pkg/consort/man/consort_plot.html).
  `side_box = "all"` (default) includes every exclusion column; pass a
  character vector to select specific columns.
- `plot.hv_consort(x)` — renders the diagram via the `consort` plot
  method.
- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  now accepts `hv_consort` objects, producing an editable DrawingML
  vector object in the output `.pptx`.

**Sample data:**

- `sample_consort_data(n, seed)` — reproducible three-stage cardiac
  surgery tracker for demos and testing.

**Dependency:** `consort (>= 0.2.0)` added to `Imports`.

### Documentation

- New worked **CONSORT Patient Flow Diagram** section in the *Plot
  Functions* vignette, covering the tracker workflow, the rendered
  diagram, the audit helpers, and
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  export ([\#68](https://github.com/ehrlinger/hvtiPlotR/issues/68)).
- New “What’s New in v2.x” slide deck shipped as Quarto source at
  `inst/slides/hvtiPlotR-whats-new.qmd` — an onboarding overview of the
  v2.x API redesign, theme rename, and PowerPoint export, with a README
  “Slides” section pointing to it
  ([\#67](https://github.com/ehrlinger/hvtiPlotR/issues/67)).

## hvtiPlotR 2.2.0

### New S3 methods for `hv_data` objects ([\#64](https://github.com/ehrlinger/hvtiPlotR/issues/64))

Three standard-R S3 verbs are now implemented for every `hv_data`
subclass:

- **[`summary()`](https://rdrr.io/r/base/summary.html)** — prints the
  standard one-screen header, then walks the object’s `$tables` slot and
  prints each named auxiliary table with a header. Callers get risk
  tables, report tables, and diagnostics without reaching for `$tables`
  directly. Subclasses can override with a curated layout.
- **[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)**
  — re-exports ggplot2’s
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  generic and dispatches to the registered `plot.<subclass>()` method.
  Callers who prefer the ggplot2-ecosystem verb (`broom`, `ggfortify`,
  and `ggsurvfit` all use it) can write `autoplot(km)` in place of
  `plot(km)`. Extra args forward to the subclass
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).
- **[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)** —
  returns the `$data` slot via standard
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  coercion instead of the `$data` accessor.

No breaking changes.

### UpSet plot backend swap ([\#62](https://github.com/ehrlinger/hvtiPlotR/issues/62))

[`plot.hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_upset.md)
is now backed by [`ggupset`](https://cran.r-project.org/package=ggupset)
rather than `ComplexUpset`. The intersection-size bar chart is a
standard ggplot; themes apply via `+`, and
[`ggplot2::ggplot_build()`](https://ggplot2.tidyverse.org/reference/ggplot_build.html)
works on the output. When `set_size = TRUE` (the default) a manual
set-size sidebar is composed via `patchwork`.

**Breaking changes:**

- The `base_annotations` parameter has been removed. To recolour the
  intersection bars by an external grouping variable, pass
  `fill_col = "<column>"` to
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html); for a single
  fixed colour pass `bar_fill = "<colour>"`.
- The `min_size` parameter has been replaced by `n_intersections` (top-N
  by frequency or degree — see `sort_by`). ComplexUpset’s size-threshold
  semantics are not preserved.
- `encode_sets` and `sort_intersections` parameters have been removed
  (the new equivalents are `sort_by` and `set_size_sort`).
- Themes now apply via `+`, not `&`. `&` still works on the patchwork
  composite when `set_size = TRUE`.

**Other changes:**

- The `ComplexUpset` Import has been dropped; `ggupset (>= 0.4.0)` is
  added in its place. `patchwork` has been promoted from Suggests to
  Imports.
- [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md)
  adds a `.Procedures` list-column to its stored `$data` for
  `scale_x_upset()` to consume.
- The four `upset_*` vignette chunks no longer carry a Windows skip
  gate; ggupset renders cleanly on every CI runner.
- `tests/testthat/test_example_plot_data.R` and
  `tests/testthat/test_plot_integration.R` drop their
  `tryCatch / skip_if_theme_incompatibility` wrappers — the upset output
  now passes `expect_plot_has_data()` like every other plot.

## hvtiPlotR 2.1.0

### Theme API redesign

- The four theme functions are now named
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  and
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  matching ggplot2’s
  [`theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html) /
  [`theme_grey()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  naming.

- Each theme follows the
  [`theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  contract: pass `base_size` / `base_family` to control typography, then
  forward any extra named theme element through `...` to override.
  Examples:

  ``` r

  theme_hv_manuscript(legend.position = "right")
  theme_hv_ppt_dark(axis.text.y = element_text(family = "mono"))
  ```

- The `hv_theme()` dispatcher has been **removed**. Call the named theme
  function directly.

- The `bold = TRUE`, `mono_y = TRUE`, and `title_size` kwargs on the PPT
  themes have been **removed**. Express the equivalent overrides through
  `...` (e.g. `axis.text = element_text(face = "bold")` or
  `axis.text.y = element_text(family = "mono")`).

- The previous names
  ([`hv_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`hv_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`hv_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`hv_theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md))
  remain as **deprecated aliases** that emit a one-shot deprecation
  warning and forward to the new theme function. Plan to remove in
  v3.0.0.

### Tests

- Added `tests/testthat/helper-plot-data.R` and
  `tests/testthat/test_example_plot_data.R`. Every `@examples` and
  vignette plot path is exercised through
  [`ggplot2::ggplot_build()`](https://ggplot2.tidyverse.org/reference/ggplot_build.html),
  asserting that non-decorator layers carry observation rows, expected
  geoms appear, and grouped/stratified plots preserve their groups.
  Catches the “plot rendered but contains no data” defect without a
  graphics device.

## hvtiPlotR 2.0.1

### Bug fixes

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md):
  the
  [`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html)
  call that places each plot on its slide now uses `bg = "transparent"`
  so the placeholder rectangle’s fill no longer shows up as an opaque
  white box behind the plot on dark PowerPoint templates. Previously,
  officer’s default ph_location shape had a white fill; against a
  blue-gradient slide template that appeared as a visible white
  rectangle larger than the ggplot panel. The ggplot itself is
  unchanged; only the containing shape’s fill is now transparent so the
  slide template background shows through any area outside the panel.
- [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
  panel background is now `fill = "transparent"` (was `"white"`). Saving
  a `light_ppt`-themed plot into a dark PowerPoint template previously
  showed as an opaque white rectangle inside the panel; with a
  transparent fill the slide template shows through. Add
  `+ theme(panel.background = element_rect(fill = "white"))` if you
  specifically need an opaque white panel.

### Documentation

- Package-level help topic
  ([`?hvtiPlotR`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md))
  rewritten to cover the v2.0.0 feature set: two-step workflow with
  runnable example, fixed-panel geometry subsection
  ([`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md)/[`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)/`save_ppt(panel_box=)`),
  legacy single-call API, `hv_data` class introspection, scope and
  versioning, vignette index.
- README “Utilities” table now lists
  [`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md)
  and
  [`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md),
  and documents `save_ppt(panel_box=)`.
- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  example rewritten to show the recommended `hv_theme("light_ppt")`
  preview workflow saving into a dark PPT template with
  `panel_box = list(width = 8.88, height = 4.51, left = 2.58, top = 1.29)`
  and a
  `scale_x_continuous(breaks = seq(0, 400, 100), expand = c(0, 0))`
  decorator.
- `hvtiPlotR.qmd` colour-guidance section updated to reflect that
  ColorBrewer palettes are accessed via ggplot2’s built-in
  [`scale_colour_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html)
  rather than a direct `RColorBrewer` dependency.

## hvtiPlotR 2.0.0

First stable release of the `hv_*` API. This consolidates the
`2.0.0.9001`–`2.0.0.9013` dev cycle into a tagged release that internal
users can anchor against for bug reports and reproducibility. Subsequent
releases will advance the semantic version (`2.0.1`, `2.1.0`, `3.0.0`)
directly; no `.9xxx` pre-release suffixes.

### New features — fixed-panel geometry

The dominant theme of this release is making the **panel content area**
(the rectangular data region, excluding axes/titles/legend/margins)
directly addressable, so figures stay visually aligned across output
devices and across slides in a deck even when axis-label widths differ.

- `hv_ggsave_dims(plot, width, height, units = "in")`: compute
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  `width`/`height` that preserve a fixed panel content area regardless
  of surrounding chrome. Returns a named list shaped to splat into
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
  so every slide anchors the panel at the given rectangle; on dark PPT
  themes where the panel fill is visible, the panel no longer shifts
  between slides. When `panel_box = NULL` (default), the fixed
  `width`/`height`/`left`/`top` arguments are used (legacy behavior).

### New features — PPT theme polish

- `hv_theme_dark_ppt(bold = TRUE)` and
  `hv_theme_light_ppt(bold = TRUE)`: apply `face = "bold"` to axis text
  and axis titles.

### Behaviour changes — PPT themes

- [`hv_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  and
  [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
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
  - [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
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
    `mh$meta$group_labels[1]` / `[2]`, so the annotations track the
    labels supplied to the constructor.

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
  - `hvti_theme()` → `hv_theme()`
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
  tags; the help system and pkgdown reference both show bi-directional
  “See also” links between each constructor and its plot method.
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

| New constructor | Removed function(s) |
|----|----|
| [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md) | `mirror_histogram()` |
| [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md) | `covariate_balance()` |
| [`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md) | `stacked_histogram()` |
| [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md) | `survival_curve()` |
| [`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md) | `nonparametric_curve_plot()` |
| [`hv_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md) | `nonparametric_ordinal_plot()` |
| [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md) | `goodness_followup()` + `goodness_event_plot()` |
| [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md) | `trends_plot()` |
| [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md) | `spaghetti_plot()` |
| [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md) | `longitudinal_counts_plot()` + `longitudinal_counts_table()` |
| [`hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md) | `alluvial_plot()` |
| [`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md) | `cluster_sankey_plot()` |
| [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md) | `eda_plot()` |
| [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md) | `upset_plot()` |

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
- Added `@examples` to all five theme functions: `hv_theme()`,
  [`hv_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`hv_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  and
  [`hv_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).
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
  `size =`) and updated
  [`remotes::install_github()`](https://remotes.r-lib.org/reference/install_github.html)
  (replacing
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
  messages use consistent wording across all entry points.

### Code quality

- Named all simulation tuning constants in
  [`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md)
  and the internal helper `.np_sample_bins()`: `eta_intercept`,
  `logit_shift`, `cont_baseline`, `cont_scale`, `cont_sigma`,
  `eff_frac_prob`, `eff_frac_cont`. Magic numbers replaced throughout
  the single-curve, multi-group, and binned-data-summary code paths.
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
- Added `hv_theme()` dispatcher for `"manuscript"`, `"ppt"`,
  `"dark_ppt"`, and `"poster"` themes.
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
