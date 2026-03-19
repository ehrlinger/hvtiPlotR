# Sample Procedure Co-occurrence Data

Generates a realistic cardiac-surgery procedure data set where each row
is a patient and each column is a logical indicator of a specific
procedure. Co-occurrence rates are modelled from a latent
primary-procedure type so that the UpSet plot shows meaningful overlap
patterns (e.g. aortic valve patients frequently have concomitant aorta
work; mitral valve patients frequently have concomitant TV repair).

## Usage

``` r
sample_upset_data(n = 500, seed = 42L)
```

## Arguments

- n:

  Number of patients. Default `500`.

- seed:

  Random seed for reproducibility. Default `42`.

## Value

A data frame with `n` rows and the following logical columns:
`AV_Replacement`, `AV_Repair`, `MV_Replacement`, `MV_Repair`,
`TV_Repair`, `Aorta`, `CABG`.

## See also

[`upset_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/upset_plot.md)

## Examples

``` r
dta <- sample_upset_data(n = 300, seed = 42)
head(dta)
#>   AV_Replacement AV_Repair MV_Replacement MV_Repair TV_Repair Aorta  CABG
#> 1          FALSE     FALSE          FALSE      TRUE     FALSE FALSE FALSE
#> 2          FALSE     FALSE          FALSE      TRUE     FALSE FALSE FALSE
#> 3          FALSE     FALSE          FALSE     FALSE     FALSE FALSE  TRUE
#> 4          FALSE      TRUE          FALSE     FALSE     FALSE FALSE FALSE
#> 5          FALSE     FALSE           TRUE     FALSE      TRUE FALSE FALSE
#> 6           TRUE     FALSE          FALSE     FALSE     FALSE FALSE  TRUE
colSums(dta)
#> AV_Replacement      AV_Repair MV_Replacement      MV_Repair      TV_Repair 
#>             93             40             45             33             36 
#>          Aorta           CABG 
#>             37            114 
```
