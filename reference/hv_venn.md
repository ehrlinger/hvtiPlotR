# Prepare a Venn diagram for plotting

Validates a wide set-membership data frame and returns an `hv_venn`
object carrying a region-count table. Call
[`plot.hv_venn`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_venn.md)
on the result for a bare ggplot2 Venn diagram. `hv_venn()` is the
small-set-count companion to
[`hv_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md),
reading the same input; for more than three sets use
[`hv_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md).

## Usage

``` r
hv_venn(data, sets)
```

## Arguments

- data:

  A data frame; one row per patient. Each set column must be logical or
  0/1 numeric.

- sets:

  Character vector of **2 to 3** column names to draw as sets.

## Value

An object of class `c("hv_venn", "hv_data")`:

- `$data`:

  The input data frame.

- `$meta`:

  Named list: `sets`, `n_patients`, `n_sets`.

- `$tables$regions`:

  A data frame with one logical column per set (the in/out membership
  pattern), a `region` label, and `n` (patients in that exact region).

## See also

Worked recipe with rendered output:
<https://ehrlinger.github.io/hvti_graphics/upset.html>.

[`plot.hv_venn`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_venn.md),
[`hv_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md),
[`sample_upset_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_upset_data.md)

## Examples

``` r
dta <- sample_upset_data(n = 300, seed = 42)
v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
v$tables$regions
#>   AV_Replacement MV_Replacement  CABG                                 region
#> 1           TRUE          FALSE FALSE                    AV_Replacement only
#> 2          FALSE           TRUE FALSE                    MV_Replacement only
#> 3           TRUE           TRUE FALSE        AV_Replacement & MV_Replacement
#> 4          FALSE          FALSE  TRUE                              CABG only
#> 5           TRUE          FALSE  TRUE                  AV_Replacement & CABG
#> 6          FALSE           TRUE  TRUE                  MV_Replacement & CABG
#> 7           TRUE           TRUE  TRUE AV_Replacement & MV_Replacement & CABG
#>     n
#> 1  82
#> 2  42
#> 3   0
#> 4 100
#> 5  11
#> 6   3
#> 7   0
```
