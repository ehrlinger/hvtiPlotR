# Generate Sample Survival Data

Simulates exponential survival times with administrative censoring at
`study_years`. The default `hazard_rate = 0.05` yields roughly 63\\

## Usage

``` r
sample_survival_data(
  n = 500,
  hazard_rate = 0.05,
  strata_levels = NULL,
  hazard_ratios = NULL,
  study_years = 20,
  seed = 42
)
```

## Arguments

- n:

  Number of observations. Must be a positive integer. Defaults to `500`.

- hazard_rate:

  Base annual hazard rate (exponential distribution parameter). Defaults
  to `0.05`.

- strata_levels:

  Optional character vector of stratum labels (e.g.
  `c("Type A", "Type B")`). When `NULL` (the default) a single
  unstratified cohort is generated.

- hazard_ratios:

  Numeric vector of hazard multipliers — one per element of
  `strata_levels` — relative to `hazard_rate`. Defaults to all 1 (equal
  hazard across strata). Ignored when `strata_levels` is `NULL`.

- study_years:

  Length of administrative follow-up in years. Subjects event-free
  beyond this point are censored. Defaults to `20`.

- seed:

  Integer random seed for reproducibility. Defaults to `42`.

## Value

A data frame with columns:

- `iv_dead`:

  Follow-up time in years (numeric), truncated at `study_years`.

- `dead`:

  Logical event indicator; `TRUE` if the subject experienced the event
  before administrative censoring.

- `iv_opyrs`:

  Operation year offset — uniform over `[1990, 1990 + study_years]`.

- `age_at_op`:

  Age at operation (years); drawn from \\N(65, 10)\\, capped to
  `[30, 90]`.

- `valve_type`:

  (Only when `strata_levels` is not `NULL`) Character stratum label.

## Examples

``` r
# Unstratified
dta <- sample_survival_data(n = 500, seed = 42)
head(dta)
#>     iv_dead  dead iv_opyrs age_at_op
#> 1  3.966736  TRUE 2003.503  58.08251
#> 2 13.217905  TRUE 2008.716  65.37466
#> 3  5.669821  TRUE 1990.072  58.80676
#> 4  0.763838  TRUE 2005.739  66.45205
#> 5  9.463533  TRUE 2006.139  75.84440
#> 6 20.000000 FALSE 1991.461  60.21944

# Stratified with differential hazard
dta_s <- sample_survival_data(
  n             = 500,
  strata_levels = c("Type A", "Type B"),
  hazard_ratios = c(1, 1.4),
  seed          = 42
)
table(dta_s$valve_type)
#> 
#> Type A Type B 
#>    250    250 
```
