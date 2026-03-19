# Fit a Kaplan-Meier (survfit) model

Wraps
[`survival::survfit`](https://rdrr.io/pkg/survival/man/survfit.html)
using renamed local variables to avoid column-name clashes with the
formula interface.

## Usage

``` r
km_fit(data, time_col, event_col, group_col, conf_level, method)
```

## Arguments

- data:

  A data frame.

- time_col:

  Name of the time column.

- event_col:

  Name of the event indicator column.

- group_col:

  Name of an optional stratification column, or `NULL`.

- conf_level:

  Confidence level for the CI band (default 0.95).

- method:

  Method for survival curve estimation: `"kaplan-meier"` uses
  product-limit S(t) with logit CI (matches SAS `%kaplan`), or
  `"nelson-aalen"` uses Fleming-Harrington H(t) with log CI (matches SAS
  `%nelsont`).

## Value

A `survfit` object.
