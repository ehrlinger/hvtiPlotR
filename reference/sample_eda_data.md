# Sample EDA Data

Generates a realistic mixed-type patient-level data frame for
demonstrating
[`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md)
and
[`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md).
The data mimics a cardiac surgery registry with binary, ordinal,
character-categorical, and continuous variables, plus a modest
proportion of missing values.

## Usage

``` r
sample_eda_data(n = 300L, year_range = c(2005L, 2020L), seed = 42L)
```

## Arguments

- n:

  Number of patients. Default `300`.

- year_range:

  Integer vector `c(start, end)` for surgery years. Default
  `c(2005L, 2020L)`.

- seed:

  Random seed for reproducibility. Default `42`.

## Value

A data frame with columns:

- `year` — integer surgery year (discrete x for barplots)

- `op_years` — continuous years from first year in range (x for
  scatterplots)

- `male` — binary 0/1 (sex)

- `cabg` — binary 0/1 (concomitant CABG)

- `nyha` — ordinal 1–4 (NYHA class)

- `valve_morph` — character (valve morphology: Bicuspid / Tricuspid /
  Unicuspid)

- `ef` — continuous ejection fraction (%)

- `lv_mass` — continuous LV mass index (g/m²)

- `peak_grad` — continuous peak gradient (mmHg)

## See also

[`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md),
[`eda_classify_var()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_classify_var.md),
[`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md)

## Examples

``` r
dta <- sample_eda_data()
head(dta)
#>   year op_years male cabg nyha valve_morph   ef lv_mass peak_grad
#> 1 2005     0.48    1    0    2   Tricuspid 66.3    97.6      31.0
#> 2 2009     4.44    1    0    2   Unicuspid 52.0   121.1      38.0
#> 3 2005     0.06    0    0    2   Tricuspid   NA   129.7      25.2
#> 4 2013     8.32    1    0    3    Bicuspid 49.8   131.4      52.5
#> 5 2014     9.87    1    0    4   Tricuspid   NA   146.3        NA
#> 6 2008     3.92    1    1    1    Bicuspid 20.0   148.0      45.1
sapply(dta, eda_classify_var)
#>        year    op_years        male        cabg        nyha valve_morph 
#>      "Cont"      "Cont"   "Cat_Num"   "Cat_Num"   "Cat_Num"  "Cat_Char" 
#>          ef     lv_mass   peak_grad 
#>      "Cont"      "Cont"      "Cont" 
```
