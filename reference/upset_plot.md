# UpSet Plot for Set Co-occurrence Analysis

Wraps
[`ComplexUpset::upset()`](https://krassowski.github.io/complex-upset/reference/upset.html)
to produce a structured UpSet plot for visualising overlapping set
memberships — most commonly surgical procedure co-occurrences. Returns a
bare patchwork / ggplot object so callers can compose colour scales and
themes.

## Usage

``` r
upset_plot(
  data,
  intersect,
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

- data:

  A data frame. Each set-membership column must be logical or integer
  (0/1).

- intersect:

  Character vector of column names to treat as sets. Must contain at
  least two names that exist in `data`.

- min_size:

  Minimum intersection size to display. Default `1`.

- width_ratio:

  Fraction of horizontal space given to the set-size bar. Default `0.3`.

- encode_sets:

  Logical; when `FALSE` (default) set names are used verbatim, which is
  required for
  [`ggplot2::annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html)
  to reference a specific set by name.

- sort_sets:

  Sort order for set-size bar: `"descending"`, `"ascending"`, or
  `FALSE`. Default `"descending"`.

- sort_intersections:

  Sort order for intersection size bars. Default `"descending"`.

- set_size_position:

  Position of the set-size bar: `"right"` (default) or `"left"`.

- ...:

  Additional arguments forwarded to
  [`ComplexUpset::upset()`](https://krassowski.github.io/complex-upset/reference/upset.html),
  e.g. `base_annotations`, `annotations`, `set_sizes`.

## Value

A patchwork / ggplot composite. Use `&` to apply a theme to all panels;
use `+` within `base_annotations` list entries for per-panel
customisation.

## Details

Apply a theme to **all panels** with `&`:

    upset_plot(dta, intersect = sets) & hvti_theme("manuscript")

Apply scales or annotations to the intersection panel via
`base_annotations`.

## See also

[`ComplexUpset::upset()`](https://krassowski.github.io/complex-upset/reference/upset.html),
[`sample_upset_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_upset_data.md),
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
          "TV_Repair", "Aorta", "CABG")
dta <- sample_upset_data(n = 300, seed = 42)

# --- Build the plot object (render interactively with print(p)) ----------
p <- upset_plot(dta, intersect = sets)
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
# --- Manuscript theme applied to all panels via & ------------------------
upset_plot(dta, intersect = sets) &
  hvti_theme("manuscript")

# --- Custom intersection bar colour via scale_fill_manual ----------------
upset_plot(
  dta,
  intersect = sets,
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

# --- Colour bars by a stratum (e.g. era) ---------------------------------
if (FALSE) { # \dontrun{
dta$era <- ifelse(seq_len(nrow(dta)) <= 150, "Early", "Recent")

upset_plot(
  dta,
  intersect = sets,
  base_annotations = list(
    "Intersection size" = ComplexUpset::intersection_size(
      counts   = FALSE,
      mapping  = ggplot2::aes(fill = era)
    ) +
      ggplot2::scale_fill_manual(
        values = c("Early" = "grey60", "Recent" = "steelblue"),
        name   = "Era"
      ) +
      ggplot2::labs(y = "Patients (n)")
  )
) &
  hvti_theme("manuscript")
} # }

# --- Annotate a specific set bar and add count labels --------------------
if (FALSE) { # \dontrun{
upset_plot(
  dta,
  intersect = sets,
  set_sizes = (
    ComplexUpset::upset_set_size(position = "right") +
      ggplot2::geom_text(
        ggplot2::aes(label = ggplot2::after_stat(count)),
        hjust  = 1.1,
        stat   = "count",
        colour = "white"
      ) +
      ggplot2::annotate(
        geom  = "text",
        label = "\u2713",
        x     = "CABG",
        y     = 175,
        size  = 3
      ) +
      ggplot2::expand_limits(y = 300)
  )
) &
  hvti_theme("manuscript")
} # }

# --- Save ----------------------------------------------------------------
if (FALSE) { # \dontrun{
p <- upset_plot(dta, intersect = sets) & hvti_theme("manuscript")
ggplot2::ggsave("upset.pdf", p, width = 12, height = 8)
} # }
```
