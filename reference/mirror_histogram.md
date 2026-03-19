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
  alpha = 0.8,
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

  Column name of the binary match indicator. Default `"match"`. Required
  in binary-match mode; ignored when `weight_col` is supplied.

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

- alpha:

  Transparency of the histogram bars, in \[0, 1\]. Default `0.8`.

- output_file:

  Optional file path; when provided the plot is saved via
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

- width, height:

  Dimensions (inches) when saving `output_file`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. Diagnostics are printed as a message and attached as
`attr(p, "diagnostics")`. Working data attached as `attr(p, "data")`.
Binary-match diagnostics include `smd_matched`; weighted diagnostics
include `smd_weighted` and `effective_n_by_group`.

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
# separation = 1.5 leaves many high/low-score patients unmatched at tails
mirror_dta <- sample_mirror_histogram_data(n = 500, separation = 1.5)
mhist <- mirror_histogram(mirror_dta, alpha = 0.8)
#> mirror_histogram diagnostics:
#> $n_input
#> [1] 1000
#> 
#> $n_analyzed
#> [1] 1000
#> 
#> $n_dropped_missing_or_other_group
#> [1] 0
#> 
#> $group_counts_before
#> 
#>   0   1 
#> 500 500 
#> 
#> $score_summary_before
#> working$group: 0
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   2.313  19.614  31.260  34.205  47.144  90.167 
#> ------------------------------------------------------------ 
#> working$group: 1
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   6.775  51.385  67.926  64.596  81.283  98.587 
#> 
#> $smd_before
#> [1] 1.565275
#> 
#> $group_counts_matched
#> 
#>   0   1 
#> 230 230 
#> 
#> $matched_rate_by_group
#>    0    1 
#> 0.46 0.46 
#> 
#> $score_summary_matched
#> working$group[matched_idx]: 0
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   6.904  38.323  48.337  48.565  61.152  90.167 
#> ------------------------------------------------------------ 
#> working$group[matched_idx]: 1
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   6.775  38.321  48.425  48.872  61.136  89.236 
#> 
#> $smd_matched
#> [1] 0.01837958
attr(mhist, "diagnostics")$smd_before
#> [1] 1.565275
attr(mhist, "diagnostics")$smd_matched
#> [1] 0.01837958

# Customise fill colours and apply manuscript theme
mhist +
  ggplot2::scale_fill_manual(
    values = c(before_g0 = "white",  matched_g0 = "steelblue",
               before_g1 = "white",  matched_g1 = "firebrick"),
    guide = "none"
  ) +
  ggplot2::labs(x = "Propensity Score", y = "Count") +
  hvti_theme("manuscript")


# --- Weighted IPTW mode --------------------------------------------------
wt_dta <- sample_mirror_histogram_data(n = 500, add_weights = TRUE)
mhist_wt <- mirror_histogram(wt_dta, weight_col = "mt_wt", alpha = 0.8)
#> mirror_histogram diagnostics:
#> $n_input
#> [1] 1000
#> 
#> $n_analyzed
#> [1] 1000
#> 
#> $n_dropped_missing_or_other_group
#> [1] 0
#> 
#> $group_counts_before
#> 
#>   0   1 
#> 500 500 
#> 
#> $score_summary_before
#> working$group: 0
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   2.313  19.614  31.260  34.205  47.144  90.167 
#> ------------------------------------------------------------ 
#> working$group: 1
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   6.775  51.385  67.926  64.596  81.283  98.587 
#> 
#> $smd_before
#> [1] 1.565275
#> 
#> $effective_n_by_group
#>   0   1 
#> 500 500 
#> 
#> $smd_weighted
#> [1] 0.5445719
attr(mhist_wt, "diagnostics")$smd_weighted
#> [1] 0.5445719
attr(mhist_wt, "diagnostics")$effective_n_by_group
#>   0   1 
#> 500 500 

# Customise fill colours for weighted mode and apply manuscript theme
mhist_wt +
  ggplot2::scale_fill_manual(
    values = c(before_g0 = "white", weighted_g0 = "blue",
               before_g1 = "white", weighted_g1 = "red"),
    guide = "none"
  ) +
  ggplot2::labs(x = "Propensity Score", y = "Weighted Count") +
  hvti_theme("manuscript")

```
