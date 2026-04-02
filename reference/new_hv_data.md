# Construct a validated hv_data object

This is the single internal entry point used by every `hv_*()` function
to create its return value. It enforces the three-slot contract
(`$data`, `$meta`, `$tables`) and attaches the two-level S3 class
vector.

## Usage

``` r
new_hv_data(data, meta, tables = list(), subclass)
```

## Arguments

- data:

  A data frame – the primary tidy data ready for ggplot2.

- meta:

  A named list of metadata (column names, method choices, computed
  statistics, etc.).

- tables:

  A named list of auxiliary objects — typically data frames (risk
  tables, report tables, etc.) but may also contain vectors or other R
  objects (e.g. named integer vectors for set counts). May be
  [`list()`](https://rdrr.io/r/base/list.html).

- subclass:

  A single string naming the specific subclass (e.g. `"hv_survival"`).

## Value

A named list of class `c(subclass, "hv_data")`.
