# Classify a Variable as Continuous or Categorical

Replicates the type-detection logic from
`Barplot_Scatterplot_Function.R`: a numeric column is treated as
categorical when all non-missing values are non-negative whole numbers
with no more than `unique_limit` distinct values.

## Usage

``` r
eda_classify_var(x, unique_limit = 6L)
```

## Arguments

- x:

  A vector (one column of a data frame).

- unique_limit:

  Integer threshold. Numeric columns with more distinct values than this
  are classified as `"Cont"`. Default `6`.

## Value

A length-1 character: `"Cont"`, `"Cat_Num"`, or `"Cat_Char"`.

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
