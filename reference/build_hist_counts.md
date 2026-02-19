# Build Histogram Counts

Helper function to compute histogram bin midpoints and counts for a
numeric vector.

## Usage

``` r
build_hist_counts(x, breaks)
```

## Arguments

- x:

  Numeric vector to bin.

- breaks:

  Numeric vector of break points for bins.

## Value

Data frame with columns \`x\` (bin midpoints) and \`count\` (counts per
bin).
