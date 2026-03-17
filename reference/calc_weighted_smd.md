# Calculate Weighted Standardized Mean Difference (SMD)

Computes the weighted SMD between two groups using IPTW weights. Uses
weighted means and weighted variances (frequency-weight convention).

## Usage

``` r
calc_weighted_smd(score, weights, group, group_levels)
```

## Arguments

- score:

  Numeric vector of scores.

- weights:

  Numeric vector of non-negative weights (same length as score).

- group:

  Vector indicating group membership (same length as score).

- group_levels:

  Length-2 vector specifying the two group values to compare.

## Value

Numeric value of the weighted SMD, or NA if not computable.
