# Plot Mirrored Propensity Score Histogram

Generates mirrored propensity score histograms for two treatment groups,
highlighting the distribution before and after matching. The returned
list contains the rendered plot, the filtered data used to draw it, and
a set of diagnostics (group counts, SMD values, summary statistics) that
can be logged or displayed in reports.

## Usage

``` r
plot_mirror_histogram(
  data,
  score_col = "prob_t",
  group_col = "tavr",
  match_col = "match",
  group_levels = c(0, 1),
  group_labels = c("SAVR", "TF-TAVR"),
  matched_value = 1,
  score_multiplier = HVTI_SCORE_DEFAULT_MULTIPLIER,
  binwidth = 5,
  output_file = NULL,
  width = 8,
  height = 6
)
```

## Arguments

- data:

  A data frame containing at least the score, group, and match
  indicators.

- score_col:

  Column name holding the numeric propensity score.

- group_col:

  Column name identifying the grouping/treatment indicator.

- match_col:

  Column name indicating whether an observation is matched.

- group_levels:

  Length-2 vector giving the values in \`group_col\` that should be
  plotted (order determines the panel orientation).

- group_labels:

  Length-2 character vector supplying human readable labels for each
  group.

- matched_value:

  Value in \`match_col\` that denotes a matched observation.

- score_multiplier:

  Multiplier applied to \`score_col\` prior to plotting (defaults to
  percentages).

- binwidth:

  Bin width, on the scaled score scale, used when computing the
  histograms.

- output_file:

  Optional file path for saving the figure via \`ggsave()\`.

- width, height:

  Dimensions (inches) used when saving \`output_file\`.

## Value

A list with elements \`plot\` (ggplot object), \`diagnostics\` (list of
summary statistics), and \`data\` (the filtered data frame that was
plotted).

## Examples

``` r
# Create a sample data set
mirror_dta <- sample_mirror_histogram_data(n = 4000)

# Generate the figure
mhist <- plot_mirror_histogram(mirror_dta )

# The plot is returned in a list.
mhist$p


# Diagnostics are also returned, which can be logged or displayed in reports.
mhist$diagnostics
#> $n_input
#> [1] 8000
#> 
#> $n_analyzed
#> [1] 8000
#> 
#> $n_dropped_missing_or_other_group
#> [1] 0
#> 
#> $group_counts_before
#> 
#>    0    1 
#> 4000 4000 
#> 
#> $group_counts_matched
#> 
#>    0    1 
#> 2438 2359 
#> 
#> $matched_rate_by_group
#>       0       1 
#> 0.60950 0.58975 
#> 
#> $score_summary_before
#> working$group: 0
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   0.506  16.432  26.597  28.661  38.997  89.089 
#> ------------------------------------------------------------ 
#> working$group: 1
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   5.868  60.964  73.585  71.312  84.054  99.760 
#> 
#> $score_summary_matched
#> working$group[matched_idx]: 0
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   0.506  16.516  26.585  28.827  39.346  83.929 
#> ------------------------------------------------------------ 
#> working$group[matched_idx]: 1
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   5.868  60.922  73.683  71.229  83.943  99.760 
#> 
#> $smd_before
#> [1] 2.648481
#> 
#> $smd_matched
#> [1] 2.605724
#> 

# The data used to draw the figure is also returned, which can be useful for
# debugging or further analysis.
head(mhist$data)
#>   score_raw group matched    score
#> 1 0.1855938     0       0 18.55938
#> 2 0.2414701     0       1 24.14701
#> 3 0.6889674     0       1 68.89674
#> 4 0.3001684     0       1 30.01684
#> 5 0.3125460     0       0 31.25460
#> 6 0.3879990     0       1 38.79990

# By default, the figure uses the manuscript theme, but you can set it to
# any hvtiPlotR theme you like. For example:
ggplot2::set_theme(hvti_theme("manuscript"))
mhist$p


# You can modify the figure using scales:
mhist$p +
  ggplot2::scale_fill_manual(
    values = c(
      before_g0 = "white",
      matched_g0 = "green1",
      before_g1 = "white",
      matched_g1 = "green4"),
    guide = "none")
#> Scale for fill is already present.
#> Adding another scale for fill, which will replace the existing scale.

 
 # and annotations:
group_labels = c("SAVR", "TF-TAVR")
mhist$p +
  ggplot2::scale_fill_manual(
    values = c(
      before_g0 = "white",
      matched_g0 = "green1",
      before_g1 = "white",
      matched_g1 = "green4"),
    guide = "none")+
  ggplot2::annotate(
    "text",
    x = 0.8,
    y = 0.80,
    label = group_labels[1],
    size = 6
  ) +
  ggplot2::annotate(
    "text",
    x = 0.8,
    y = -0.80,
    label = group_labels[2],
    size = 6
  )
#> Scale for fill is already present.
#> Adding another scale for fill, which will replace the existing scale.

```
