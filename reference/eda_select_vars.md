# Select and Reorder Variables from a Data Frame

Returns the subset of `data` containing only the columns named in
`vars`, in the order given. Replaces the `Order_Variables()` helper and
the `Mod_Data <- dta[, Order_Var]` pattern from
`tp.dp.EDA_barplots_scatterplots_varnames.R`.

## Usage

``` r
eda_select_vars(data, vars)
```

## Arguments

- data:

  A data frame.

- vars:

  A character vector of column names, or a single string of
  space-separated names, e.g. `"age ht wt bmi"`.

## Value

A data frame containing only the requested columns in the requested
order.

## Details

`vars` may be supplied as a character vector or as a single
space-separated string (matching the `Var_CatList` / `Var_ContList`
style from the template).

## See also

[`hvti_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_eda.md)

## Examples

``` r
dta <- sample_eda_data()

# Vector form
sub <- eda_select_vars(dta, c("male", "cabg", "nyha"))
names(sub)
#> [1] "male" "cabg" "nyha"

# Space-separated string (matches template Var_CatList style)
sub2 <- eda_select_vars(dta, "male cabg nyha valve_morph")
names(sub2)
#> [1] "male"        "cabg"        "nyha"        "valve_morph"
```
