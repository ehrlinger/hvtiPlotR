# Design — `hv_legend_inside()`

**Date:** 2026-06-25
**Status:** Approved (brainstorming), pre-implementation
**Repo:** hvtiPlotR (feature). Book adoption in hvti_graphics is a separate phase 2.

## Motivation

The CORR house figure convention is **in-panel legends placed in dead space**,
never overlapping the data (see the figure-conventions house rules). Today the
book sets this by hand per recipe (`theme(legend.position = c(x, y))`), choosing
a corner by eye. The house themes (`theme_hv_manuscript()` et al.) set
`legend.position = "none"`, so a legend is opt-in and must be positioned
explicitly.

We want a single helper that **places the legend in the emptiest panel corner
automatically**, and **falls back to an outside legend when no corner is clear**
— so dense multi-curve panels (e.g. the stratified Kaplan–Meier / hazard
"Stratified by group" figures) get a clean outside legend without a hand-coded
exception.

ggplot2 has no native legend auto-placement, so this is a post-processing helper
on a built plot, in the same family as `hv_ggsave_dims()` and `hv_ph_location()`
(both inspect a built plot via `ggplot_build()` / `ggplotGrob()`).

## API

```r
hv_legend_inside(plot,
                 threshold = 0.08,
                 box_frac  = 0.30,
                 pad       = 0.02,
                 fallback  = "right")
```

| Arg | Default | Meaning |
|-----|---------|---------|
| `plot` | — | A single-panel `ggplot`. |
| `threshold` | `0.08` | Max fraction of data points allowed in the chosen corner box for an in-panel legend. If the emptiest corner exceeds it, use `fallback`. |
| `box_frac` | `0.30` | Corner-box size as a fraction of panel width and height. |
| `pad` | `0.02` | Inset of the legend anchor from the panel edge (npc units). |
| `fallback` | `"right"` | `legend.position` used when no corner is empty enough, or when the plot can't be reasoned about (facets/patchwork). One of `"right"`, `"left"`, `"top"`, `"bottom"`. |

**Returns:** the input `plot` with a `theme()` layer added that sets
`legend.position` (and, for an in-panel result, `legend.justification`). It is a
pure, composable transform — no side effects.

**Usage / ordering.** Because the house theme sets `legend.position = "none"`,
`hv_legend_inside()` must be applied **after** the theme so its position wins:

```r
p <- plot(km) +
  scale_y_continuous(labels = scales::percent) +
  theme_hv_manuscript()
hv_legend_inside(p)               # added after the theme, so it overrides "none"
```

(The book will wrap the final styled plot in phase 2.)

## Algorithm — corner-box point-count

1. **Build.** `b <- ggplot2::ggplot_build(plot)`.
2. **Panel guard.** If `b` has more than one panel (facets) or `plot` is not a
   single `ggplot` (e.g. a patchwork/gtable composite), skip inspection: emit a
   one-line `message()` and return `plot + theme(legend.position = fallback)`.
3. **Collect points.** From each layer in `b$data`, take rows that expose finite
   `x` and `y`. Lines/steps contribute one point per vertex (a coverage proxy);
   points contribute themselves. Ribbons/cols that expose only `ymin`/`ymax` are
   ignored for v1 (documented limitation). If no usable points remain, return
   `plot + theme(legend.position = fallback)` (nothing to dodge).
4. **Normalize.** Map each point to the unit panel `[0,1] × [0,1]` with
   `b$layout$coord$transform(layer_data, panel_params)`, which returns npc
   coordinates accounting for the coordinate system. This is why `coord_flip`
   works: the layer `data$x/$y` stay in original orientation while
   `panel_params$x.range/$y.range` swap under flip, so a manual
   `data$x ÷ x.range` normalization would mismatch — `coord$transform`
   reconciles both. (Verified empirically against ggplot2 4.0.3.)
5. **Corner occupancy.** Define four corner boxes of size `box_frac` in each
   dimension: top-right, top-left, bottom-right, bottom-left. For each, compute
   the fraction of normalized points inside.
6. **Decide.**
   - `best <- argmin(occupancy)`.
   - If `occupancy[best] <= threshold`: in-panel. Set
     `legend.position = c(x, y)` and `legend.justification` to the matching
     corner, inset by `pad` (e.g. top-right → `position = c(1 - pad, 1 - pad)`,
     `justification = c(1, 1)`).
   - Else: `legend.position = fallback`, no justification.
7. **Return** `plot + theme(...)`.

### Corner anchor table

| Corner | `legend.position` | `legend.justification` |
|--------|-------------------|------------------------|
| top-right | `c(1 - pad, 1 - pad)` | `c(1, 1)` |
| top-left | `c(pad, 1 - pad)` | `c(0, 1)` |
| bottom-right | `c(1 - pad, pad)` | `c(1, 0)` |
| bottom-left | `c(pad, pad)` | `c(0, 0)` |

Ties broken by a fixed corner preference order: top-right, top-left,
bottom-right, bottom-left (deterministic, testable).

## Edge cases & decisions

- **Facets / patchwork:** cannot reason per-panel → `fallback` + `message()`.
- **No legend in the plot:** setting `legend.position` is a visual no-op; silent.
- **Dense panel (stratified curves):** every corner above `threshold` → `"right"`.
  This is the intended automatic "6.6.1 exception."
- **`coord_flip` / transformed scales:** handled because points are read in built
  coordinates.
- **Argument validation:** reuse `.check_scalar_positive()` for `box_frac`/`pad`;
  validate `threshold` in `[0, 1]`, `box_frac` in `(0, 0.5]`, and `fallback` via
  `match.arg`. `plot` must be a `ggplot`.

## Out of scope (YAGNI)

- Legend-grob-sized corner boxes (more precise sizing) — fixed `box_frac` is
  enough for the conservative target.
- Non-corner / arbitrary emptiest-region placement.
- Per-panel placement for facets.
- Ribbon/area occupancy.
- Auto-resizing the legend or its key glyphs.

## Testing strategy

`tests/testthat/test_legend_inside.R`, using small synthetic ggplots so the
geometry is known:

1. **Empty top-right → places top-right.** Points clustered bottom-left; assert
   the returned theme has `legend.position == c(1 - pad, 1 - pad)`,
   `legend.justification == c(1, 1)`.
2. **Each corner.** Four fixtures, one empty corner each; assert the matching
   anchor.
3. **Full panel → fallback.** Points fill all corners; assert
   `legend.position == "right"`.
4. **Custom `fallback`.** Same dense fixture with `fallback = "bottom"` →
   `"bottom"`.
5. **Facets → fallback + message.** `expect_message()` and
   `legend.position == fallback`.
6. **coord_flip** fixture → emptiest corner computed in built coords.
7. **No usable points** (e.g. blank plot) → `fallback`.
8. **Input validation.** Non-ggplot, `box_frac > 0.5`, `threshold > 1`,
   bad `fallback` → informative errors.
9. **Composability.** Result is a ggplot; the added theme overrides a prior
   `theme_hv_manuscript()`'s `"none"`.

Extract `legend.position`/`legend.justification` from the returned object's
`$theme` for assertions (no rendering required), keeping tests fast and
device-independent.

## Package integration

- New file `R/legend-inside.R`; export `hv_legend_inside`.
- Roxygen with `@return`, runnable `@examples` (guarded with
  `if (requireNamespace(...))` only if needed), and the recipes-book `@seealso`
  deep link to `legends.html`, matching the v2.7.0 cross-reference convention.
- `@importFrom ggplot2 ggplot_build theme` (and any helpers actually used).
- `devtools::document()`; add to `_pkgdown.yml` reference index (Saving &
  Utilities, beside `hv_ggsave_dims`).
- Version: patch/minor bump in **both** `DESCRIPTION` and `NEWS.md` (NEWS-grep
  test); add a NEWS entry. Minor bump (`2.8.0`) is justified by a new exported
  function — confirm digit with the maintainer at release time per the
  versioning discipline (do not roll the minor unilaterally).
- Release gate before tagging: `R CMD check --as-cran` **0/0/0** incl. PDF
  manual; full test suite green.

## Phase 2 — book adoption (separate spec/PR, after release)

After `hv_legend_inside()` ships and hvtiPlotR is reinstalled locally:

- Apply it to the multi-series recipes in hvti_graphics that carry a legend,
  replacing hand-coded `theme(legend.position = c(...))` where the helper's
  automatic choice matches, and letting the fallback handle dense panels.
- Verify the stratified survival/hazard ("Stratified by group") figures resolve
  to an outside legend automatically.
- Re-render affected chapters (freeze), one PR.
