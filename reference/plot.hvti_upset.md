# Plot an hvti_upset object

Draws an UpSet plot using
[`upset`](https://krassowski.github.io/complex-upset/reference/upset.html).
Apply a theme to **all panels** with `&`:

    plot(up) & hvti_theme("manuscript")

Apply scales or annotations to the intersection panel via
`base_annotations`.

## Usage

``` r
# S3 method for class 'hvti_upset'
plot(
  x,
  min_size = 1,
  width_ratio = 0.3,
  encode_sets = FALSE,
  sort_sets = "descending",
  sort_intersections = "descending",
  set_size_position = "right",
  ...
)
```

## Arguments

- x:

  An `hvti_upset` object.

- min_size:

  Minimum intersection size to display. Default `1`.

- width_ratio:

  Fraction of horizontal space given to the set-size bar. Default `0.3`.

- encode_sets:

  Logical; when `FALSE` (default) set names are used verbatim, required
  for
  [`annotate`](https://ggplot2.tidyverse.org/reference/annotate.html) to
  reference a specific set by name.

- sort_sets:

  Sort order for set-size bar: `"descending"`, `"ascending"`, or
  `FALSE`. Default `"descending"`.

- sort_intersections:

  Sort order for intersection size bars. Default `"descending"`.

- set_size_position:

  Position of the set-size bar: `"right"` (default) or `"left"`.

- ...:

  Additional arguments forwarded to
  [`upset`](https://krassowski.github.io/complex-upset/reference/upset.html),
  e.g. `base_annotations`, `annotations`, `set_sizes`.

## Value

A patchwork / ggplot composite. Use `&` to apply a theme to all panels.

## See also

[`hvti_upset`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_upset.md),
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
          "TV_Repair", "Aorta", "CABG")
dta <- sample_upset_data(n = 300, seed = 42)
up  <- hvti_upset(dta, intersect = sets)

# Build the plot object (render interactively with print(p))
p <- plot(up)
#> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` instead.
#> ℹ The deprecated feature was likely used in the ComplexUpset package.
#>   Please report the issue at
#>   <https://github.com/krassowski/complex-upset/issues>.
#> Warning: themes$intersections_matrix is not a valid theme.
#> Please use `theme()` to construct themes.
#> Warning: `legend.margin` must be specified using `margin()`
#> ℹ For the old behavior use `legend.spacing`
#> Warning: themes$intersections_matrix is not a valid theme.
#> Please use `theme()` to construct themes.
#> Warning: selected_theme is not a valid theme.
#> Please use `theme()` to construct themes.
#> Warning: `legend.margin` must be specified using `margin()`
#> ℹ For the old behavior use `legend.spacing`
#> Warning: selected_theme is not a valid theme.
#> Please use `theme()` to construct themes.
#> Warning: themes$overall_sizes is not a valid theme.
#> Please use `theme()` to construct themes.
#> Warning: `legend.margin` must be specified using `margin()`
#> ℹ For the old behavior use `legend.spacing`
#> Warning: themes$overall_sizes is not a valid theme.
#> Please use `theme()` to construct themes.

if (FALSE) { # \dontrun{
# Manuscript theme applied to all panels via &
plot(up) & hvti_theme("manuscript")

# Custom intersection bar colour
plot(up,
  base_annotations = list(
    "Intersection size" = ComplexUpset::intersection_size(
      mapping = ggplot2::aes(fill = "n")
    ) +
      ggplot2::scale_fill_manual(
        values = c("n" = "steelblue"),
        guide  = "none"
      ) +
      ggplot2::labs(y = "Patients (n)")
  )
) &
  hvti_theme("manuscript")
} # }
```
