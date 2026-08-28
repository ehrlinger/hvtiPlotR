# hv_sankey — Reproduce the Canonical Cluster-Stability Sankey

**Date:** 2026-06-24
**Author:** John Ehrlinger (with Claude)
**Status:** Draft for review
**Repo:** hvtiPlotR (branch `feat/sankey-canonical`)

## Problem

`hv_sankey()` is meant to reproduce the cluster-stability Sankey from the AVSD
SID-morphology analysis (`analyses/avsd_sid_morphology/09-publication-figures.qmd`,
the `pub-sankey-full` chunk; canonical outputs `figE1_sankey_full_k2_k9.pdf` and
`fig1a_sankey_5of7_k2_k7.pdf`). It does not. Three defects, all traced to the
canonical recipe:

1. **Ribbons join unintuitively.** The canonical applies a deliberate
   *hierarchical* node order (`node_order_full <- c("B","F","H","D","I","C","E","G","A")`,
   `_common.R`) to both `node` and `next_node`, so each child cluster sits next
   to its parent and flows stay short and uncrossed. `hv_sankey()` defaults
   `node_levels` to the **first** cluster column's factor levels — an arbitrary
   order — so flows cross and lineage is obscured.

2. **`NA` filler nodes appear.** Same root cause: the first column at k=2 has
   only the coarsest clusters (e.g. `{A, B}`). Defaulting `node_levels` to those
   levels means every finer-k cluster (`C`…`I`) is outside the factor levels and
   is coerced to `NA`, rendering spurious grey "NA" boxes. The canonical reads
   all k columns and orders across their full label set, so no `NA` arises.

3. **Node boxes are too saturated.** The canonical draws labels at `alpha = 0.3`
   (light-tinted fill, black text) and flows at `alpha = 0.5` (`alpha_hlf`).
   `hv_sankey()` uses `alpha = 0.8` for both, producing heavy solid boxes and
   dense ribbons that do not match the publication look.

The engine is **not** the problem: the canonical figure uses the same
`ggsankey` geoms (`geom_sankey`, `geom_sankey_label`) that `hv_sankey()` already
uses. This is a defaults/ordering fix, not a re-implementation.

### Non-goals

- Not replacing `ggsankey`. The flow geometry is correct; we keep the engine.
- Not hard-coding the AVSD-specific palette or the AVSD `node_order_full` as the
  only option. The function stays general; the AVSD figure is reproducible by
  passing its specific `node_colours`/`node_levels`, and the *defaults* are made
  sensible.
- Not building the collapsed "5-of-7 → Z" recode (`collapse_map`). That is an
  analysis-side data transform; the caller supplies already-collapsed columns.
- No alluvial (`hv_alluvial`) changes.

## Approach (agreed: C + styling + NA fix)

Enhance `hv_sankey()` / `plot.hv_sankey()` so the canonical look is the default,
with everything still overridable.

### 1. Auto-derived, lineage-preserving node order (default)

When `node_levels = NULL`, derive an order from the data instead of using the
first column's levels:

1. Take the union of all cluster labels across every `cluster_cols` column
   (this alone eliminates the `NA` defect).
2. For each adjacent column pair `(k, k+1)`, assign each `(k+1)` cluster a
   **parent** = the `k` cluster contributing the plurality of its members
   (from the k→k+1 contingency table).
3. This parent relation across all k defines a forest rooted at the coarsest
   column. Order the finest-column clusters by a depth-first traversal of that
   forest so siblings (clusters sharing a parent) are adjacent — a
   dendrogram-style leaf order that minimizes ribbon crossing.
4. Order each coarser column's clusters by the mean position of their
   finest-column descendants, so the order is consistent top-to-bottom across
   all columns.

The result is a single global `node_levels` vector covering every label, applied
to both `node` and `next_node`. If the caller passes `node_levels` explicitly,
use it verbatim (validated to cover all observed labels; error if any observed
label is missing). On the AVSD data this auto-order should reproduce
`node_order_full` (verification criterion below).

This logic lives in a new internal helper `.derive_node_order(data, cluster_cols)`
in `cluster-sankey-plot.R`, called from `hv_sankey()`.

### 2. Styling defaults aligned to the canonical

In `plot.hv_sankey()`, split the single `alpha` into two arguments with
canonical defaults:

- `flow_alpha = 0.5` — applied to `geom_sankey()` and the dashed `geom_vline()`.
- `label_alpha = 0.3` — applied to `geom_sankey_label()` (the light-tinted box).

Keep `label_size` (default 8) and `label_hjust`. Retain a deprecated `alpha`
argument: if supplied, it sets both (back-compat) with a one-time message
steering callers to the new arguments.

Default palette: when `node_colours = NULL`, map node labels to Set1 in label
order (a stable, distinct default). Document that the exact AVSD figure passes
its own `node_colours` (the `_common.R` `cols` map). Do **not** silently recycle
a too-short palette into ambiguous repeats — if there are more labels than
palette colours, recycle but `warning()` that colours repeat.

### 3. Optional k-group milestone x labels

Add an optional `group_labels` argument to `plot.hv_sankey()`: a named character
vector mapping a `cluster_cols` value to a milestone label (e.g.
`c(C2 = "2 groups", C3 = "3 groups", C6 = "4 groups", C7 = "5 groups")`). When
supplied, the x-axis tick for that column shows `"<col>\n<label>"`; unlisted
columns show the bare column name. When `NULL` (default), bare column names
only — current behaviour. This reproduces the `fig1a` milestone annotations
without the caller hand-editing `scale_x_discrete()`.

## Components / files

| File | Change |
|---|---|
| `R/cluster-sankey-plot.R` | New `.derive_node_order()` helper; `hv_sankey()` default `node_levels` now auto-derived (validates explicit input); `plot.hv_sankey()` gains `flow_alpha`/`label_alpha`/`group_labels`, deprecates `alpha`; default palette in label order with recycle warning |
| `man/*.Rd` | Regenerated via roxygen (`hv_sankey`, `plot.hv_sankey`) |
| `tests/testthat/test_cluster_sankey.R` | New tests (see below) |
| `NEWS.md` | Entry under a new dev version |
| `DESCRIPTION` | Version bump (line 4) |

`.derive_node_order()` is independently testable from a wide cluster data frame
and has one job: data frame + columns → ordered label vector. `hv_sankey()`
keeps its build-object role; `plot.hv_sankey()` keeps its render role.

## Testing

`test_cluster_sankey.R` adds:

1. **No `NA` nodes.** With `sample_cluster_sankey_data()` (9 clusters), the
   `hv_sankey()` long data has no `NA` in `node`/`next_node`, and `node_levels`
   covers all 9 labels. (Locks the regression.)
2. **Lineage order matches canonical.** `.derive_node_order()` on the AVSD merge
   structure (encoded in `sample_cluster_sankey_data()`'s `merge_tree`) returns
   `c("B","F","H","D","I","C","E","G","A")`.
3. **Explicit `node_levels` validated.** Passing a vector missing an observed
   label errors; passing a complete vector is used verbatim.
4. **Styling args plumb through.** `plot()` returns a ggplot; `flow_alpha` /
   `label_alpha` reach the corresponding layers (inspect built layers); the
   deprecated `alpha` still sets both and emits the message.
5. **`group_labels`** produces the `"C2\n2 groups"`-style x labels for listed
   columns and bare labels otherwise.

Run under `if (requireNamespace("ggsankey"))` guards, matching existing tests.

## Verification / success criteria

1. `plot(hv_sankey(clusters_letter))` with the AVSD `node_colours` reproduces
   `figE1_sankey_full_k2_k9.pdf` (same node order, no `NA`, light boxes, soft
   ribbons) on visual comparison.
2. Default (no `node_levels`, no `node_colours`) produces intuitive,
   non-crossing ribbons and zero `NA` nodes on `sample_cluster_sankey_data()`.
3. All `test_cluster_sankey.R` tests pass; `devtools::check()` clean.
4. The `hvti_graphics` book's `sankey.qmd` "Cluster-stability Sankey" figure
   re-renders with the improved default (follow-up, separate from this repo).

## Release implications

hvtiPlotR is internal-only (no CRAN), but the full release gate still applies
per house rule: bump `DESCRIPTION` line 4 **and** `NEWS.md`, run
`R CMD check`/`devtools::check()` to 0/0/0, keep examples runnable under
`requireNamespace("ggsankey")`. Open a PR; **John merges** (do not self-merge).

## Open questions

- Default palette: Set1 in label order is the proposed general default. Confirm
  that is acceptable vs. defaulting to the exact AVSD `cols` map. (Leaning
  general default + document the AVSD override.)
- Tie-breaking when a `(k+1)` cluster's members split evenly between two parents
  (no clear plurality). Default: break ties by the parent appearing earliest in
  the coarser column's derived order; revisit if it produces crossings on real
  data.

## Relationship to the book

After this lands and a new hvtiPlotR is tagged, the `hvti_graphics`
"Cluster-stability Sankey" chapter (`sankey.qmd`) re-renders against it. That is
a separate change in the book repo, not part of this spec.

---

## Additional scope (added 2026-06-24) — `hv_alluvial` clean y-axis + new book example

A second target was added: a clinical patient-flow alluvial (the Impella 5.5
"Fig. 2" — Hospital Admission → Device Placement → Device Removal → Hospital
Discharge, with NO MCS / MCS strata and NHS/HTx/LVAD/Other/Dead outcomes, counts
on the flows, a timeline annotation bar at top, and **no visible y-axis**). No
source code exists for it; it is reverse-engineered. Two deliverables:

### A. `hv_alluvial` — `show_yaxis` option

`plot.hv_alluvial()` currently returns a ggplot whose default continuous y-scale
shows patient counts (examples add `labs(y = "Patients (n)")`). Add an argument:

- `show_yaxis = TRUE` (default — current behaviour). When `FALSE`, strip the
  y-axis: blank `axis.title.y`, `axis.text.y`, `axis.ticks.y`, `axis.line.y`
  (via a `theme()` overlay the function adds), leaving the alluvium/stratum
  geometry untouched. This gives the clean patient-flow look without the caller
  hand-writing the `theme()` calls.

Keep it overridable/composable — the caller can still add their own `theme()`
after. Add a test that `show_yaxis = FALSE` blanks those four y elements and
`TRUE` leaves them. This ships in the same hvtiPlotR change set / release as the
`hv_sankey` work above.

### B. New book example (hvti_graphics, follow-up)

A new worked example reproducing the Impella-style **milestone patient-flow
alluvial**: named milestone axes, categorical state strata, counts on flows,
`show_yaxis = FALSE`. Built on **synthetic data** (no source data/code), via a
`sample_*` generator mimicking the admission→placement→removal→discharge flow.
Likely a new section in `sankey.qmd` (which already houses alluvial + cluster
Sankey) or its own short chapter. The **timeline annotation bar** at top is
treated as optional decorator-level work (annotation layer in the example), not
a core `hv_alluvial` feature, unless we later decide it is reusable.

This book example is a separate change in the `hvti_graphics` repo, after the
hvtiPlotR `show_yaxis` option ships.
