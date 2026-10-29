# Build the provenance footnote for a saved figure

Formats the fields
[`save_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_manuscript.md)
prints below a figure to identify the version of the job that drew it:
the commit, the job path, the R, hvtiPlotR and hvtiRtemplates versions
and the time, which
[`save_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_manuscript.md)
joins with a middle dot.

## Usage

``` r
provenance_footnote(
  commit,
  job,
  versions = .default_versions(),
  time = Sys.time()
)
```

## Arguments

- commit:

  The render commit ID, a single string printed as given: a unique
  abbreviation, the full ID, or a marker such as `"uncommitted"`.

- job:

  The job path, a single string, such as `"30_analyses/survival.qmd"`.

- versions:

  A named character vector of versions, printed as `"<name> <version>"`
  in the order given. The default is R, the installed hvtiPlotR and,
  when it is installed, hvtiRtemplates.

- time:

  The time of the render, a `POSIXct` printed as `"%Y-%m-%d %H:%M"`.
  Default [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

## Value

A character vector of fields: the commit, the job, one field per version
and the time. Pass it to the `footnote` argument of
[`save_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_manuscript.md),
which joins and fits it.

## Details

The commit comes first, so the shortest line that survives a crop still
finds the render record, which names the job. It is printed as given and
never shortened here: hvtiPlotR cannot know which abbreviation is unique
in the study's repository, so pass one that git verified, such as the
output of `git rev-parse --short`, or the full ID. A marker the caller
uses when no commit could be made, such as `"uncommitted"`, prints whole
too.

Only the R, hvtiPlotR and hvtiRtemplates versions are printed; the full
package list belongs in the render provenance.

hvtiPlotR does not know about studies or git. It formats the parts it is
given; the commit and the job path come from the caller.

## See also

[`save_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_manuscript.md),
which prints the note in a strip below the figure.

## Examples

``` r
provenance_footnote(
  commit   = "3f9c2a1",
  job      = "30_analyses/rfs.explain.long_term_survival.primary.qmd",
  versions = c(R = "4.5.1", hvtiPlotR = "2.8.19", hvtiRtemplates = "1.5.3"),
  time     = as.POSIXct("2026-10-29 14:40")
)
#> [1] "3f9c2a1"                                               
#> [2] "30_analyses/rfs.explain.long_term_survival.primary.qmd"
#> [3] "R 4.5.1"                                               
#> [4] "hvtiPlotR 2.8.19"                                      
#> [5] "hvtiRtemplates 1.5.3"                                  
#> [6] "2026-10-29 14:40"                                      
```
