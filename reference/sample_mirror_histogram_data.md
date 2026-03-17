# Generate Sample Data for Mirrored Histogram

Creates a reproducible data frame suitable for testing
[`mirror_histogram`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md)
in either binary-match or weighted IPTW mode.

## Usage

``` r
sample_mirror_histogram_data(n = 100, add_weights = FALSE)
```

## Arguments

- n:

  Number of samples per group (default 100).

- add_weights:

  Logical. When `TRUE` an `mt_wt` column of positive IPTW-style weights
  is appended (default `FALSE`).

## Value

Data frame with columns `prob_t`, `tavr`, `match`, and optionally
`mt_wt`.
