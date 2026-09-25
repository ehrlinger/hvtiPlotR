# Plot an hv_eda_pages object

Lays the section's panels out as pages of `ncol` by `nrow` panels.
Nothing is printed or saved; the caller prints, saves or captions each
page.

## Usage

``` r
# S3 method for class 'hv_eda_pages'
plot(x, ncol = 4L, nrow = 4L, alpha = 0.5, ...)
```

## Arguments

- x:

  An `hv_eda_pages` object.

- ncol, nrow:

  Panels across and down each page. Default 4 by 4.

- alpha:

  Point transparency for continuous panels. Default `0.5`, which keeps a
  dense cohort readable as a distribution.

- ...:

  Passed to
  [`plot.hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_eda.md),
  for example `smooth_span`.

## Value

A list of patchwork pages, possibly empty. Each page carries the names
of the variables on it as `attr(page, "variables")`, so a report can
caption it.

## Details

Colours and themes are left to the caller, as everywhere in this
package. Apply them to every panel of a page at once with patchwork's
`&`: `page & theme_hv_manuscript(base_size = 8)`.

## See also

[`hv_eda_pages()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda_pages.md),
[`plot.hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_eda.md)

## Examples

``` r
dta <- sample_eda_data(n = 300, seed = 42)
pages <- plot(hv_eda_pages(dta, section = "count"), ncol = 3, nrow = 2)
for (page in pages) message(paste(attr(page, "variables"), collapse = ", "))
#> male, cabg, nyha, valve_morph
```
