# Prepare UpSet co-occurrence data for plotting

Validates a set-membership data frame, checks all intersect columns are
binary (logical or 0/1 integer), computes per-set counts, and returns an
`hv_upset` object. Call
[`plot.hv_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_upset.md)
on the result to obtain a ggplot2 UpSet diagram (backed by
[`scale_x_upset`](https://rdrr.io/pkg/ggupset/man/scale_x_upset.html)).

## Usage

``` r
hv_upset(data, intersect)
```

## Arguments

- data:

  A data frame. Each set-membership column must be logical or integer
  (0/1).

- intersect:

  Character vector of column names to treat as sets. Must contain at
  least two names that exist in `data`.

## Value

An object of class `c("hv_upset", "hv_data")`:

- `$data`:

  The validated input data frame, plus a `.Procedures` list-column
  derived from the indicator matrix (consumed by `scale_x_upset()`).

- `$meta`:

  Named list: `intersect`, `n_patients`, `n_sets`.

- `$tables`:

  List with one element: `set_counts` – a named integer vector of
  per-set patient counts.

## See also

Worked recipe with rendered output:
<https://ehrlinger.github.io/hvti_graphics/upset.html>.

[`plot.hv_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_upset.md),
[`sample_upset_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_upset_data.md)

## Examples

``` r
sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
          "TV_Repair", "Aorta", "CABG")
dta <- sample_upset_data(n = 300, seed = 42)

# 1. Build data object
up <- hv_upset(dta, intersect = sets)
up  # prints set counts
#> <hv_upset>
#>   N patients  : 300  (7 sets)
#>   Set counts  :
#>     AV_Replacement       93
#>     AV_Repair            40
#>     MV_Replacement       45
#>     MV_Repair            33
#>     TV_Repair            36
#>     Aorta                37
#>     CABG                 114

# 2. Plot. The default (set_size = TRUE) returns a patchwork composite,
# so apply themes with `&` to theme every sub-panel. Use `+` for
# set_size = FALSE (a plain ggplot).
plot(up) & theme_hv_poster()
#> Warning: Removed 30 rows containing non-finite outside the scale range (`stat_count()`).
#> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` instead.
#> ℹ The deprecated feature was likely used in the ggupset package.
#>   Please report the issue at <https://github.com/const-ae/ggupset/issues>.

plot(up, set_size = FALSE) + theme_hv_poster()
#> Warning: Removed 30 rows containing non-finite outside the scale range (`stat_count()`).

```
