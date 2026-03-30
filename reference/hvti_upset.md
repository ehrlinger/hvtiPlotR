# Prepare UpSet co-occurrence data for plotting

Validates a set-membership data frame, checks all intersect columns are
binary (logical or 0/1 integer), computes per-set counts, and returns an
`hvti_upset` object. Call
[`plot.hvti_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_upset.md)
on the result to obtain the ComplexUpset UpSet diagram. Apply a theme to
all panels with `&`:

    plot(up) & hvti_theme("manuscript")

## Usage

``` r
hvti_upset(data, intersect)
```

## Arguments

- data:

  A data frame. Each set-membership column must be logical or integer
  (0/1).

- intersect:

  Character vector of column names to treat as sets. Must contain at
  least two names that exist in `data`.

## Value

An object of class `c("hvti_upset", "hvti_data")`:

- `$data`:

  The validated input data frame.

- `$meta`:

  Named list: `intersect`, `n_patients`, `n_sets`.

- `$tables`:

  List with one element: `set_counts` — a named integer vector of
  per-set patient counts.

## See also

[`plot.hvti_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_upset.md),
[`sample_upset_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_upset_data.md)

## Examples

``` r
sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
          "TV_Repair", "Aorta", "CABG")
dta <- sample_upset_data(n = 300, seed = 42)
up  <- hvti_upset(dta, intersect = sets)
up   # prints set counts
#> <hvti_upset>
#>   N patients  : 300  (7 sets)
#>   Set counts  :
#>     AV_Replacement       93
#>     AV_Repair            40
#>     MV_Replacement       45
#>     MV_Repair            33
#>     TV_Repair            36
#>     Aorta                37
#>     CABG                 114

if (FALSE) { # \dontrun{
plot(up) & hvti_theme("manuscript")
} # }
```
