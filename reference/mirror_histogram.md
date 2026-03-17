# Plot Mirrored Propensity Score Histogram

Generates mirrored propensity score histograms for two treatment groups.
Supports two display modes selected by the arguments supplied:

## Usage

``` r
mirror_histogram(
  data,
  score_col = "prob_t",
  group_col = "tavr",
  match_col = "match",
  group_levels = c(0, 1),
  group_labels = c("SAVR", "TF-TAVR"),
  matched_value = 1,
  score_multiplier = HVTI_SCORE_DEFAULT_MULTIPLIER,
  binwidth = 5,
  weight_col = NULL,
  output_file = NULL,
  width = 8,
  height = 6
)
```

## Arguments

- data:

  A data frame containing at least the score and group columns, plus
  either `match_col` or `weight_col`.

- score_col:

  Column name holding the numeric propensity score.

- group_col:

  Column name identifying the grouping/treatment indicator.

- match_col:

  Column name of the binary match indicator. Required in binary-match
  mode; ignored when `weight_col` is supplied.

- group_levels:

  Length-2 vector giving the values in `group_col` to plot (order
  determines panel orientation).

- group_labels:

  Length-2 character vector of human-readable group labels.

- matched_value:

  Value in `match_col` that denotes a matched observation (binary-match
  mode only).

- score_multiplier:

  Multiplier applied to `score_col` before plotting (default scales raw
  probabilities to percentages).

- binwidth:

  Bin width on the scaled score scale.

- weight_col:

  Optional column name holding IPTW weights. When supplied the function
  operates in weighted mode: "Before" bars show raw counts, "Weighted"
  bars show per-bin weight sums, and `match_col` is not required. The
  column must be numeric and non-negative.

- output_file:

  Optional file path; when provided the plot is saved via
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

- width, height:

  Dimensions (inches) when saving `output_file`.

## Value

A list with elements `plot` (ggplot object), `diagnostics`
(mode-dependent summary statistics), and `data` (filtered working data
frame). Binary-match diagnostics include `smd_matched`; weighted
diagnostics include `smd_weighted` and `effective_n_by_group`.

## Details

- Binary-match mode:

  Supply `match_col`. Upper bars show all observations (before
  matching); overlaid bars show the matched subset. Fill keys:
  `before_g0`, `matched_g0`, `before_g1`, `matched_g1`.

- Weighted IPTW mode:

  Supply `weight_col`. Upper bars show raw counts (before weighting);
  overlaid bars show per-bin weight sums. `match_col` is ignored. Fill
  keys: `before_g0`, `weighted_g0`, `before_g1`, `weighted_g1`.

## Examples

``` r
# --- Binary-match mode ---------------------------------------------------
mirror_dta <- sample_mirror_histogram_data(n = 4000)
mhist <- mirror_histogram(mirror_dta)
mhist$plot

mhist$diagnostics$smd_before
#> [1] 2.648481
mhist$diagnostics$smd_matched
#> [1] 2.605724

# Customise fill colours
mhist$plot +
  ggplot2::scale_fill_manual(
    values = c(before_g0 = "white",  matched_g0 = "steelblue",
               before_g1 = "white",  matched_g1 = "firebrick"),
    guide = "none"
  )


# --- Weighted IPTW mode --------------------------------------------------
wt_dta <- sample_mirror_histogram_data(n = 500, add_weights = TRUE)
mhist_wt <- mirror_histogram(wt_dta, weight_col = "mt_wt")
mhist_wt$plot

mhist_wt$diagnostics$smd_weighted
#> [1] 2.67934
mhist_wt$diagnostics$effective_n_by_group
#>        0        1 
#> 460.7773 493.7646 

# Customise fill colours for weighted mode
mhist_wt$plot +
  ggplot2::scale_fill_manual(
    values = c(before_g0 = "white", weighted_g0 = "blue",
               before_g1 = "white", weighted_g1 = "red"),
    guide = "none"
  )

```
