# Contributing to hvtiPlotR

Thank you for contributing! This guide covers two tracks:

- **Track A — Porting a SAS template** (for biostatisticians and analysts):
  adding a new plot function or sample-data generator.
- **Track B — Package infrastructure** (for R package developers):
  dependency changes, CI, testing, and CRAN compliance.

For detailed walkthroughs see the
[Contributing vignette](vignettes/contributing.qmd) (rendered at
`vignettes/contributing.html` or on the pkgdown site).

---

## Quick start

```r
# 1. Install development dependencies
install.packages("devtools")
devtools::install_deps(dependencies = TRUE)

# 2. Load the package without installing
devtools::load_all()

# 3. Run all checks (must pass before a PR is merged)
devtools::check()

# 4. Run tests only
devtools::test()

# 5. Regenerate documentation
devtools::document()
```

---

## Track A — Porting a SAS template

If you have a SAS template (e.g. `tp.np.afib.ivwristm.avrg_curv.binary.sas`)
and want to add an R equivalent:

1. **Create `R/my-plot.R`** — one file per plot family.
2. **Write the bare-ggplot function** — accept model-output data frames and
   column-name strings; return an unstyled `ggplot` object.
3. **Add a `sample_my_data()` companion** — realistic synthetic data that
   mirrors the SAS `predict` / `means` datasets.
4. **Write roxygen docs** — include `@param`, `@return`, `@seealso`,
   `@examples`, `@references` (SAS template name), and `@export`.
5. **Run `devtools::document()`** to regenerate `NAMESPACE` and `.Rd` files.
6. **Add a worked example** to `vignettes/plot-functions.qmd`.
7. **Add a row** to the lookup table in `vignettes/sas-migration-guide.qmd`.
8. **Add the function** to the right section in `_pkgdown.yml`.
9. **Write at least two tests** in `tests/testthat/test_my_plot.R`:
   one checking the return class, one checking the sample-data shape.
10. **Update `NEWS.md`** under the current dev version.
11. Open a pull request against `main`.

See the [Contributing vignette](vignettes/contributing.qmd) for a fully
worked example.

---

## Track B — Package infrastructure

For changes to `DESCRIPTION`, CI workflows, testing infrastructure, or
package-level architecture:

- **New dependencies** must be justified and added to the right field
  (`Imports` for runtime, `Suggests` for vignettes/tests only).
- **CI** runs `R CMD CHECK` on push via GitHub Actions
  (`.github/workflows/`). All checks must pass.
- **Vignettes** are built with Quarto (`VignetteBuilder: quarto`). Chunks
  that require a file system path or network access must have `#| eval: false`.
- **Breaking changes** to existing function signatures require a `NEWS.md`
  entry and a deprecation notice in the function.

---

## Code conventions

| Convention | Rule |
|---|---|
| File names | `kebab-case.R` (e.g. `nonparametric-curve-plot.R`) |
| Function names | `hv_<concept>()` constructor + `plot.hv_<concept>()` method (e.g. `hv_nonparametric()`, `plot.hv_nonparametric()`) |
| Column-name args | Always strings, never bare symbols (e.g. `x_col = "time"`) |
| Colours | Never hard-coded — leave to `scale_colour_*()` / `scale_fill_*()` |
| Themes | Never applied inside the function — leave to the caller |
| Tidy eval | Use `.data[[col]]` from `rlang`; import with `@importFrom rlang .data` |
| Tests | `expect_s3_class(obj, "hv_data")` for constructor; `expect_s3_class(plot(obj), "ggplot")` for the plot method |
| Snapshots | After adding a new `expect_snapshot()` test, run `devtools::test()` once locally to generate the `.snap` baseline, then commit the file under `tests/testthat/_snaps/`. If CI is the first to run it, the snapshot will be uploaded automatically via `upload-snapshots: true` in the workflow. To accept updated snapshots after intentional output changes, run `testthat::snapshot_accept()` locally and commit the result. |

---

## Getting help

- Open an [issue](https://github.com/ehrlinger/hvtiPlotR/issues) to discuss
  a new port before writing code.
- Tag `@ehrlinger` for review on all pull requests.
