# hv_balance(): direct inputs, pair facets, VR/KS panels, height helper (design)

Issue: [#219](https://github.com/ehrlinger/hvtiPlotR/issues/219). Related: #49.
Branch: `feat/balance-panels`. Delivered as **one PR**.

## Problem

Using `hv_balance()` as the love plot in a two-group matched study and a three-group weighted
study (50 imputations each) forced hand-written code around it in four places:

1. Callers pivot balance tables to long format, multiply by 100 and average imputations themselves.
2. Three or more groups cannot be faceted by pairwise comparison.
3. Only SMD is plotted; exact mean balance can hide distributional imbalance (all SMDs 0, KS 0.22).
4. No figure-height guidance; 38 rows at 12 pt need about 8 in, not 4.

## Facts verified before design (2026-10-14)

- `hvtiRpropensity` 0.2.0: there is **no `$tables$smd`** (the issue's wording). `ps_match()` carries
  `$tables$smd_before` / `smd_after`; `ps_weight()` carries `smd_unweighted` / `smd_weighted`. Each is a
  data frame `variable`, `smd` on the **fraction** scale. SMD only: no variance ratio or KS.
- `cobalt` 5.0.0 `bal.tab()`: `$Balance` has `Diff.Un`, `V.Ratio.Un`, `KS.Un`, `Diff.Adj`,
  `V.Ratio.Adj`, `KS.Adj` (VR and KS present only when requested via `stats`).
  **Binary covariates report a raw difference by default**; `attr(x, "print.options")$binary` is
  `"std"` only when `binary = "std"` was passed. VR is `NA` for binaries.
- Multi-category `bal.tab()` has class `c("bal.tab.multi", "bal.tab")` and `$Pair.Balance`, a list of
  `bal.tab` objects named `"B vs. A"`, `"C vs. A"`, `"C vs. B"`.

## Decisions

| question | decision |
|---|---|
| delivery | one spec, one PR |
| dependencies | `R/` only inspects class and list elements, with no `cobalt::` or `hvtiRpropensity::` calls. Both go in **Suggests** for tests; `ehrlinger/hvtiRpropensity` added to Remotes. |
| `bal.tab` with raw binary differences | **error**, telling the caller to re-run with `binary = "std"` |
| panel layout | one bare ggplot, `facet_grid(pair ~ stat, scales = "free_x")`; VR on a linear axis |

## Data model

`hv_balance()$data` stays long (one row per covariate × group) and gains two columns:

- `stat`: `"smd"`, `"variance_ratio"` or `"ks"`.
- `pair`: comparison label; `NA` for two-group input.

A data frame with no `stat` column is treated as SMD only, so every existing call is unchanged.
`std_diff_col` still names the value column (it now holds VR and KS values too for those rows).
Adding columns is additive; no existing column or `$meta` element is renamed or removed.

### New `hv_balance()` arguments

| argument | default | meaning |
|---|---|---|
| `stat_col` | `NULL` | data-frame input: column holding the stat name |
| `pair_col` | `NULL` | data-frame input: column holding the comparison label |
| `stats` | `"smd"` | panels to build; subset of `c("smd", "variance_ratio", "ks")` |
| `vr_threshold` | `c(0.5, 2)` | dotted reference lines in the VR panel |
| `ks_threshold` | `NULL` | dotted reference line in the KS panel; none by default |
| `group_labels` | `c("Before", "After")` | labels for unadjusted / adjusted when input is `bal.tab` or `ps_*` |

### New `$meta` elements

`stats`, `pairs` (character, length 0 for two groups), `n_imputations` (1 for a single object),
`vr_threshold`, `ks_threshold`, `suggested_height` (inches at `base_size = 12`).

## Input dispatch

Runs first in `hv_balance()`; each branch produces the long data frame, then the existing
validation path runs on it.

- **`bal.tab`**: error unless `print.options$binary == "std"`. `Diff.Un` / `Diff.Adj` → `smd` (× 100),
  `V.Ratio.*` → `variance_ratio`, `KS.*` → `ks` (not scaled). `Un` → `group_labels[1]`,
  `Adj` → `group_labels[2]`. Row names → `variable`.
- **`bal.tab.multi`**: each `Pair.Balance` element handled as above, `pair` = its name.
- **`ps_data` (`ps_match` / `ps_weight`)**: `smd_before`/`smd_after` or `smd_unweighted`/`smd_weighted`
  × 100 → `smd`. Requesting `"variance_ratio"` or `"ks"` errors, naming `bal.tab()` as the source.
- A `bal.tab` group whose `Diff` column is absent or entirely `NA` (no adjustment, or `un = FALSE`)
  is skipped, not drawn empty. Variance-ratio rows for binary covariates are dropped by the adapter:
  the ratio is undefined for them, not missing, so they do not trigger the missing-value warning.
- Adapter input always yields the canonical columns `variable`, `group`, `stat`, `pair`, `std_diff`;
  the `*_col` arguments apply to data-frame input only.
- **List of any one of the above** (one element per imputation): build each, then take the
  **signed mean** per covariate × group × stat × pair. `n_imputations` = list length.
- A list counts as an imputation list only when every element is a `bal.tab` or `ps_data` object;
  a plain list such as `list(variable = ...)` still gets the existing "not a data.frame" error.
- Anything else falls through to the data-frame path; the existing `.check_df()` message is unchanged.

## Plot

`plot.hv_balance()` returns one bare ggplot; existing arguments unchanged.

- **Facets**: `facet_grid(rows = vars(pair), cols = vars(stat), scales = "free_x")`, each dimension
  added only when it has more than one level. A two-group SMD-only object keeps today's geoms
  (`GeomVline`, `GeomHline`, `GeomPoint`), intercepts (0, ±threshold), y breaks and `FacetNull`; the
  reference lines collapse from three `vline` layers to two (one solid, one dotted).
- **Strip labels** via a labeller: "Standardized difference (%)", "Variance ratio", "KS statistic".
- **Reference lines** as `geom_vline(data = <per-stat frame>)` so each lands only in its panel:

  | stat | solid | dotted |
  |---|---|---|
  | smd | 0 | ± `threshold` (10) |
  | variance_ratio | 1 | `vr_threshold` (0.5, 2) |
  | ks | 0 | `ks_threshold` (none) |

- Points (colour and shape mapped to group) and the dashed per-row `geom_hline` guides are unchanged.
- The legend behaviour is unchanged; annotation is left to the caller's decoration, as now.

## Height helper

New export `hv_balance_height(n_rows, base_size = 12, n_pairs = 1)`, returning inches:

```
s * (0.17 * n_rows * n_pairs + 0.3 * (n_pairs - 1) + 1.5),  s = base_size / 12
```

38 rows at 12 pt → 7.96 in, matching the issue's measured 8 in. 0.3 in per extra pair is strip
space; 1.5 in covers the x axis, its title and the legend. `print.hv_balance()` shows
`$meta$suggested_height`. Added to the Propensity section of `_pkgdown.yml`.

## Errors

All `stop(..., call. = FALSE)`, each naming the fix.

- `bal.tab` with `binary != "std"` → re-run `bal.tab()` with `binary = "std"`.
- `stats` requests a stat absent from the input (`ps_*`, or `bal.tab` without `stats = c("m","v","ks")`)
  → names the missing stat and how to obtain it.
- Imputation list empty, mixing classes, or with differing covariate sets.
- Unknown `stats` value (`match.arg(several.ok = TRUE)`).
- `vr_threshold` not positive or length not 1–2; `ks_threshold` not `NULL` and not in [0, 1].
- Data frame: `stats` names a stat with no rows in `stat_col`.
- `NA` values (e.g. VR for binaries) follow the existing missing-data contract: counted in
  `n_missing`, reported by `print()`, not drawn.

## Tests

In `tests/testthat/test_covariate_balance.R`; fixtures in `tests/testthat/helper-balance-fixtures.R`.
Every plot test uses the data-carrying helper in `helper-plot-data.R`. Tests needing `cobalt` or
`hvtiRpropensity` are guarded by `skip_if_not_installed()`.

1. Regression: the current two-group SMD call keeps its geoms, intercepts, y breaks and `FacetNull`;
   all 30 existing tests in the file pass unchanged (there is no balance snapshot).
2. Two-group matched, 38 terms, list of 5 imputations: pooled mean equals a hand computation,
   `n_imputations == 5`, SMD × 100.
3. Three groups via `bal.tab.multi`: three facet rows, pair labels preserved, data in every panel.
4. Exact mean balance with large KS: every SMD ≈ 0 while one KS > 0.2; the KS panel's points carry
   that value and the SMD panel's do not.
5. Reference lines land in the correct facet (`ggplot_build()` panel data).
6. Each error above fires with its message (`expect_error(regexp = )`).
7. `hv_balance_height()`: 38 rows / 12 pt = 7.96; base-size scaling; pair term.

## Housekeeping

- `DESCRIPTION`: `cobalt`, `hvtiRpropensity` in Suggests; `ehrlinger/hvtiRpropensity` in Remotes.
- `devtools::document()`; commit `man/` and `NAMESPACE`.
- `news/feat-balance-panels.md` fragment; no version bump.
- Build the manual locally (`R CMD Rd2pdf`): roxygen gains `\eqn{}`, and `check-manual.yaml` does not gate PRs.
- `lintr::lint_package()` returns zero.

## Out of scope

- Log-scale VR axis (would need patchwork or a transformed column; rejected for the bare-ggplot contract).
- Calling `bal.tab()` from a formula inside `hv_balance()`.
- Changing the default legend behaviour.
