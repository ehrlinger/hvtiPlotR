# Classify a Variable as Continuous or Categorical

Replicates the type-detection logic from
`Barplot_Scatterplot_Function.R`: a numeric column is treated as
categorical when all non-missing values are non-negative whole numbers
with no more than `unique_limit` distinct values.

## Usage

``` r
eda_classify_var(
  x,
  unique_limit = 6L,
  unique_bound = 100,
  var_name = NULL,
  type_overrides = NULL
)
```

## Arguments

- x:

  A vector (one column of a data frame).

- unique_limit:

  Integer threshold. Numeric columns with more distinct values than this
  are classified as `"Cont"`. Default `6`.

- unique_bound:

  Integer threshold. Numeric columns that contain any values greater
  than this are classified as `"Cont"`, regardless of number of distinct
  values. Default `100`

- var_name:

  A string containing the name of the variable/column. Default `NULL`

- type_overrides:

  A named vector of variables and variable types ("Cont", "Cat_Num", or
  "Cat_Char") to manually set their classifications, e.g., c(severity =
  "Cat_Num"). Default `NULL`

## Value

A length-1 character: `"Cont"`, `"Cat_Num"`, or `"Cat_Char"`.

## See also

[`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md),
[`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md)

## Examples

``` r
eda_classify_var(c(0, 1, 1, 0, NA))        # "Cat_Num"
#> [1] "Cat_Num"
eda_classify_var(c(1, 2, 3, 4))            # "Cat_Num"
#> [1] "Cat_Num"
eda_classify_var(rnorm(50))                # "Cont"
#> [1] "Cont"
eda_classify_var(c("A", "B", "A"))         # "Cat_Char"
#> [1] "Cat_Char"
```
