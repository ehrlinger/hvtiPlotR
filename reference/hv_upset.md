# Prepare UpSet co-occurrence data for plotting

Validates a set-membership data frame, checks all intersect columns are
binary (logical or 0/1 integer), computes per-set counts, and returns an
`hv_upset` object. Call
[`plot.hv_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_upset.md)
on the result to obtain the ComplexUpset UpSet diagram. Apply a theme to
all panels with `&`:

    plot(up) & hv_theme("poster")

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

  The validated input data frame.

- `$meta`:

  Named list: `intersect`, `n_patients`, `n_sets`.

- `$tables`:

  List with one element: `set_counts` — a named integer vector of
  per-set patient counts.

## See also

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

# 2 & 3. Bare plot + theme in one step
# ComplexUpset uses & (not +) to apply a theme across all sub-panels.
if (FALSE) { # \dontrun{
p <- plot(up)
p & hv_theme("poster")
} # }
```
