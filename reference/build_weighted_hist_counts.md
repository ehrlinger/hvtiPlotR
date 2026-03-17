# Build Weighted Histogram Counts

Computes per-bin sums of `weights` for use in IPTW mirrored histograms.

## Usage

``` r
build_weighted_hist_counts(x, weights, breaks)
```

## Arguments

- x:

  Numeric vector of propensity scores (already scaled).

- weights:

  Numeric vector of non-negative weights (same length as `x`).

- breaks:

  Numeric vector of break points for bins.

## Value

Data frame with columns \`x\` (bin midpoints) and \`count\` (weight sums
per bin).
