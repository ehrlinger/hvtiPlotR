# Suggested figure height for a covariate balance plot

Covariate labels overprint when a balance plot is drawn too short. This
returns a height that leaves about 0.17 in per covariate row at 12 pt,
plus room for the x axis, its title and a legend, scaled by `base_size`.

## Usage

``` r
hv_balance_height(n_rows, base_size = 12, n_pairs = 1)
```

## Arguments

- n_rows:

  Number of covariate rows (`length(var_levels)`).

- base_size:

  Theme base font size in points. Default `12`.

- n_pairs:

  Number of pairwise-comparison facet rows. Default `1`.

## Value

Height in inches, a numeric scalar.

## See also

[`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md),
whose `$meta$suggested_height` holds this value at `base_size = 12`.

## Examples

``` r
hv_balance_height(38)                 # about 8 in
#> [1] 7.96
hv_balance_height(38, base_size = 16)
#> [1] 10.61333
hv_balance_height(12, n_pairs = 3)    # three-group design
#> [1] 8.22
```
