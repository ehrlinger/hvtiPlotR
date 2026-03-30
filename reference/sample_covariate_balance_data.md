# Generate Sample Covariate Balance Data

Produces a reproducible long-format data frame suitable for testing and
demonstrating
[`hvti_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_balance.md).
Rather than drawing SMDs from independent normals, this generator
simulates patient-level covariates through a logistic propensity score
model, computes group standardized mean differences before matching,
then performs greedy 1:1 nearest-neighbour caliper matching and computes
residual differences in the matched cohort.

## Usage

``` r
sample_covariate_balance_data(
  n_vars = 12,
  n = 600,
  separation = 1.5,
  caliper = 0.05,
  group_levels = c("Before match", "After match"),
  seed = 42L
)
```

## Arguments

- n_vars:

  Integer. Number of covariates to generate. Default `12`.

- n:

  Integer. Total number of simulated patients before matching. Default
  `600` (roughly 300 per group at `separation = 1.5`).

- separation:

  Numeric. Distance between the two group means on the log-odds scale.
  Larger values push propensity score distributions further apart,
  increasing the proportion of unmatched extreme-score patients and
  residual imbalance after matching. Default `1.5`.

- caliper:

  Matching caliper expressed in propensity-score units (0–1 scale).
  Patients without a partner within this distance are left unmatched.
  Default `0.05`.

- group_levels:

  Length-2 character vector of group labels. Default
  `c("Before match", "After match")`.

- seed:

  Integer random seed for reproducibility. Default `42`.

## Value

A data frame with `2 * n_vars` rows and columns `variable`, `group`, and
`std_diff` (standardized mean difference as a percentage).

## Details

The result captures the pattern seen in real studies: covariates that
drive treatment selection show large imbalance before matching; matching
substantially reduces imbalance, but patients at the propensity score
extremes cannot be matched, leaving small residual differences for the
strongest confounders.

## Examples

``` r
dta <- sample_covariate_balance_data()
head(dta)
#>            variable        group std_diff
#> 1               Age Before match      9.8
#> 2        Female sex Before match     25.4
#> 3      Hypertension Before match    -14.7
#> 4 Diabetes mellitus Before match     -8.9
#> 5              COPD Before match     -3.9
#> 6        Creatinine Before match     26.5

# Higher separation -> more unmatched extremes -> more residual imbalance
dta2 <- sample_covariate_balance_data(
  n_vars       = 8,
  separation   = 2.0,
  group_levels = c("Unweighted", "IPTW weighted")
)
```
