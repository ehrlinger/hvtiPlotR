# save_manuscript() Draft PNG Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let `save_manuscript()` optionally write a second, raster "draft" copy of a figure alongside the primary publisher file, in one call, so downstream manuscripts can drag a small PNG into Word without touching the vector deliverable.

**Architecture:** Add two new optional parameters, `draft_file` and `draft_dpi`, to the existing `save_manuscript()` wrapper in `R/save-manuscript.R`. When `draft_file` is supplied, a second `ggplot2::ggsave()` call writes to that path at `draft_dpi` (falls back to `dpi` when unset). No behavior changes for any existing call site that doesn't pass `draft_file` — it stays `NULL` by default.

**Tech Stack:** R, ggplot2 (`ggsave`), testthat edition 3, roxygen2 (markdown).

## Global Constraints

- Never push directly to `main`. Branch, commit, `gh pr create`, let the user merge.
- Version bump is **patch only** (`2.7.2 -> 2.7.3`) — this is an additive, backward-compatible enhancement, not a minor/major change. Update both `DESCRIPTION` (Version + Date) and `NEWS.md`.
- `Config/testthat/edition: 3` — write tests in the testthat 3e style already used in this file (`test_that()`, `expect_*()`, no legacy `context()`).
- Match existing code style in `R/save-manuscript.R`: `.check_scalar_positive()` validator, `stop(..., call. = FALSE)`, roxygen with `@param`/`@return`/`@export`.
- Do not touch the pre-existing untracked files in this working tree (`.codegraph/`, `inst/extdata/Yahoo slide template LIGHT ROOM.pptx`) or the 1 commit already ahead of `origin/main` — they predate this task and are not in scope.

---

### Task 1: Add `draft_file`/`draft_dpi` to `save_manuscript()`

**Files:**
- Modify: `R/save-manuscript.R`
- Modify: `tests/testthat/test_save_manuscript.R`
- Modify: `man/save_manuscript.Rd` (regenerated, not hand-edited)
- Modify: `DESCRIPTION` (Version, Date)
- Modify: `NEWS.md`

**Interfaces:**
- Produces: `save_manuscript(plot, file, width = 6, height = 4, units = "in", device = NULL, dpi = 300, draft_file = NULL, draft_dpi = NULL, ...)` — same return value as today (`invisible(file)`), draft output is a side effect only.

- [ ] **Step 1: Create a feature branch**

```bash
cd ~/Documents/GitHub/hvtiPlotR
git checkout -b feat/save-manuscript-draft-png
```

- [ ] **Step 2: Write the failing tests**

Append to `tests/testthat/test_save_manuscript.R`:

```r
test_that("save_manuscript writes an optional draft_file alongside file", {
  p <- mk_plot()
  f <- tempfile(fileext = ".pdf")
  d <- tempfile(fileext = ".png")
  on.exit(unlink(c(f, d)), add = TRUE)
  save_manuscript(p, f, draft_file = d)
  expect_true(file.exists(f))
  expect_true(file.exists(d))
})

test_that("save_manuscript draft_file honours draft_dpi and falls back to dpi", {
  p <- mk_plot()
  f <- tempfile(fileext = ".pdf")
  d <- tempfile(fileext = ".png")
  on.exit(unlink(c(f, d)), add = TRUE)
  expect_silent(save_manuscript(p, f, dpi = 150, draft_file = d, draft_dpi = 72))
  expect_true(file.exists(d))
})

test_that("save_manuscript validates draft_file inputs", {
  p <- mk_plot()
  f <- tempfile(fileext = ".pdf")
  on.exit(unlink(f), add = TRUE)
  expect_error(save_manuscript(p, f, draft_file = c("a.png", "b.png")), "draft_file")
  expect_error(save_manuscript(p, f, draft_file = NA_character_), "draft_file")
  expect_error(save_manuscript(p, f, draft_file = ""), "draft_file")
  expect_error(
    save_manuscript(p, f, draft_file = file.path(tempdir(), "no_such_dir_xyz", "d.png")),
    "Draft output directory does not exist"
  )
})
```

- [ ] **Step 3: Run tests to verify the new ones fail**

Run: `Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test_save_manuscript.R")'`
Expected: the 3 new tests FAIL (`unused argument (draft_file = d)` or similar), the 3 pre-existing tests still PASS.

- [ ] **Step 4: Implement `draft_file`/`draft_dpi`**

Replace the full contents of `R/save-manuscript.R` with:

```r
#' Save a ggplot at HVTI manuscript defaults
#'
#' A thin wrapper around [ggplot2::ggsave()] that enforces the house manuscript
#' figure size — **6 inches wide by 4 inches tall** — so journal figures come
#' out at a consistent size in one call. It is the manuscript counterpart of
#' [save_ppt()], which enforces the slide panel box.
#'
#' Pair it with [theme_hv_manuscript()], whose 12 pt `base_size` supplies the
#' manuscript typography. Like [save_ppt()], `save_manuscript()` fixes the
#' output geometry, not the theme — style the plot first, then save.
#'
#' The device is inferred from the file extension by default. For a `.pdf`
#' where you want fonts embedded (so 12 pt type renders exactly as designed),
#' pass `device = grDevices::cairo_pdf` — on a system with cairo/X11 support.
#'
#' Publisher-accepted vector formats (PDF, EPS, TIFF) often produce large or
#' fragile files when dragged into a Word manuscript — Word has no native
#' PDF-as-picture support and silently converts them to bloated, sometimes
#' unreadable EMF. Pass `draft_file` (typically a `.png` path) to also write a
#' small raster copy alongside `file` in the same call: keep `file` as the
#' vector deliverable actually submitted to the journal, and drag
#' `draft_file` into the Word draft instead.
#'
#' @param plot A [ggplot2::ggplot()] object, e.g. `plot(hv_*())` finished with
#'   `theme_hv_manuscript()`.
#' @param file Output file path. Its extension sets the format (`.pdf`, `.png`,
#'   ...).
#' @param width,height,units Figure size. Default `6` x `4` `"in"` — the HVTI
#'   manuscript default.
#' @param device Graphics device. `NULL` (default) lets \pkg{ggplot2} pick from
#'   the file extension. For font embedding in a PDF, pass
#'   `grDevices::cairo_pdf` (requires cairo/X11 support).
#' @param dpi Resolution for raster formats. Default `300`.
#' @param draft_file Optional second output file path (typically `.png`). When
#'   supplied, an additional raster copy of `plot` is written here at the same
#'   `width`/`height`/`units`, for dragging into a Word draft manuscript.
#'   Default `NULL` (no draft copy written).
#' @param draft_dpi Resolution for `draft_file`. Default `NULL`, which falls
#'   back to `dpi`.
#' @param ... Further arguments passed to [ggplot2::ggsave()] for the primary
#'   `file`. Not applied to `draft_file`.
#'
#' @return Invisibly, the `file` path.
#'
#' @seealso [save_ppt()] for slides, [theme_hv_manuscript()] for the 12 pt
#'   typography, [hv_ggsave_dims()] for fixed-panel sizing. Worked examples live
#'   in the HVTI ggplot graphics recipes book,
#'   <https://ehrlinger.github.io/hvti_graphics/>.
#'
#' @examples
#' \donttest{
#' p <- plot(hv_survival(sample_survival_data(n = 200, seed = 42))) +
#'   theme_hv_manuscript()
#' save_manuscript(p, file.path(tempdir(), "survival.pdf"))
#'
#' # also write a small draft PNG for dragging into Word
#' save_manuscript(p, file.path(tempdir(), "survival.pdf"),
#'                  draft_file = file.path(tempdir(), "survival_draft.png"))
#' }
#'
#' @importFrom ggplot2 ggsave
#' @export
save_manuscript <- function(plot, file, width = 6, height = 4, units = "in",
                            device = NULL, dpi = 300,
                            draft_file = NULL, draft_dpi = NULL, ...) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file))
    stop("`file` must be a single non-empty file path.", call. = FALSE)
  .check_scalar_positive(width,  "width")
  .check_scalar_positive(height, "height")
  .check_scalar_positive(dpi,    "dpi")
  units <- match.arg(units, c("in", "cm", "mm", "px"))
  out_dir <- dirname(file)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)

  ggplot2::ggsave(filename = file, plot = plot, device = device,
                  width = width, height = height, units = units, dpi = dpi, ...)

  if (!is.null(draft_file)) {
    if (!is.character(draft_file) || length(draft_file) != 1L ||
        is.na(draft_file) || !nzchar(draft_file))
      stop("`draft_file` must be a single non-empty file path.", call. = FALSE)
    draft_out_dir <- dirname(draft_file)
    if (!dir.exists(draft_out_dir))
      stop("Draft output directory does not exist: ", draft_out_dir, call. = FALSE)
    draft_dpi <- if (is.null(draft_dpi)) dpi else draft_dpi
    .check_scalar_positive(draft_dpi, "draft_dpi")
    ggplot2::ggsave(filename = draft_file, plot = plot, device = NULL,
                    width = width, height = height, units = units, dpi = draft_dpi)
  }

  invisible(file)
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test_save_manuscript.R")'`
Expected: all 6 tests (3 pre-existing + 3 new) PASS.

- [ ] **Step 6: Regenerate documentation**

Run: `Rscript -e 'devtools::document()'`
Expected: `man/save_manuscript.Rd` is rewritten to include `draft_file`/`draft_dpi`; no roxygen warnings/errors.

- [ ] **Step 7: Bump version and changelog**

In `DESCRIPTION`, change:
```
Version: 2.7.2
Date: 2026-06-24
```
to:
```
Version: 2.7.3
Date: 2026-07-14
```

Prepend to `NEWS.md`:
```markdown
# hvtiPlotR 2.7.3

## New features

- `save_manuscript()` gains `draft_file`/`draft_dpi` arguments: write an
  additional raster (typically PNG) copy alongside the primary publisher
  file in one call. Use this to keep a small, portable draft figure for
  dragging into a Word manuscript while `file` stays the vector deliverable
  (PDF/EPS/TIFF) actually submitted to the journal.

```

- [ ] **Step 8: Run the full test suite**

Run: `Rscript -e 'devtools::test()'`
Expected: 0 failures, 0 errors (warnings from unrelated pre-existing files are out of scope — do not fix them here).

- [ ] **Step 9: Commit**

```bash
git add R/save-manuscript.R tests/testthat/test_save_manuscript.R man/save_manuscript.Rd DESCRIPTION NEWS.md
git commit -m "feat: save_manuscript() gains draft_file/draft_dpi for PNG draft export"
```

- [ ] **Step 10: Push and open a PR (confirm with the user first — this pushes to a shared remote)**

```bash
git push -u origin feat/save-manuscript-draft-png
gh pr create --title "save_manuscript(): optional draft PNG export" --body "$(cat <<'EOF'
## Summary
- Adds optional `draft_file`/`draft_dpi` args to `save_manuscript()` so callers can write a small raster draft copy alongside the vector publisher file in one call, without touching any of the ~30 existing call sites that don't pass them.
- Bumps 2.7.2 -> 2.7.3 (patch, additive/backward-compatible).

## Test plan
- [x] `devtools::test()` passes
- [x] `devtools::document()` regenerates man/save_manuscript.Rd cleanly
EOF
)"
```

---

## Self-Review

- **Spec coverage:** The AVSD morphology handoff's Workstream 1 goal — "a draft-quality raster to drag in, while keeping PDF/EPS as the publisher deliverable" — is satisfied by `draft_file`/`draft_dpi`. Every one of the ~30 `save_manuscript()` call sites in `09-publication-figures.qmd` can add `draft_file = file.path(draft_dir, "<name>.png")` without any other change (follow-up work in the AVSD repo, not in this plan).
- **Placeholder scan:** No TBD/placeholder steps; every step has literal code or an exact command with expected output.
- **Type consistency:** `draft_file`/`draft_dpi` names and defaults are identical between the roxygen doc, the function signature, and the tests.
