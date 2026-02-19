# Calculate Standardized Mean Difference (SMD)

Computes the standardized mean difference between two groups for a given
score.

## Usage

``` r
calc_smd(score, group, group_levels)
```

## Arguments

- score:

  Numeric vector of scores.

- group:

  Vector indicating group membership (same length as score).

- group_levels:

  Length-2 vector specifying the two group values to compare.

## Value

Numeric value of the SMD, or NA/0 if not computable.
