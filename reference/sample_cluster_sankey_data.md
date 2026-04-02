# Sample Cluster Stability Sankey Data

Generates a synthetic dataset with one row per patient and columns
`C2`–`C9` holding letter-labelled cluster assignments at successive
values of K (number of clusters). The hierarchical merge structure
follows the pattern from the HVTI PAM clustering analysis:

## Usage

``` r
sample_cluster_sankey_data(
  n = 300L,
  probs = c(B = 0.18, F = 0.12, H = 0.06, D = 0.12, I = 0.04, C = 0.14, E = 0.11, G =
    0.08, A = 0.15),
  seed = 42L
)
```

## Arguments

- n:

  Number of patients. Default `300`.

- probs:

  Named numeric vector of C9-level cluster probabilities (must sum to
  1), in the order `c(B, F, H, D, I, C, E, G, A)`. Default uses
  approximate equal-area proportions.

- seed:

  Random seed. Default `42L`.

## Value

A data frame with `n` rows and columns `C2`–`C9`, each a factor ordered
by the hierarchical cluster labels.

## Details

|          |     |     |     |     |     |     |     |     |
|----------|-----|-----|-----|-----|-----|-----|-----|-----|
| C9 label | C2  | C3  | C4  | C5  | C6  | C7  | C8  | C9  |
| A        | A   | A   | A   | A   | A   | A   | A   | A   |
| B        | B   | B   | B   | B   | B   | B   | B   | B   |
| C        | A   | C   | C   | C   | C   | C   | C   | C   |
| D        | B   | B   | D   | D   | D   | D   | D   | D   |
| E        | A   | C   | C   | E   | E   | E   | E   | E   |
| F        | B   | B   | B   | B   | F   | F   | F   | F   |
| G        | A   | A   | A   | A   | A   | G   | G   | G   |
| H        | B   | B   | B   | B   | F   | F   | H   | H   |
| I        | B   | B   | D   | D   | D   | D   | D   | I   |

## See also

[`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md)

## Examples

``` r
dta <- sample_cluster_sankey_data(n = 200, seed = 42)
head(dta)
#>   C2 C3 C4 C5 C6 C7 C8 C9
#> 1  B  B  B  B  F  F  H  H
#> 2  B  B  B  B  F  F  H  H
#> 3  A  A  A  A  A  A  A  A
#> 4  A  A  A  A  A  G  G  G
#> 5  B  B  D  D  D  D  D  D
#> 6  B  B  B  B  F  F  F  F
table(dta$C9)
#> 
#>  B  F  H  D  I  C  E  G  A 
#> 35 21 19 23  7 26 32 12 25 
```
