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
