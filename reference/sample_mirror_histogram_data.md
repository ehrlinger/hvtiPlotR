# Generate Sample Data for Mirrored Histogram

Creates a reproducible data frame for testing
[`hvti_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md)
in either binary-match or weighted IPTW mode. Propensity scores are
simulated via a logistic model: control subjects draw their linear
predictor from \\N(-\text{sep}/2, 1)\\ and treated subjects from
\\N(+\text{sep}/2, 1)\\, so the two score distributions overlap in the
centre while accumulating mass at opposite extremes. Patients at those
extremes cannot find a matching partner within the caliper, which
naturally reproduces the "many unmatched at the tails" pattern seen in
real studies.

## Usage

``` r
sample_mirror_histogram_data(
  n = 500,
  separation = 1.5,
  caliper = 0.05,
  seed = 42L,
  add_weights = FALSE
)
```

## Arguments

- n:

  Number of observations **per group** (default 500).

- separation:

  Numeric. Distance between the two group means on the log-odds scale.
  Larger values push the score distributions further apart and increase
  the proportion of unmatched patients at the extremes (default 1.5).

- caliper:

  Matching caliper width expressed in propensity-score units (0–1 scale,
  default 0.05). Treated patients without a control partner within this
  distance are left unmatched.

- seed:

  Integer random seed for reproducibility (default 42L).

- add_weights:

  Logical. When `TRUE` an `mt_wt` column of ATE-style IPTW weights
  derived from the simulated propensity scores is appended and
  normalised to mean 1 within each group (default `FALSE`).

## Value

Data frame with columns:

- `prob_t`:

  Propensity score on the 0–1 scale.

- `tavr`:

  Group indicator (0 = control, 1 = treated).

- `match`:

  Binary match indicator produced by greedy nearest-neighbour matching
  within `caliper` (1 = matched).

- `mt_wt`:

  (Only when `add_weights = TRUE`) ATE IPTW weights normalised to mean 1
  within each group.

## See also

[`hvti_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md)

## Examples

``` r
# Binary-match mode sample data (default)
dta <- sample_mirror_histogram_data(n = 500, separation = 1.5)
head(dta)
#>      prob_t tavr match
#> 1 0.6504365    0     1
#> 2 0.2117017    0     0
#> 3 0.4044706    0     1
#> 4 0.4707491    0     1
#> 5 0.4144179    0     1
#> 6 0.2981497    0     1
table(dta$tavr, dta$match)   # matched vs unmatched counts per group
#>    
#>       0   1
#>   0 270 230
#>   1 270 230

# IPTW weighted mode — adds mt_wt column
dta_wt <- sample_mirror_histogram_data(n = 500, add_weights = TRUE)
head(dta_wt)
#>      prob_t tavr match     mt_wt
#> 1 0.6504365    0     1 1.6479076
#> 2 0.2117017    0     0 0.7307492
#> 3 0.4044706    0     1 0.9672879
#> 4 0.4707491    0     1 1.0884221
#> 5 0.4144179    0     1 0.9837191
#> 6 0.2981497    0     1 0.8207567
tapply(dta_wt$mt_wt, dta_wt$tavr, mean)  # should be ~1 in each group
#> 0 1 
#> 1 1 
```
